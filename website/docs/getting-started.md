---
sidebar_position: 1
---

# Getting started

## Requirements

- An Intel Mac with Homebrew in `/usr/local`. Bottles are built there.
- macOS Sequoia 15. Tahoe 26 support is planned.

## Tap it

Formulae here have the same names as core. Install them **fully
qualified**, for example `macos-intel/tap/cmake`. A bare name installs
core's version.

```bash
brew tap macos-intel/tap
brew trust macos-intel/tap
brew install macos-intel/tap/cmake
```

## Switch a keg you already have

`brew install` refuses a name installed from another tap, so switch with
`brew reinstall`:

```bash
brew reinstall macos-intel/tap/cmake
```

Switch the formula's tap dependencies first: run
`brew reinstall macos-intel/tap/<dep>` for each one, in dependency order.

A keg you built from source with `--build-bottle` keeps building on
`reinstall`. Switch it with `brew uninstall` and then `brew install`.

## Use a Brewfile

```ruby
tap "macos-intel/tap", trusted: true
brew "macos-intel/tap/cmake"
```

## Staying up to date

Once installed, a formula follows the tap. When core bumps it, you stay on
the tap's last published version until the new bottle is published. Expect
one day plus build time.
