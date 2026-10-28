"""Pure, line-based transforms from a homebrew-core formula to this tap's."""

import re
from collections.abc import Set as AbstractSet

TAP = "macos-intel/tap"
BOTTLE_MARKER = "  # bottle block: written by brew pr-pull"

_BOTTLE_START = "  bottle do"
_BOTTLE_END = "  end"
_HEADER_PATTERN = re.compile(
    r"# Generated from Homebrew/homebrew-core@([0-9a-f]{40}) by scripts/tap/render\.py; do not edit\."
)


class TransformError(ValueError):
    pass


def header(commit: str, name: str) -> str:
    return (
        f"# Generated from Homebrew/homebrew-core@{commit} by scripts/tap/render.py; do not edit.\n"
        f"# Hand-written changes belong in patches/{name}.patch.\n"
    )


def parse_header(text: str) -> str:
    match = _HEADER_PATTERN.fullmatch(text.split("\n", 1)[0])
    if match is None:
        msg = "first line is not a generated-formula header"
        raise TransformError(msg)
    return match.group(1)


def _bottle_spans(lines: list[str]) -> list[tuple[int, int]]:
    """Return (start, end) index pairs, end exclusive, of top-level bottle blocks."""
    spans = []
    index = 0
    while index < len(lines):
        if lines[index].rstrip() != _BOTTLE_START:
            index += 1
            continue
        end = next((i for i in range(index + 1, len(lines)) if lines[i].rstrip() == _BOTTLE_END), None)
        if end is None:
            msg = "bottle block has no closing end"
            raise TransformError(msg)
        spans.append((index, end + 1))
        index = end + 1
    return spans


def _lines(text: str) -> list[str]:
    return text.splitlines(keepends=True)


def mark_bottle_block(text: str, *, required: bool = True) -> str:
    lines = _lines(text)
    spans = _bottle_spans(lines)
    if len(spans) > 1:
        msg = f"expected one bottle block, found {len(spans)}"
        raise TransformError(msg)
    if not spans:
        if required:
            msg = "no bottle block found"
            raise TransformError(msg)
        return text
    start, end = spans[0]
    return "".join([*lines[:start], BOTTLE_MARKER + "\n", *lines[end:]])


def qualify_dependencies(text: str, tap_names: AbstractSet[str]) -> str:
    if not tap_names:
        return text
    names = "|".join(re.escape(name) for name in sorted(tap_names))
    pattern = re.compile(rf'^([ \t]*depends_on )"({names})"', re.MULTILINE)
    return pattern.sub(rf'\1"{TAP}/\2"', text)


_DEPENDS_ON = re.compile(r'^([ \t]*)depends_on "([^"]+)"(.*)$')
_CONDITIONAL = re.compile(r"\b(if|unless)\b")
# brew style's DependencyOrder: build-time > test > normal > recommended > optional.
_TYPE_RANK = ((":build", 0), (":test", 1), (":recommended", 3), (":optional", 4))
_NORMAL_RANK = 2


def _dependency_key(match: re.Match[str]) -> tuple[int, str]:
    rest = match.group(3)
    rank = next((rank for tag, rank in _TYPE_RANK if tag in rest), _NORMAL_RANK)
    return rank, match.group(2).lower()


def _ordered_run(run: list[tuple[str, re.Match[str]]]) -> list[str]:
    if any(_CONDITIONAL.search(match.group(3)) for _, match in run):
        return [line for line, _ in run]
    return [line for line, _ in sorted(run, key=lambda pair: _dependency_key(pair[1]))]


def order_dependencies(text: str) -> str:
    """Re-sort each run of same-indent depends_on lines the way brew style expects.

    Qualifying a name with the tap changes where it sorts, so a core formula's
    order no longer satisfies FormulaAudit/DependencyOrder. A comment line inside
    a run belongs to the dependency below it and moves with it, as brew style
    sorts across comments.
    """
    out: list[str] = []
    run: list[tuple[str, re.Match[str]]] = []
    comments: list[str] = []
    for line in _lines(text):
        match = _DEPENDS_ON.match(line.rstrip("\n"))
        indent = run[0][1].group(1) if run else None
        if match and (indent is None or match.group(1) == indent):
            run.append(("".join(comments) + line, match))
            comments = []
            continue
        if indent is not None and _is_comment(line, indent):
            comments.append(line)
            continue
        out.extend(_ordered_run(run))
        out.extend(comments)
        comments = []
        run = [(line, match)] if match else []
        if not match:
            out.append(line)
    out.extend(_ordered_run(run))
    out.extend(comments)
    return "".join(out)


def _is_comment(line: str, indent: str) -> bool:
    return line.startswith(f"{indent}#")


# brew refuses these in an unofficial tap ("no_autobump! can only be used in
# official Homebrew taps"), so the formula would not even load.
_OFFICIAL_ONLY = re.compile(r"^[ \t]*no_autobump!.*$")


