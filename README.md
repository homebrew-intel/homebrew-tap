# macos-intel/tap

<!-- Inline HTML because Markdown's image syntax cannot set a width. The path
     is relative, so the logo also renders on branches and pull requests. -->
<p align="center">
  <img src="img/homebrew-intel.svg"
    alt="macos-intel logo: a beer mug with the Intel logo in its foam"
    width="300">
</p>

A Homebrew tap that keeps Intel (x86_64) Macs usable after homebrew-core
dropped them. Intel macOS is Tier 3 in Homebrew: no new Intel bottles are
published, and Homebrew plans to stop running on Intel in or after September
2027. This project ends then, unless a separate decision extends it.
It is not affiliated with or endorsed by Homebrew.

The tap carries Intel `sequoia` bottles for an explicit, growing list of core
formulae, so you pour them instead of compiling. A Sequoia bottle also pours
on Tahoe. It can also carry formulae that core removed, disabled or restricted
to arm64 when the software still works on Intel; those have a small reviewed
patch.

**Status:** bottles are being published. `lz4` and `cmake` ship Intel
Sequoia bottles; the other formulae (`gh`, `git`, `openssl@3`, `pkgconf` and
their dependencies) build from source until theirs is published. A keg you
built from source with `--build-bottle` keeps building on `reinstall`, so
switch it with `brew uninstall` and then `brew install`.

Formulae in `Formula/` are generated from homebrew-core and must not be edited
by hand. See `CLAUDE.md` for the workflow.

## Recent Improvements

**October 24, 2026:**

- 🚀 **11 formulae enabled** (up from 1): `cmake`, `gh`, `git`,
  `openssl@3`, `pkgconf`, and their dependencies
- ⚡ **Auto-trigger builds**: a change to `Formula/` on `main` starts a bottle
  build
- 🔇 **About the Intel warning**: what it means and how to hide it
  ([see below](#the-intel-deprecation-warning))

See [CHANGELOG.md](CHANGELOG.md) for complete details.

## Using the tap

Formulae here have the same names as core. Install them **fully qualified**,
for example `macos-intel/tap/cmake`. A bare name installs core's
version.

```bash
brew tap macos-intel/tap
brew trust macos-intel/tap
brew reinstall macos-intel/tap/cmake   # switches an installed core keg
```

Switching an installed core formula to the tap needs its tap dependencies
switched first: run `brew reinstall macos-intel/tap/<dep>` in
dependency order, because `brew install` refuses a name installed from
another tap.

In a Brewfile:

```ruby
tap "macos-intel/tap", trusted: true
brew "macos-intel/tap/cmake"
```

### Moving from `homebrew-intel/tap`

The organization was renamed from `homebrew-intel` to `macos-intel`, so the
tap is now `macos-intel/tap`. Kegs installed under the old name keep it in
their receipt. Tap the new name, reinstall each of them from it (dependencies
first), then remove the old tap:

```bash
brew tap macos-intel/tap
brew trust macos-intel/tap
brew list --full-name | grep '^homebrew-intel/tap/'   # what the old name installed
brew reinstall macos-intel/tap/<name>
brew untap homebrew-intel/tap
```

In a Brewfile, change `tap "homebrew-intel/tap"` and every
`homebrew-intel/tap/` prefix to `macos-intel/tap`.

Once installed, a formula follows the tap. When core bumps it, you stay on the
tap's last published version until the new bottle is published (expected lag:
one day plus build time).

## The Intel deprecation warning

On Intel, `brew install` and `brew doctor` warn that macOS on Intel x86_64 is
a Tier 3 configuration. The warning is expected when you use this tap, and it
does not stop anything from installing.

Homebrew has no setting that hides only this warning. It is skipped when
`HOMEBREW_DEVELOPER=1` is set, but that variable also changes how Homebrew
updates and adds developer checks, so only set it if you accept that.
`HOMEBREW_NO_ENV_HINTS=1` hides Homebrew's environment hints, not this
warning.

To add it to your shell config, run the setup script. It explains the trade-off
and asks before changing anything:

```bash
./scripts/setup-intel.sh
```

## Requirements

- Intel macOS with Homebrew in `/usr/local`. Bottles are built there.
- Sequoia 15 or Tahoe 26.

## License

BSD 2-Clause, the same as Homebrew; see [LICENSE.txt](LICENSE.txt). Formulae
are derived from homebrew-core, so its copyright notice is kept. Each formula's
`license` field still describes the upstream software it installs.
