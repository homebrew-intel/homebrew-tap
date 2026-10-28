// Grouping and selection logic for the bottle list, kept free of React so it
// can be unit tested.

export type Group = { initial: string; names: string[] };

// Names that start with a digit share one "#" group.
export function initialOf(name: string): string {
  const first = name.charAt(0).toUpperCase();
  return /[0-9]/.test(first) ? "#" : first;
}

// One group per initial that has a name matching the query (a substring,
// case-insensitive), in order. An empty query matches every name, so only
// initials with formulae ever get a group.
export function groupNames(names: readonly string[], query: string): Group[] {
  const needle = query.trim().toLowerCase();
  const groups = new Map<string, string[]>();
  for (const name of [...names].sort()) {
    if (!name.toLowerCase().includes(needle)) continue;
    const initial = initialOf(name);
    groups.set(initial, [...(groups.get(initial) ?? []), name]);
  }
  return [...groups].map(([initial, members]) => ({ initial, names: members }));
}

// Every name the groups show, in list order: what the "All" checkbox covers.
export function shownNames(groups: readonly Group[]): string[] {
  return groups.flatMap((group) => group.names);
}

export type GroupState = "none" | "some" | "all";

export function groupState(names: readonly string[], selected: ReadonlySet<string>): GroupState {
  const count = names.filter((name) => selected.has(name)).length;
  if (count === 0) return "none";
  return count === names.length ? "all" : "some";
}

export function toggleName(selected: ReadonlySet<string>, name: string): Set<string> {
  const next = new Set(selected);
  if (!next.delete(name)) next.add(name);
  return next;
}

// A group checkbox selects every name it is given unless all of them are
// already selected, then it clears them. The caller passes the names the
// group shows, so with a filter active only the visible ones change.
export function toggleGroup(selected: ReadonlySet<string>, names: readonly string[]): Set<string> {
  const next = new Set(selected);
  const clear = groupState(names, selected) === "all";
  for (const name of names) {
    if (clear) next.delete(name);
    else next.add(name);
  }
  return next;
}

// Reads a saved selection, dropping anything that is not a known formula
// (one leaving the tap, or a hand-edited value). Invalid input yields an
// empty selection rather than an error.
export function restoreSelection(saved: string | null, known: ReadonlySet<string>): Set<string> {
  if (!saved) return new Set();
  try {
    const parsed: unknown = JSON.parse(saved);
    if (!Array.isArray(parsed)) return new Set();
    return new Set(parsed.filter((name): name is string => typeof name === "string" && known.has(name)));
  } catch {
    return new Set();
  }
}

export function serializeSelection(selected: ReadonlySet<string>): string {
  return JSON.stringify([...selected].sort());
}
