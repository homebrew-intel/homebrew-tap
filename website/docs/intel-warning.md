---
sidebar_position: 3
---

# The Intel warning

On Intel, `brew install` and `brew doctor` warn that macOS on Intel x86_64 is
a Tier 3 configuration. The warning is expected when you use this tap, and it
does not stop anything from installing.

## Hiding it

Homebrew has no setting that hides only this warning. It is skipped when
`HOMEBREW_DEVELOPER=1` is set, but that variable also changes how Homebrew
updates and adds developer checks, so only set it if you accept that.
`HOMEBREW_NO_ENV_HINTS=1` hides Homebrew's environment hints, not this
warning.

To add it to your shell config, run the setup script from a clone of the
tap. It explains the trade-off and asks before changing anything:

```bash
./scripts/setup-intel.sh
```