def drop_official_only(text: str) -> str:
    lines = _lines(text)
    for index in reversed(range(len(lines))):
        if _OFFICIAL_ONLY.match(lines[index].rstrip("\n")):
            lines = _drop_span(lines, index, index + 1)
    return "".join(lines)


# Core formulae test dependency names bare (deps.map(&:name).include?("z3"),
# dep.name.start_with?("openssl@")); the render qualifies tap dependencies, so
# those predicates would silently miss (llvm drops z3) or yield nil. Names fed
# to formula_opt_prefix and friends may stay qualified: brew strips the tap.
_BARE = f'.delete_prefix("{TAP}/")'
_DEP_NAME_CALL = re.compile(r"\bdep\.name\.(?!delete_prefix\()(?=[a-z_]+[?!]?\b)")
_DEPS_MAP_NAME = re.compile(r"\bdeps\.map\(&:name\)")


def bare_dependency_names(text: str) -> str:
    text = _DEP_NAME_CALL.sub(f"dep.name{_BARE}.", text)
    return _fit_endless_defs(_DEPS_MAP_NAME.sub(f"deps.map {{ |dep| dep.name{_BARE} }}", text))


# The rewrite widens lines, and brew style allows 118 columns. An endless def
# pushed past that (rust's `def openssl = ...`) gets the multi-line body
# `brew style --fix` would give it.
_LINE_LIMIT = 118
_ENDLESS_DEF = re.compile(r"^([ \t]*)def ([a-z_]+[?!]?) = (.+)$")


def _fit_endless_defs(text: str) -> str:
    lines = _lines(text)
    for index, line in enumerate(lines):
        body = line.rstrip("\n")
        match = _ENDLESS_DEF.match(body)
        if match and len(body) > _LINE_LIMIT:
            indent, name, expression = match.groups()
            lines[index] = f"{indent}def {name}\n{indent}  {expression}\n{indent}end\n"
    return "".join(lines)


# Core keeps shared patch files in Patches/ at its root, and brew resolves a
# formula's `file` patch against its tap's root; the render copies them to
# CORE_PATCHES (not Patches/, which collides with patches/ on case-insensitive
# filesystems).
CORE_PATCHES = "core-patches"
_CORE_PATCH_FILE = re.compile(r'^([ \t]*file ")Patches/([^"]+)"', re.MULTILINE)
_TAP_PATCH_FILE = re.compile(rf'^[ \t]*file "{CORE_PATCHES}/([^"]+)"', re.MULTILINE)


def localize_core_patches(text: str) -> str:
    return _CORE_PATCH_FILE.sub(rf'\1{CORE_PATCHES}/\2"', text)


def core_patch_paths(text: str) -> list[str]:
    """Paths, relative to core's Patches/ and the tap's CORE_PATCHES, a rendered formula needs."""
    return _TAP_PATCH_FILE.findall(text)


def render_body(source: str, *, name: str, commit: str, tap_names: AbstractSet[str]) -> str:
    body = bare_dependency_names(localize_core_patches(drop_official_only(mark_bottle_block(source))))
    return header(commit, name) + order_dependencies(qualify_dependencies(body, tap_names))


def apply_bottle(body: str, bottle_block: str | None) -> str:
    if bottle_block is None:
        return body
    lines = _lines(body)
    marker = next((i for i, line in enumerate(lines) if line.rstrip() == BOTTLE_MARKER), None)
    if marker is None:
        msg = "bottle marker not found"
        raise TransformError(msg)
    return "".join([*lines[: marker + 1], bottle_block, *lines[marker + 1 :]])


def bottle_blocks(text: str) -> list[str]:
    lines = _lines(text)
    return ["".join(lines[start:end]) for start, end in _bottle_spans(lines)]


def extract_bottle_block(text: str) -> str | None:
    blocks = bottle_blocks(text)
    return blocks[0] if blocks else None


def _is_blank(line: str) -> bool:
    return not line.strip()


def _drop_span(lines: list[str], start: int, end: int) -> list[str]:
    rest = lines[end:]
    if start > 0 and rest and _is_blank(lines[start - 1]) and _is_blank(rest[0]):
        rest = rest[1:]
    return [*lines[:start], *rest]


def move_bottle_to_marker(text: str) -> str:
    """Put the bottle block right after the marker, where render and verify expect it.

    `brew bottle --write` places the block by its own rules: after `livecheck`
    when it can parse it, else after `license` (readline, whose livecheck nests
    a strategy block).
    """
    block = extract_bottle_block(text)
    if block is None or f"{BOTTLE_MARKER}\n{block}" in text:
        return text
    return apply_bottle(strip_bottle_block(text), block)


def strip_bottle_block(text: str) -> str:
    lines = _lines(text)
    for start, end in reversed(_bottle_spans(lines)):
        lines = _drop_span(lines, start, end)
    return "".join(lines)
