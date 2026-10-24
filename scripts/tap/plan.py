"""Decide which tap formulae need Intel bottles built, in dependency order."""

import argparse
import subprocess
import sys
from collections.abc import Mapping
from collections.abc import Set as AbstractSet
from pathlib import Path

from bottles import api_core_commit, pkg_version
from closure import BUILD_KEYS, build_order, dependencies, expand
from core_source import formula_relpath
from enabled import ConfigError, load_enabled
from render import TAP_ROOT, load_formulae
from transform import extract_bottle_block


class PlanError(RuntimeError):
    pass


def tap_dependencies(name: str, order: list[str], formulae: Mapping[str, Mapping]) -> list[str]:
    return [d for d in dependencies(name, formulae, *BUILD_KEYS) if d in order]


def is_bottled(tap_dir: Path, name: str) -> bool:
    path = tap_dir / formula_relpath(name)
    return path.is_file() and extract_bottle_block(path.read_text(encoding="utf-8")) is not None


def bottle_exists_gh(name: str, version: str) -> bool:
    """Check if a bottle exists in GitHub Releases for the given formula version."""
    tag = f"{name}-{version}"
    result = subprocess.run(
        ["gh", "release", "view", tag, "-R", "homebrew-intel/homebrew-tap"],
        capture_output=True,
        text=True,
        check=False,
    )
    return result.returncode == 0


def needs_build(
    order: list[str],
    tap_dir: Path,
    formulae: Mapping[str, Mapping],
    forced: AbstractSet[str],
    *,
    skip_unchanged: bool = False,
) -> list[str]:
    built: list[str] = []
    for name in order:
        # Always build forced formulae
        if name in forced:
            built.append(name)
            continue

        # Skip if bottle exists for current version (only when skip_unchanged enabled)
        if skip_unchanged:
            version = pkg_version(formulae[name]) if name in formulae else None
            if version and bottle_exists_gh(name, version):
                # Still need to rebuild if a dependency was rebuilt
                if any(d in built for d in tap_dependencies(name, order, formulae)):
                    built.append(name)
                continue

        # Default behavior: build if stale or dependency was rebuilt
        stale = not is_bottled(tap_dir, name)
        if stale or any(d in built for d in tap_dependencies(name, order, formulae)):
            built.append(name)
    return built


def build_line(name: str, order: list[str], formulae: Mapping[str, Mapping]) -> str:
    version = pkg_version(formulae[name]) if name in formulae else "-"
    return " ".join([name, version, *tap_dependencies(name, order, formulae)])


def parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("commit", help="print the homebrew-core commit of the API snapshot")
    builds = commands.add_parser("builds", help="print one line per formula to build")
    builds.add_argument("--force", action="append", default=[], metavar="NAME", help="build NAME regardless")
    builds.add_argument(
        "--skip-unchanged",
        action="store_true",
        help="skip formulae that already have bottles for the current version",
    )
    return parser.parse_args(argv)


def run(args: argparse.Namespace) -> None:
    formulae = load_formulae()
    if args.command == "commit":
        print(api_core_commit(formulae.values()))
        return
    enabled = [entry.name for entry in load_enabled(TAP_ROOT / "enabled.toml")]
    order = build_order(expand(enabled, formulae), formulae)
    unknown = sorted(set(args.force) - set(order))
    if unknown:
        message = f"--force names not in the build set: {', '.join(unknown)}"
        raise PlanError(message)
    skip_unchanged = getattr(args, "skip_unchanged", False)
    for name in needs_build(order, TAP_ROOT, formulae, frozenset(args.force), skip_unchanged=skip_unchanged):
        print(build_line(name, order, formulae))


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        run(args)
    except (ConfigError, PlanError, ValueError, OSError) as error:
        print(f"plan: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
