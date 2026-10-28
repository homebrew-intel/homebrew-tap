import { describe, expect, test } from "bun:test";
import type { Bottle } from "./bottle";
import { migrateBrewfile, splitComment, tapIndex } from "./brewfile";

function bottle(name: string, aliases: string[] = []): Bottle {
  return { name, version: "1", url: "", deps: [], aliases };
}

const index = tapIndex([bottle("cmake"), bottle("pkgconf", ["pkg-config"]), bottle("python@3.15", ["python"])]);

function migrate(lines: string[]): string[] {
  return migrateBrewfile(lines.join("\n"), index).text.split("\n");
}

describe("splitComment", () => {
  test("ignores # inside strings", () => {
    expect(splitComment('brew "a#b" # note')).toEqual({ code: 'brew "a#b"', comment: " # note" });
    expect(splitComment("brew 'x'")).toEqual({ code: "brew 'x'", comment: "" });
  });
});

describe("migrateBrewfile", () => {
  test("qualifies tap formulae, keeping options and comments", () => {
    expect(migrate(['tap "a/b"', 'brew "cmake", args: ["HEAD"] # build tool', "brew 'jq'"])).toEqual([
      'tap "a/b"',
      'tap "macos-intel/tap", trusted: true',
      'brew "macos-intel/tap/cmake", args: ["HEAD"] # build tool',
      "brew 'jq'",
    ]);
  });

  test("maps a mirrored core alias to its formula", () => {
    expect(migrate(['brew "pkg-config"', 'brew "python" if OS.mac?'])).toEqual([
      'tap "macos-intel/tap", trusted: true',
      'brew "macos-intel/tap/pkgconf"',
      'brew "macos-intel/tap/python@3.15" if OS.mac?',
    ]);
  });

  test("leaves qualified entries, casks and comments untouched", () => {
    const source = [
      "# brew \"cmake\"",
      'brew "homebrew/core/cmake"',
      'brew "macos-intel/tap/pkgconf"',
      'cask "cmake"',
    ];
    const result = migrateBrewfile(source.join("\n"), index);
    expect(result.migrated).toEqual([]);
    // The already-qualified pkgconf still needs the tap entry.
    expect(result.text.split("\n")).toEqual([
      "# brew \"cmake\"",
      'tap "macos-intel/tap", trusted: true',
      ...source.slice(1),
    ]);
  });

  test("adds no tap entry when nothing uses the tap", () => {
    const source = 'tap "a/b"\nbrew "jq"\n';
    const result = migrateBrewfile(source, index);
    expect(result.text).toBe(source);
    expect(result.changes).toEqual([]);
  });

  test("trusts an existing tap entry after its other arguments", () => {
    expect(migrate(['tap "macos-intel/tap", "https://example.com/t.git" # mine', 'brew "cmake"'])).toEqual([
      'tap "macos-intel/tap", "https://example.com/t.git", trusted: true # mine',
      'brew "macos-intel/tap/cmake"',
    ]);
  });

  test("keeps an existing trusted setting", () => {
    const source = 'tap "macos-intel/homebrew-tap", trusted: { formula: "cmake" }\nbrew "cmake"';
    expect(migrate(source.split("\n"))[0]).toBe('tap "macos-intel/homebrew-tap", trusted: { formula: "cmake" }');
  });

  test("warns about a multi-line tap entry instead of breaking it", () => {
    const result = migrateBrewfile('tap "macos-intel/tap",\n  "https://example.com/t.git"\nbrew "cmake"', index);
    expect(result.warnings).toHaveLength(1);
    expect(result.text.split("\n")[0]).toBe('tap "macos-intel/tap",');
  });

  test("reports changes with output line numbers and the migrated formulae", () => {
    const result = migrateBrewfile('tap "a/b"\nbrew "cmake"\nbrew "pkg-config"\nbrew "cmake"\n', index);
    expect(result.migrated).toEqual(["cmake", "pkgconf"]);
    expect(result.changes).toEqual([
      { line: 2, before: undefined, after: 'tap "macos-intel/tap", trusted: true' },
      { line: 3, before: 'brew "cmake"', after: 'brew "macos-intel/tap/cmake"' },
      { line: 4, before: 'brew "pkg-config"', after: 'brew "macos-intel/tap/pkgconf"' },
      { line: 5, before: 'brew "cmake"', after: 'brew "macos-intel/tap/cmake"' },
    ]);
    expect(result.text.endsWith("\n")).toBe(true);
  });

  test("preserves CRLF line endings and indentation", () => {
    const result = migrateBrewfile('if OS.mac?\r\n  brew "cmake"\r\nend\r\n', index);
    expect(result.text).toBe('tap "macos-intel/tap", trusted: true\r\nif OS.mac?\r\n  brew "macos-intel/tap/cmake"\r\nend\r\n');
  });
});
