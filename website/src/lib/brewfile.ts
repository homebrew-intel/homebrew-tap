import { TAP, type Bottle } from "./bottle";

// Maps every name a Brewfile may use for a tap formula, its bare name or a
// core alias the tap mirrors (pkg-config for pkgconf), to the formula name.
export type TapIndex = ReadonlyMap<string, string>;

export function tapIndex(bottles: readonly Bottle[]): TapIndex {
  const index = new Map<string, string>();
  for (const bottle of bottles) {
    for (const alias of bottle.aliases) index.set(alias, bottle.name);
  }
  // Formula names win over an alias that happens to share one.
  for (const bottle of bottles) index.set(bottle.name, bottle.name);
  return index;
}

// One changed line of the rewritten Brewfile, numbered in the output.
// `before` is absent for an inserted line.
export type LineChange = { line: number; before?: string; after: string };

export type BrewfileMigration = {
  text: string;
  changes: LineChange[];
  // Tap formulae the rewrite switched, by formula name, in file order.
  migrated: string[];
  warnings: string[];
};

const TAP_LINE = `tap "${TAP}", trusted: true`;
const TAP_ENTRY = /^\s*tap\s+(["'])([^"']+)\1/;
const BREW_ENTRY = /^(\s*brew\s+)(["'])([^"']+)\2(.*)$/;
// brew normalises the repository name, so both spellings are this tap.
const OUR_TAP = /^macos-intel\/(homebrew-)?tap$/i;

type Split = { code: string; comment: string };

// Splits a line at its first "#" outside a string, keeping the whitespace
// before the comment with it, so a rewrite never touches the comment.
export function splitComment(line: string): Split {
  let quote = "";
  for (let at = 0; at < line.length; at += 1) {
    const char = line[at];
    if (quote) {
      if (char === "\\") at += 1;
      else if (char === quote) quote = "";
    } else if (char === '"' || char === "'") {
      quote = char;
    } else if (char === "#") {
      const code = line.slice(0, at).trimEnd();
      return { code, comment: line.slice(code.length) };
    }
  }
  return { code: line, comment: "" };
}

// A trailing "," or "\" continues the entry on the next line.
function continues(code: string): boolean {
  return /[,\\]\s*$/.test(code);
}

function isOurTap(code: string): boolean {
  const match = TAP_ENTRY.exec(code);
  return match !== null && OUR_TAP.test(match[2]);
}

type Line = { text: string; before?: string; inserted?: boolean };

// `tapFormula` names the tap formula a brew entry installs after the
// rewrite, whether it was switched or already qualified.
type BrewRewrite = { text: string; tapFormula?: string };

// Rewrites `brew "<name>"` to the tap when <name> is a tap formula or alias.
// Qualified names (anything with a "/") are left alone: they already say
// which tap the user wants, core included.
function rewriteBrew(line: string, index: TapIndex): BrewRewrite {
  const { code, comment } = splitComment(line);
  const match = BREW_ENTRY.exec(code);
  if (!match) return { text: line };
  const [, prefix, quote, name, rest] = match;
  if (name.includes("/")) {
    const qualified = name.toLowerCase().startsWith(`${TAP}/`);
    return { text: line, tapFormula: qualified ? name.slice(TAP.length + 1) : undefined };
  }
  const formula = index.get(name.toLowerCase());
  if (!formula) return { text: line };
  return { text: `${prefix}${quote}${TAP}/${formula}${quote}${rest}${comment}`, tapFormula: formula };
}

function changed(before: string, after: string): Line {
  return after === before ? { text: before } : { text: after, before };
}

// Adds `trusted: true` to our tap entry unless it already sets `trusted:`.
// Appended after every other argument: a positional clone URL must stay
// before keyword arguments.
function trustTap(line: string, warnings: string[]): string {
  const { code, comment } = splitComment(line);
  if (/\btrusted:/.test(code)) return line;
  if (continues(code)) {
    warnings.push(`Add "trusted: true" to the multi-line ${TAP} entry by hand.`);
    return line;
  }
  return `${code}, trusted: true${comment}`;
}

// Where the tap entry goes: after the last top-level tap entry (and its
// continuation lines), else before the first top-level entry, else the end.
// Indented lines sit inside a block (`if OS.mac?`) and would make it
// conditional.
function insertionPoint(lines: readonly Line[]): number {
  let lastTap = -1;
  lines.forEach((line, at) => {
    if (/^tap\s/.test(line.text)) lastTap = at;
  });
  if (lastTap >= 0) {
    let at = lastTap;
    while (at + 1 < lines.length && continues(splitComment(lines[at].text).code)) at += 1;
    return at + 1;
  }
  const firstEntry = lines.findIndex((line) => /^[a-z]/.test(line.text));
  return firstEntry >= 0 ? firstEntry : lines.length;
}

// Switches a Brewfile's entries to the tap: every bare `brew` entry naming
// a tap formula or alias, plus a trusted tap entry when the file then uses
// the tap. Runs in the browser only; the file is never sent anywhere.
export function migrateBrewfile(source: string, index: TapIndex): BrewfileMigration {
  const eol = source.includes("\r\n") ? "\r\n" : "\n";
  const warnings: string[] = [];
  const migrated = new Set<string>();
  let usesTap = false;
  let hasTap = false;

  const lines: Line[] = source.split(/\r?\n/).map((text) => {
    if (isOurTap(splitComment(text).code)) {
      hasTap = true;
      return changed(text, trustTap(text, warnings));
    }
    const { text: rewritten, tapFormula } = rewriteBrew(text, index);
    if (tapFormula === undefined) return { text };
    usesTap = true;
    if (rewritten !== text) migrated.add(tapFormula);
    return changed(text, rewritten);
  });

  if (usesTap && !hasTap) {
    lines.splice(insertionPoint(lines), 0, { text: TAP_LINE, inserted: true });
  }

  const changes = lines.flatMap((line, at): LineChange[] =>
    line.before !== undefined || line.inserted
      ? [{ line: at + 1, before: line.before, after: line.text }]
      : [],
  );
  return { text: lines.map((line) => line.text).join(eol), changes, migrated: [...migrated], warnings };
}
