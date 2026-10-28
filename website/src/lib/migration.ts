import { TAP, type Bottle } from "./bottle";

export type DependencyMap = ReadonlyMap<string, readonly string[]>;

export function dependencyMap(bottles: readonly Bottle[]): DependencyMap {
  return new Map(bottles.map((bottle) => [bottle.name, bottle.deps]));
}

// Orders the formulae and every tap dependency they reach so each one comes
// after its dependencies, as getting-started.md asks: reinstalling a formula
// before its dependency would pull core's copy of the dependency back in.
// Depth-first post-order, visiting names alphabetically so the output is
// stable. A cycle cannot occur in brew, but a malformed list must not hang
// the page, so a name already on the path is skipped.
export function installOrder(names: Iterable<string>, deps: DependencyMap): string[] {
  const order: string[] = [];
  const done = new Set<string>();
  const onPath = new Set<string>();

  function visit(name: string): void {
    if (done.has(name) || onPath.has(name)) return;
    onPath.add(name);
    for (const dep of [...(deps.get(name) ?? [])].sort()) visit(dep);
    onPath.delete(name);
    done.add(name);
    order.push(name);
  }

  for (const name of [...names].sort()) visit(name);
  return order;
}

// The commands that switch installed core kegs to the tap: one reinstall
// per formula, dependencies first.
export function migrationCommands(names: Iterable<string>, deps: DependencyMap): string {
  const reinstalls = installOrder(names, deps).map((name) => `brew reinstall ${TAP}/${name}`);
  return [`brew tap ${TAP}`, `brew trust ${TAP}`, ...reinstalls].join("\n");
}
