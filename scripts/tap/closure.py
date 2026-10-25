"""Dependency expansion and build order over homebrew-core API formula dicts."""

from collections.abc import Iterable, Mapping
from collections.abc import Set as AbstractSet

BOTTLED_INTEL_TAGS = frozenset({"all", "sequoia", "sonoma", "ventura", "monterey", "big_sur"})
# The API's top-level dependency lists describe ARM macOS. What differs on the
# Intel system the bottles are built on sits in formula["variations"][tag],
# where each key present replaces the top-level one outright, as brew's
# Homebrew::API.merge_variations does with a shallow Hash#merge.
INTEL_VARIATION = "sequoia"
# What building, testing and bottling a formula on the Intel host installs:
# brew pours its runtime dependencies and builds none of its build or test
# dependencies itself (`brew test` refuses to run without the test ones).
BUILD_KEYS = ("dependencies", "build_dependencies", "test_dependencies")


class DependencyCycleError(ValueError):
    """The closure's dependencies loop, so no build order exists."""

    def __init__(self, cycle: list[str]) -> None:
        self.cycle = cycle
        path = " -> ".join(cycle)
        super().__init__(
            f"dependency cycle {path} (Intel runtime, build and test dependencies); "
            "break it with a patch that drops one of these edges, or disable what pulls them in"
        )


def needs_intel_bottle(formula: Mapping) -> bool:
    files = ((formula.get("bottle") or {}).get("stable") or {}).get("files", {})
    return BOTTLED_INTEL_TAGS.isdisjoint(files)


def dependencies(name: str, formulae: Mapping[str, Mapping], *keys: str) -> list[str]:
    formula = formulae.get(name, {})
    intel = (formula.get("variations") or {}).get(INTEL_VARIATION) or {}
    return [dependency for key in keys for dependency in intel.get(key, formula.get(key)) or []]


def expand(enabled: Iterable[str], formulae: Mapping[str, Mapping]) -> set[str]:
    """The enabled names plus every dependency they need that has no Intel bottle.

    Runtime dependencies are followed through bottled formulae too, since a
    poured keg still needs its own. Build and test dependencies are followed
    only for formulae in the result: the tap builds and tests those, while a
    bottled formula is poured, never built.

    A core formula in the result's lock tree that depends, in any way, on a
    formula in the result joins it: core names its dependencies bare, so the
    tree would hold core's copy next to the tap's, and brew locks both by one
    rack name (core zstd's xz, core libpsl's pkgconf). Joining can make
    another core formula qualify, so this repeats until stable.
    """
    result = set(enabled)
    while True:
        _add_unbottled(result, formulae)
        joining = {
            name
            for name in _lock_tree(result, formulae) - result
            if not result.isdisjoint(dependencies(name, formulae, *BUILD_KEYS))
        }
        if not joining:
            return result
        result |= joining


def _lock_tree(result: AbstractSet[str], formulae: Mapping[str, Mapping]) -> set[str]:
    """Every formula brew locks when installing one in result.

    FormulaInstaller#lock takes recursive_dependencies without a block, which
    keeps the build and test dependencies of every dependency, at any depth.
    """
    tree: set[str] = set()
    pending = sorted(result)
    while pending:
        name = pending.pop()
        if name in tree:
            continue
        tree.add(name)
        pending.extend(d for d in dependencies(name, formulae, *BUILD_KEYS) if d in formulae)
    return tree


def _add_unbottled(result: set[str], formulae: Mapping[str, Mapping]) -> None:
    """Add every dependency without an Intel bottle that result builds or pours."""
    visited: set[str] = set()
    pending = sorted(result)
    while pending:
        name = pending.pop()
        if name in visited:
            continue
        visited.add(name)
        keys = BUILD_KEYS if name in result else ("dependencies",)
        for dependency in dependencies(name, formulae, *keys):
            known = dependency in formulae
            if known and needs_intel_bottle(formulae[dependency]):
                result.add(dependency)
            if known:
                pending.append(dependency)


def build_order(names: AbstractSet[str], formulae: Mapping[str, Mapping]) -> list[str]:
    prerequisites = {name: {d for d in dependencies(name, formulae, *BUILD_KEYS) if d in names} for name in names}
    order: list[str] = []
    remaining = dict(prerequisites)
    while remaining:
        ready = sorted(name for name, needed in remaining.items() if not needed)
        if not ready:
            raise DependencyCycleError(find_cycle(remaining))
        order.append(ready[0])
        del remaining[ready[0]]
        for needed in remaining.values():
            needed.discard(ready[0])
    return order


def find_cycle(prerequisites: Mapping[str, AbstractSet[str]]) -> list[str]:
    """One cycle, closed on its first name, where every name still needs another.

    Following any prerequisite from any name must revisit a name; the walk is
    sorted so the reported cycle is stable.
    """
    path: list[str] = []
    name = min(prerequisites)
    while name not in path:
        path.append(name)
        name = min(prerequisites[name])
    return [*path[path.index(name) :], name]
