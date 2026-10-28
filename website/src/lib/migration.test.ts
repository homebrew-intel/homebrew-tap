import { describe, expect, test } from "bun:test";
import { installOrder, migrationCommands } from "./migration";

const deps = new Map<string, string[]>([
  ["wget", ["openssl@4", "libidn2", "gettext"]],
  ["libidn2", ["gettext", "libunistring"]],
  ["gettext", ["libunistring"]],
  ["git", ["gettext", "pcre2"]],
]);

describe("installOrder", () => {
  test("puts every dependency before its dependents", () => {
    const order = installOrder(["wget"], deps);
    expect([...order].sort()).toEqual(["gettext", "libidn2", "libunistring", "openssl@4", "wget"]);
    for (const [name, needs] of deps) {
      if (!order.includes(name)) continue;
      for (const dep of needs) expect(order.indexOf(dep)).toBeLessThan(order.indexOf(name));
    }
  });

  test("lists a shared dependency once and is stable", () => {
    expect(installOrder(["wget", "git"], deps)).toEqual([
      "libunistring",
      "gettext",
      "pcre2",
      "git",
      "libidn2",
      "openssl@4",
      "wget",
    ]);
  });

  test("keeps a name with no known dependencies", () => {
    expect(installOrder(["cmake"], deps)).toEqual(["cmake"]);
  });

  test("terminates on a cycle", () => {
    const cyclic = new Map([["a", ["b"]], ["b", ["a"]]]);
    expect(installOrder(["a"], cyclic)).toEqual(["b", "a"]);
  });
});

describe("migrationCommands", () => {
  test("taps, trusts, then reinstalls dependencies first", () => {
    expect(migrationCommands(["git"], deps)).toBe(
      [
        "brew tap macos-intel/tap",
        "brew trust macos-intel/tap",
        "brew reinstall macos-intel/tap/libunistring",
        "brew reinstall macos-intel/tap/gettext",
        "brew reinstall macos-intel/tap/pcre2",
        "brew reinstall macos-intel/tap/git",
      ].join("\n"),
    );
  });
});
