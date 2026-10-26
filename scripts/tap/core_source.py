"""Reader for formulae in the local homebrew-core clone, pinned by commit."""

import os
import subprocess
from pathlib import Path


class CoreSourceError(RuntimeError):
    pass


def formula_relpath(name: str) -> str:
    shard = "lib" if name.startswith("lib") else name[0]
    return f"Formula/{shard}/{name}.rb"


def _git(repo: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "-C", str(repo), *args],
        check=False,
        capture_output=True,
        text=True,
    )


def core_repo() -> Path:
    override = os.environ.get("HOMEBREW_CORE_REPO")
    if override:
        return Path(override)
    result = subprocess.run(
        ["brew", "--repo", "homebrew/core"],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        msg = f"brew --repo homebrew/core failed: {result.stderr.strip()}"
        raise CoreSourceError(msg)
    return Path(result.stdout.strip())


def head_commit(repo: Path) -> str:
    result = _git(repo, "rev-parse", "HEAD")
    if result.returncode != 0:
        msg = f"{repo}: cannot resolve HEAD: {result.stderr.strip()}"
        raise CoreSourceError(msg)
    return result.stdout.strip()


def read_formula(repo: Path, name: str, commit: str) -> str:
    if _git(repo, "cat-file", "-e", f"{commit}^{{commit}}").returncode != 0:
        msg = f"commit {commit} not in {repo}; run: git -C {repo} fetch origin"
        raise CoreSourceError(msg)
    result = _git(repo, "show", f"{commit}:{formula_relpath(name)}")
    if result.returncode != 0:
        msg = f"{name}: {formula_relpath(name)} not found at core commit {commit}"
        raise CoreSourceError(msg)
    return result.stdout


def read_core_file(repo: Path, relpath: str, commit: str) -> str:
    result = _git(repo, "show", f"{commit}:{relpath}")
    if result.returncode != 0:
        msg = f"{relpath} not in core@{commit}: {result.stderr.strip()}"
        raise CoreSourceError(msg)
    return result.stdout


def read_core_aliases(repo: Path, commit: str) -> dict[str, str]:
    """Core's Aliases/ at a commit, as {alias: formula name}, read in one batch."""
    listing = _git(repo, "ls-tree", "-z", commit, "Aliases/")
    if listing.returncode != 0:
        msg = f"Aliases/ not readable at core@{commit}: {listing.stderr.strip()}"
        raise CoreSourceError(msg)
    links = {}
    for entry in filter(None, listing.stdout.split("\0")):
        meta, path = entry.split("\t", 1)
        mode, _, sha = meta.split()
        if mode == "120000":
            links[path.removeprefix("Aliases/")] = sha
    if not links:
        return {}
    batch = subprocess.run(
        ["git", "-C", str(repo), "cat-file", "--batch"],
        input="".join(f"{sha}\n" for sha in links.values()).encode(),
        check=False,
        capture_output=True,
    )
    if batch.returncode != 0:
        msg = f"cannot read Aliases/ at core@{commit}: {batch.stderr.decode().strip()}"
        raise CoreSourceError(msg)
    targets, offset = [], 0
    for _ in links:
        header_end = batch.stdout.index(b"\n", offset)
        size = int(batch.stdout[offset:header_end].split()[2])
        start = header_end + 1
        targets.append(batch.stdout[start : start + size].decode())
        offset = start + size + 1
    return {alias: Path(target).stem for alias, target in zip(links, targets, strict=True)}
