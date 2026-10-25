#!/usr/bin/env bash

set -Eeuo pipefail

# Writes static/bottles.json from the tap's GitHub releases, which the home
# page renders as the bottle list. Release tags are <formula>-<version>; a
# version never contains "-", so the last "-" splits them. Only the newest
# release per formula is kept.
repository="${GITHUB_REPOSITORY:-macos-intel/homebrew-tap}"
script_dir="$(dirname "$0")"
output="${script_dir}/../static/bottles.json"

mkdir -p "${script_dir}/../static"
gh api --paginate "repos/${repository}/releases?per_page=100" |
  jq -s '
    add
    | map(select(.draft | not))
    | map(.tag_name as $tag
        | ($tag | capture("^(?<name>.+)-(?<version>[^-]+)$"))
        + {url: .html_url, published: .published_at})
    | group_by(.name)
    | map(max_by(.published) | del(.published))
  ' >"${output}"

count="$(jq length "${output}")"
echo "bottles.json: ${count} formulae"
