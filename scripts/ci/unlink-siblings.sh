#!/usr/bin/env bash

set -Eeuo pipefail

# Unlink every linked keg from outside this tap that is a versioned sibling of a
# tap formula about to be poured:
#   unlink-siblings.sh <name> ...
# A sibling shares the name before any "@" (ruby@3.3 for ruby, openssl@3 for
# openssl@4) and so links the same files. The hosted runner image links some
# (ruby@3.3), and `brew install --overwrite` never takes a file another keg
# owns, so the tap formula's link step fails. Kegs from this tap and kegs
# named on the command line are left alone. Only pour-test, on a throwaway
# hosted runner, calls this.

readonly tap="macos-intel/tap"

validate_arguments() {
  local name
  for name in "$@"
  do
    if [[ ! "${name}" =~ ^[a-z0-9][a-z0-9+_.@-]*$ ]]
    then
      echo "unlink-siblings: invalid formula name: '${name}'" >&2
      exit 2
    fi
  done
}

unlink_siblings_of() {
  local prefix="$1" name="$2" link keg receipt
  shift 2
  for link in "${prefix}/var/homebrew/linked/${name%@*}" "${prefix}/var/homebrew/linked/${name%@*}@"*
  do
    [[ -L "${link}" ]] || continue
    keg="${link##*/}"
    case " $* " in
      *" ${keg} "*) continue ;;
      *) ;;
    esac
    # A keg from this tap is one this run poured; keep it.
    receipt=""
    if [[ -f "${prefix}/opt/${keg}/INSTALL_RECEIPT.json" ]]
    then
      receipt="$(tr -d ' \n' <"${prefix}/opt/${keg}/INSTALL_RECEIPT.json")"
    fi
    [[ "${receipt}" != *"\"tap\":\"${tap}\""* ]] || continue
    echo "::notice::unlinking ${keg}: its links would block linking ${tap}/${name}"
    brew unlink "${keg}"
  done
}

main() {
  [[ $# -gt 0 ]] || exit 0
  validate_arguments "$@"
  local prefix name
  prefix="$(brew --prefix)"
  for name in "$@"
  do
    unlink_siblings_of "${prefix}" "${name}" "$@"
  done
}

main "$@"
