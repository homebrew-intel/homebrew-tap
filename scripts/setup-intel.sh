#!/usr/bin/env bash

set -euo pipefail

# Setup script for macos-intel tap users on Intel Macs.
# Hides Homebrew's Intel x86_64 Tier 3 warning. Homebrew skips that warning
# only when HOMEBREW_DEVELOPER is set (check_for_unsupported_macos in
# Library/Homebrew/extend/os/mac/diagnostic.rb); no narrower setting exists.
#
# Usage: ./scripts/setup-intel.sh [--allow-symlink] [--yes]
#   --allow-symlink: Allow modifying symlinked shell RC files (use with caution)
#   --yes:           Do not ask for confirmation

SETTING="export HOMEBREW_DEVELOPER=1"
MARKER="# homebrew-intel tap: hide the Intel Tier 3 warning"
# Lines an earlier version of this script added; neither hides the warning.
OLD_SETTINGS="HOMEBREW_NO_ENV_HINTS|HOMEBREW_NO_INSTALL_FROM_API"

usage() {
  echo "Usage: $0 [--allow-symlink] [--yes]"
}

print_manual_setting() {
  echo "   Add this to your shell config instead:"
  echo "   ${SETTING}"
}

ALLOW_SYMLINK=no
ASSUME_YES=no
while [[ $# -gt 0 ]]
do
  case "$1" in
    --allow-symlink) ALLOW_SYMLINK=yes ;;
    --yes) ASSUME_YES=yes ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

echo "=== macos-intel tap setup ==="
echo ""

# Validate $HOME
if [[ -z "${HOME:-}" || "${HOME}" != /* || ! -d "${HOME}" ]]
then
  echo "❌ Error: \$HOME must be an existing absolute directory: ${HOME:-<unset>}"
  exit 1
fi

# Detect user's login shell (not the script's interpreter)
case "${SHELL##*/}" in
  zsh) SHELL_RC="${HOME}/.zshrc" ;;
  bash) SHELL_RC="${HOME}/.bashrc" ;;
  *)
    echo "❌ Error: Unsupported shell: \$SHELL=${SHELL}"
    print_manual_setting
    exit 1
    ;;
esac

# Validate shell RC file
if [[ -e "${SHELL_RC}" && ! -f "${SHELL_RC}" ]]
then
  echo "❌ Error: ${SHELL_RC} is not a regular file"
  exit 1
fi
if [[ -L "${SHELL_RC}" && "${ALLOW_SYMLINK}" != yes ]]
then
  echo "❌ Error: ${SHELL_RC} is a symlink (managed dotfiles); refusing to modify"
  echo "   Rerun with --allow-symlink, or edit your dotfiles source."
  print_manual_setting
  exit 1
fi

echo "Config file: ${SHELL_RC}"
echo ""

if grep -Eq "${OLD_SETTINGS}" "${SHELL_RC}" 2>/dev/null
then
  echo "⚠️  ${SHELL_RC} still sets variables an earlier version of this script"
  echo "   added. They do not hide the warning, and HOMEBREW_NO_INSTALL_FROM_API"
  echo "   makes Homebrew stop using its API. Remove these lines:"
  grep -En "${OLD_SETTINGS}" "${SHELL_RC}" || true
  echo ""
fi

if grep -q "HOMEBREW_DEVELOPER" "${SHELL_RC}" 2>/dev/null
then
  echo "✅ HOMEBREW_DEVELOPER is already set in ${SHELL_RC}; nothing to do."
  exit 0
fi

echo "HOMEBREW_DEVELOPER=1 hides the warning, but it also turns on Homebrew's"
echo "developer mode: deprecation warnings become errors and \`brew update\`"
echo "behaves as it does for Homebrew maintainers."
if [[ "${ASSUME_YES}" != yes ]]
then
  read -r -p "Add '${SETTING}' to ${SHELL_RC}? [y/N] " answer
  if [[ "${answer}" != [yY] ]]
  then
    echo "Nothing changed."
    exit 0
  fi
fi

printf '\n%s\n%s\n' "${MARKER}" "${SETTING}" >>"${SHELL_RC}"

echo "✅ Added to ${SHELL_RC}: ${SETTING}"
echo "Run \`source ${SHELL_RC}\` or restart your terminal."
