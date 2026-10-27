#!/usr/bin/env bash

set -Eeuo pipefail

# Build, bottle and test one tap formula on the Intel host:
#   build-formula.sh <name> <pkg-version> <out-dir>
# Leaves the bottle tarball (renamed to the bottle JSON's decoded filename) and
# the bottle JSON in <out-dir>, and writes the bottle block into the checkout's
# formula. It uploads nothing and needs no token: the hosted publish job does
# that after verifying the output. The installed keg is swapped through
# keg-swap.sh, so a failure or interruption reinstalls the previous one.
# Must stay compatible with macOS /bin/bash 3.2.
# The embedded Python never starts a line with `if`: brew style's shfmt
# wrapper would take it for a shell `if` and reindent the snippet.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly script_dir
# shellcheck source=scripts/builder/keg.sh
source "${script_dir}/keg.sh"
# shellcheck source=scripts/builder/keg-swap.sh
source "${script_dir}/keg-swap.sh"

name=""
version=""
out_dir=""
bottle_json=""

log() {
  echo "build-formula: $*" >&2
}

validate_arguments() {
  if [[ $# -ne 3 ]]
  then
    log "usage: build-formula.sh <name> <pkg-version> <out-dir>"
    exit 2
  fi
  if [[ ! "$1" =~ ${NAME_PATTERN} || ! "$2" =~ ^[0-9A-Za-z][0-9A-Za-z._+-]*$ ]]
  then
    log "invalid formula name or version: '$1' '$2'"
    exit 2
  fi
}

# A clean host has no test dependencies, and `brew test` refuses to run
# without them; --include-test installs them (the closure gives those core
# lacks an Intel bottle a tap one, built earlier in the plan).
build() {
  keg_touched=yes
  run_brew install install --build-bottle --include-test "${TAP}/${name}"
}

# A --build-bottle keg skips post_install, which some tests rely on (ruby's
# points libruby's install name at opt/ruby@<major.minor>). The bottle is
# already written, so post_install changes nothing in it; the block is merged
# only once the test passed. The test runs with unrelated kegs unlinked.
post_install_and_test() {
  run_brew install postinstall "${TAP}/${name}"
  isolate_test "${TAP}/${name}"
  run_brew install test "${TAP}/${name}"
  relink_isolated
}

# Prints "<local_filename> <decoded filename>" of the bottle JSON's single tag.
bottle_filenames() {
  python3 -c '
import json, os, sys
from urllib.parse import unquote
document = json.load(open(sys.argv[1], encoding="utf-8"))
(entry,) = document.values()
(tag,) = entry["bottle"]["tags"].values()
# brew URL-encodes filename (python@3.12 -> python%403.12); GitHub serves the
# asset under its decoded name, so that is the name to upload.
names = (tag["local_filename"], unquote(tag["filename"]))
safe = all(os.path.basename(n) == n and not n.startswith(".") for n in names)
print(*names) if safe else sys.exit(f"unsafe bottle filename in {sys.argv[1]}")
' "$1"
}

# Writes the bottle into out_dir and renames the tarball to the JSON's
# filename; sets bottle_json.
write_bottle() {
  local root_url="$1" matches pair local_file filename
  (cd "${out_dir}" && brew bottle --json --root-url="${root_url}" "${TAP}/${name}")
  matches="$(find "${out_dir}" -maxdepth 1 -name "${name}--${version}.*.bottle.json")"
  if [[ -z "${matches}" || "${matches}" == *$'\n'* ]]
  then
    log "expected exactly one ${name}--${version}.*.bottle.json in ${out_dir}"
    return 1
  fi
  pair="$(bottle_filenames "${matches}")"
  read -r local_file filename <<<"${pair}"
  if [[ "${local_file}" != "${filename}" ]]
  then
    mv -f "${out_dir}/${local_file}" "${out_dir}/${filename}"
  fi
  bottle_json="${matches}"
}

# Merges the bottle block into the formula.
merge_bottle() {
  local formula_file
  brew bottle --merge --write --no-commit "${bottle_json}"
  # brew places the block by its own rules (after license when it cannot
  # parse a livecheck block, as for readline); verify wants it at the marker.
  formula_file="$(brew formula "${TAP}/${name}")"
  python3 "${script_dir}/../tap/bottles.py" place "${formula_file}"
}

main() {
  validate_arguments "$@"
  name="$1"
  version="$2"
  mkdir -p "$3"
  out_dir="$(cd "$3" && pwd -P)"
  local root_url
  root_url="$(python3 "${script_dir}/../tap/bottles.py" root-url "${name}" "${version}")"
  start_keg_swap "${name}"
  build
  write_bottle "${root_url}"
  post_install_and_test
  merge_bottle
  log "bottled ${name} ${version}"
}

main "$@"
