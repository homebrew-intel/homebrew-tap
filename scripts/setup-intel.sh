#!/usr/bin/env bash

set -euo pipefail

# Setup script for homebrew-intel tap users on Intel Macs.
# Configures environment to suppress Homebrew's Intel deprecation warnings.

echo "=== homebrew-intel tap setup ==="
echo ""

# Detect shell
SHELL_RC=""
if [ -n "${ZSH_VERSION:-}" ]; then
    SHELL_RC="$HOME/.zshrc"
    SHELL_NAME="zsh"
elif [ -n "${BASH_VERSION:-}" ]; then
    SHELL_RC="$HOME/.bashrc"
    SHELL_NAME="bash"
else
    echo "❌ Error: Could not detect shell (zsh/bash)"
    echo "   Manually add these to your shell config:"
    echo ""
    echo "   export HOMEBREW_NO_ENV_HINTS=1"
    echo "   export HOMEBREW_NO_INSTALL_FROM_API=1"
    exit 1
fi

echo "Detected shell: $SHELL_NAME"
echo "Config file: $SHELL_RC"
echo ""

# Check if already configured
if grep -q "HOMEBREW_NO_ENV_HINTS" "$SHELL_RC" 2>/dev/null; then
    echo "✅ Homebrew Intel suppression already configured in $SHELL_RC"
    echo ""
    echo "Current configuration:"
    grep "HOMEBREW_NO_ENV_HINTS\|HOMEBREW_NO_INSTALL_FROM_API" "$SHELL_RC" || true
else
    # Add configuration
    cat >> "$SHELL_RC" << 'SHELLRC'

# homebrew-intel tap: suppress Intel deprecation warnings
# The homebrew-intel tap provides Intel bottles, so these warnings are not relevant.
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_INSTALL_FROM_API=1
SHELLRC

    echo "✅ Added Homebrew Intel suppression to $SHELL_RC"
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
echo "  source $SHELL_RC"
echo ""
echo "Or restart your terminal."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
