"""The tap's Aliases/: core's aliases of tap formulae, as relative symlinks."""

import subprocess
import sys
from collections.abc import Mapping
from pathlib import Path

from core_source import CoreSourceError, formula_relpath, read_core_aliases

ALIASES = "Aliases"


def commit_time(repo: Path, commit: str) -> int:
    result = subprocess.run(
        ["git", "-C", str(repo), "show", "-s", "--format=%ct", commit],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        msg = f"commit {commit} not in {repo}; run: git -C {repo} fetch origin"
        raise CoreSourceError(msg)
    return int(result.stdout)


def expected_aliases(repo: Path, header_commits: Mapping[str, str]) -> dict[str, str]:
    """{alias: link target} for each core alias of a tap formula, read at that formula's header commit.

    When formulae rendered at different commits claim one alias, the newest commit wins.
    """
    by_commit: dict[str, set[str]] = {}
    for name, commit in header_commits.items():
        by_commit.setdefault(commit, set()).add(name)
    expected = {}
    for commit in sorted(by_commit, key=lambda commit: commit_time(repo, commit)):
        for alias, target in read_core_aliases(repo, commit).items():
            if target in by_commit[commit]:
                expected[alias] = f"../{formula_relpath(target)}"
    return dict(sorted(expected.items()))


def actual_aliases(tap_dir: Path) -> dict[str, str | None]:
    """{alias: link target}; None for an entry that is not a symlink."""
    directory = tap_dir / ALIASES
    if not directory.is_dir():
        return {}
    return {path.name: str(path.readlink()) if path.is_symlink() else None for path in sorted(directory.iterdir())}


def write_aliases(tap_dir: Path, expected: Mapping[str, str]) -> None:
    directory = tap_dir / ALIASES
    for alias, target in actual_aliases(tap_dir).items():
        if expected.get(alias) != target:
            (directory / alias).unlink()
            if alias not in expected:
                print(f"render: removed {ALIASES}/{alias}", file=sys.stderr)
    for alias, target in expected.items():
        link = directory / alias
        if not link.is_symlink():
            directory.mkdir(exist_ok=True)
            link.symlink_to(target)


def check_aliases(tap_dir: Path, expected: Mapping[str, str]) -> list[str]:
    actual = actual_aliases(tap_dir)
    problems = []
    for alias in sorted(expected.keys() | actual.keys()):
        want, have = expected.get(alias), actual.get(alias, "")
        if want == have:
            continue
        label = f"{ALIASES}/{alias}"
        if want is None:
            problems.append(f"{label}: not a core alias of a tap formula; run mise run render")
        elif have == "":
            problems.append(f"{label}: missing; run mise run render")
        elif have is None:
            problems.append(f"{label}: not a symlink, expected -> {want}")
        else:
            problems.append(f"{label}: -> {have}, expected -> {want}")
    return problems
