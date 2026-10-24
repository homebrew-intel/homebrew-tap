#!/usr/bin/env bash

set -euo pipefail

# Setup script for homebrew-intel tap users on Intel Macs.
# Configures environment to suppress Homebrew's Intel deprecation warnings.
#
# Usage: ./scripts/setup-intel.sh [--allow-symlink]
#   --allow-symlink: Allow modifying symlinked shell RC files (use with caution)

# Parse arguments
ALLOW_SYMLINK=no
while [[ $# -gt 0 ]]
do
  case "$1" in
    --allow-symlink)
      ALLOW_SYMLINK=yes
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: $0 [--allow-symlink]"
      exit 1
      ;;
  esac
done

echo "=== homebrew-intel tap setup ==="
echo ""

# Validate $HOME
if [[ -z "${HOME}" ]]
then
  echo "❌ Error: \$HOME is not set"
  exit 1
fi

if [[ "${HOME}" != /* ]]
then
  echo "❌ Error: \$HOME is not an absolute path: ${HOME}"
  exit 1
fi

if [[ ! -d "${HOME}" ]]
then
  echo "❌ Error: \$HOME is not a directory: ${HOME}"
  exit 1
fi

# Detect user's login shell (not the script's interpreter)
USER_SHELL="${SHELL##*/}"
SHELL_RC=""
SHELL_NAME=""

case "${USER_SHELL}" in
  zsh)
    SHELL_RC="${HOME}/.zshrc"
    SHELL_NAME="zsh"
    ;;
  bash)
    SHELL_RC="${HOME}/.bashrc"
    SHELL_NAME="bash"
    ;;
  *)
    echo "❌ Error: Unsupported shell: ${USER_SHELL}"
    echo "   Detected: \$SHELL=${SHELL}"
    echo ""
    echo "   Manually add these to your shell config:"
    echo "   export HOMEBREW_NO_ENV_HINTS=1"
    echo "   export HOMEBREW_NO_INSTALL_FROM_API=1"
    exit 1
    ;;
esac

# Validate shell RC file
if [[ -e "${SHELL_RC}" ]]
then
  if [[ ! -f "${SHELL_RC}" ]]
  then
    echo "❌ Error: ${SHELL_RC} is not a regular file"
    exit 1
  fi
  if [[ -L "${SHELL_RC}" ]]
  then
    if [[ "${ALLOW_SYMLINK}" = yes ]]
    then
      echo "⚠️  Warning: ${SHELL_RC} is a symlink"
      echo "   Proceeding because --allow-symlink was specified"
      echo ""
    else
      echo "❌ Error: ${SHELL_RC} is a symlink — refusing to modify"
      echo "   (managed dotfiles detected)"
      echo ""
      echo "   If you manage your dotfiles with symlinks:"
      echo "   1. Run: ./scripts/setup-intel.sh --allow-symlink"
      echo "   2. Or manually add to your dotfiles source:"
      echo "      export HOMEBREW_NO_ENV_HINTS=1"
      echo "      export HOMEBREW_NO_INSTALL_FROM_API=1"
      exit 1
    fi
  fi
fi

echo "Detected shell: ${SHELL_NAME}"
echo "Config file: ${SHELL_RC}"
echo ""

# Check if already configured
if grep -q "HOMEBREW_NO_ENV_HINTS" "${SHELL_RC}" 2>/dev/null
then
  echo "✅ Homebrew Intel suppression already configured in ${SHELL_RC}"
  echo ""
  echo "Current configuration:"
  grep "HOMEBREW_NO_ENV_HINTS\|HOMEBREW_NO_INSTALL_FROM_API" "${SHELL_RC}" || true
else
  # Add configuration
  cat >>"${SHELL_RC}" <<'SHELLRC'

# homebrew-intel tap: suppress Intel deprecation warnings
# The homebrew-intel tap provides Intel bottles, so these warnings are not relevant.
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_INSTALL_FROM_API=1
SHELLRC

  echo "✅ Added Homebrew Intel suppression to ${SHELL_RC}"
  echo ""
  echo "Added lines:"
  echo "  export HOMEBREW_NO_ENV_HINTS=1"
  echo "  export HOMEBREW_NO_INSTALL_FROM_API=1"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Setup complete!"
echo ""
echo "To activate now:"
echo "  source ${SHELL_RC}"
echo ""
echo "Or restart your terminal."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
