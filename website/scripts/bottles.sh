#!/usr/bin/env bash

set -Eeuo pipefail

# Writes static/bottles.json from the tap's GitHub releases, which the home
# page renders as the bottle list. Release tags are <formula>-<version>; a
# version never contains "-", so the last "-" splits them. Only the newest
# release per formula is kept.
#
# Each entry also carries what the page needs to migrate kegs and Brewfiles
# without asking brew: `deps`, the formula's tap runtime dependencies (so the
# reinstall commands can run dependencies first), and `aliases`, the core
# aliases the tap mirrors in Aliases/ (so `brew "pkg-config"` maps to
# pkgconf). Both are read from the checkout, which the pages workflow has.
repository="${GITHUB_REPOSITORY:-macos-intel/homebrew-tap}"
script_dir="$(dirname "$0")"
tap_root="${script_dir}/../.."
output="${script_dir}/../static/bottles.json"

# Prints "<formula>\t<dep>" for every tap runtime dependency on Intel
# Sequoia; runtime-deps.awk says which lines count. Kept in its own file
# because brew style's shfmt wrapper cannot parse a multi-line awk program.
runtime_deps() {
  awk -f "${script_dir}/runtime-deps.awk" "${tap_root}"/Formula/*/*.rb
}

# Prints "<formula>\t<alias>" for every symlink in Aliases/.
aliases() {
  local link target
  for link in "${tap_root}"/Aliases/*
  do
    [[ -L "${link}" ]] || continue
    target="$(readlink "${link}")"
    target="${target##*/}"
    printf '%s\t%s\n' "${target%.rb}" "${link##*/}"
  done
}

# Turns "<formula>\t<value>" lines into {"<formula>": ["<value>", ...]}.
to_map() {
  jq -R -s '
    split("\n")
    | map(select(length > 0) | split("\t"))
    | group_by(.[0])
    | map({key: .[0][0], value: (map(.[1]) | unique)})
    | from_entries
  '
}

deps_json="$(runtime_deps | to_map)"
aliases_json="$(aliases | to_map)"

mkdir -p "${script_dir}/../static"
gh api --paginate "repos/${repository}/releases?per_page=100" |
  jq -s --argjson deps "${deps_json}" --argjson aliases "${aliases_json}" '
    add
    | map(select(.draft | not))
    | map(.tag_name as $tag
        | ($tag | capture("^(?<name>.+)-(?<version>[^-]+)$"))
        + {url: .html_url, published: .published_at})
    | group_by(.name)
    | map(max_by(.published) | del(.published)
        | . + {deps: ($deps[.name] // []), aliases: ($aliases[.name] // [])})
  ' >"${output}"

count="$(jq length "${output}")"
echo "bottles.json: ${count} formulae"
