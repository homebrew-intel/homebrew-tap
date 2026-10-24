# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

#### Build Optimizations
- **Skip unchanged formulae** in manual builds
  - `--skip-unchanged` flag for `plan.py` and builder
  - Checks GitHub Releases for existing bottles at current version
  - Saves ~90% build time when source unchanged (e.g., cmake: ~20min → instant)
  - Example: `gh workflow run build.yml -f formulae="cmake" -f skip-unchanged=true`

#### User Experience
- **Intel deprecation warning suppression**
  - `scripts/setup-intel.sh` to configure shell environment
  - Suppresses Homebrew's Intel x86_64 deprecation warnings
  - Detects zsh/bash and configures automatically
  - README documentation added
  - Security: Validates `$HOME`, RC files, and handles symlinked dotfiles safely

### Security
- **Fixed setup-intel.sh validation issues**
  - Added `$HOME` validation (absolute path, directory exists)
  - Detects user's login shell instead of script interpreter
  - Refuses to modify symlinked RC files by default
  - `--allow-symlink` flag for managed dotfiles users
  - Comprehensive error messages for all failure modes

### Changed
- Secrets configured for `homebrew-intel-internal` GitHub App
- Builder workflow now supports cross-repository dispatch

### Technical Details

#### Commits
- `6dab230` - tap: enable core development tools
- `ee86af4` - builder: add --skip-unchanged to avoid redundant rebuilds  
- `c41c422` - ci: add auto-trigger for builder workflow
- `47a7d28` - docs: add Intel deprecation warning suppression
- `cc1a26a` - security: fix setup-intel.sh validation issues

#### Impact
- **Time savings:** ~20min per unnecessary build
- **Automation:** Full CI/CD from push to bottles
- **UX:** No more annoying deprecation warnings
- **Security:** Hardened setup script with proper validation

## [0.1.0] - 2026-10-23

### Added
- Initial tap structure
- `lz4` formula with Intel Sequoia bottle
- Build infrastructure (VM runner, builder workflows)
- Render and drift check scripts

[Unreleased]: https://github.com/homebrew-intel/homebrew-tap/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/homebrew-intel/homebrew-tap/releases/tag/v0.1.0
