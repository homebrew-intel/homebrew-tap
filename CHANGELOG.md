# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed - 2026-10-27

- The builder plan no longer rebuilds a formula because a tap dependency
  was rebuilt in the same plan. As in homebrew-core, a formula builds only
  when forced or stale (no bottle for its current `pkg_version`); core bumps
  `revision` on dependents that need a rebuild. A python@3.15 patch bump had
  cascaded through z3, llvm, rust, just, mise and ruby: about 15 hours of
  `rebuild N` bottles for unchanged versions.

### Changed - 2026-10-25

- The organization was renamed from `homebrew-intel` to `macos-intel`: the
  tap is now `macos-intel/tap` and bottles download from
  `macos-intel/homebrew-tap`. See the README for moving installed kegs.

### Added - 2026-10-24

#### Core Formulae (11 total, up from 1)

- **New formulae enabled:** `cmake`, `gh`, `git`, `openssl@3`, `pkgconf`
- **Auto-dependencies:** `gettext`, `go`, `json-c`, `libunistring`, `pcre2`
- Growth: 1 → 11 formulae (1000% increase)

#### Automation Features

- **Auto-trigger builder workflow** ([#5](https://github.com/homebrew-intel/homebrew-tap/pull/5))
  - Automatically detects modified formulae on `main` push
  - Triggers builder workflow without manual intervention
  - Uses dedicated `homebrew-intel-internal` GitHub App for cross-repo dispatch
  - Security: Fixed GitHub Actions injection vulnerability

#### Build Planning

- **`--skip-unchanged` planner flag** for `plan.py`, `run.sh` and
  `render-plan.sh`
  - Skips a formula whose `<name>-<version>` release already exists
  - Not yet wired into the builder: `build.yml` has no input for it, so
    every build still plans without it

#### User Experience

- **`scripts/setup-intel.sh`** hides Homebrew's Intel Tier 3 warning
  - Adds `export HOMEBREW_DEVELOPER=1`, the only setting Homebrew checks
    before printing the warning, after explaining its side effects and asking
    for confirmation (`--yes` skips the question)
  - Detects zsh/bash, validates `$HOME`, and refuses a symlinked RC file
    unless `--allow-symlink` is given
- README explains the warning and the trade-off

### Fixed

- `scripts/setup-intel.sh` first set `HOMEBREW_NO_ENV_HINTS` and
  `HOMEBREW_NO_INSTALL_FROM_API`. Neither hides the warning, and the second
  makes Homebrew stop using its API. The script now warns when those lines
  are still in the RC file

### Changed

- Secrets configured for `homebrew-intel-internal` GitHub App
- Builder workflow now supports cross-repository dispatch

### Technical Details

#### Commits

- `6dab230` - tap: enable core development tools
- `ee86af4` - builder: add --skip-unchanged to avoid redundant rebuilds
- `c41c422` - ci: add auto-trigger for builder workflow
- `47a7d28` - docs: add Intel deprecation warning suppression (fixed since)
- `cc1a26a` - security: fix setup-intel.sh validation issues

#### Impact

- **Automation:** a formula change on `main` now starts a bottle build

## [0.1.0] - 2026-10-23

### Added

- Initial tap structure
- `lz4` formula with Intel Sequoia bottle
- Build infrastructure (VM runner, builder workflows)
- Render and drift check scripts

[Unreleased]: https://github.com/homebrew-intel/homebrew-tap/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/homebrew-intel/homebrew-tap/releases/tag/v0.1.0
