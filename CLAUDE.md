# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Purpose

A Homebrew tap (`brew tap macos-intel/tap`) that keeps macOS Intel
(x86_64) usable after homebrew-core dropped it. Intel macOS is Tier 3 in core:
no new Intel bottles, and Homebrew plans to stop running on Intel in or after
September 2027 (see `$(brew --repo)/docs/Support-Tiers.md`).

The tap carries:

- formulae homebrew-core removed, disabled, or gated with
  `depends_on arch: :arm64` that still build on Intel
- Intel bottles for current core formulae that no longer get them

Target: Intel macOS Sequoia 15 and Tahoe 26 (bottles are built on Sequoia).
Design: `docs/superpowers/specs/2026-10-21-intel-bottles-design.md`.

## Conventions

- Formulae in `Formula/<shard>/<name>.rb` (`<shard>` is the first letter;
  `lib*` names go to `Formula/lib/`) are **generated** from homebrew-core by
  `scripts/tap/render.py` (`mise run render`). Never hand-edit a Formula file
  or its `bottle do` block. The render leaves a permanent two-space-indented
  marker line `# bottle block: written by brew pr-pull`. `brew pr-pull`
  inserts the bottle block after `livecheck`/`head`, and the next render moves
  it right after the marker line. Drift ignores the block either way.
- Each rendered file starts with a two-line header naming the core commit it
  came from. The drift check re-renders from that commit.
- Enabling a formula means adding an entry to `enabled.toml`
  (`kind = "generated"`, or `kind = "patched"` plus a 40-character `base`
  core commit), then running `mise run render`.
- A render with one `--core-commit` rewrites every header: keep new files
  and real changes, revert header-only diffs (they force rebuilds). To change
  existing formulae without a version bump, render each at its own header
  commit.
- The render also writes the enabled closure (`scripts/tap/closure.py`):
  every dependency without an Intel bottle that a tap formula needs. Runtime
  dependencies are followed through bottled formulae too; build and test
  dependencies only of tap formulae, since the builder's clean host builds
  none of them itself (cmake joins for lz4). A core formula anywhere in
  the tree brew locks (every dependency type, at any depth) that depends
  on a tap formula joins too: its bare name would bring core's copy next
  to the tap's, and brew locks both by one rack name (zstd for xz,
  libpsl for pkgconf).
  The plan builds each one first.
- A patched formula (core removed, disabled or arm64-gated it, or it fails on
  Intel): edit the rendered file, then run
  `mise run render -- --make-patch <name>` to write `patches/<name>.patch`.
  Until the patch exists, render writes the formula unpatched from `base` and
  prints a notice. Commit the patch and the render. A patch may only remove
  Intel gates, revive a removed formula, or fix an Intel build failure.
- Same name as core. Users must install fully qualified
  (`brew install macos-intel/tap/<name>`), or core's version wins. Say
  so in README and caveats; never rename to dodge the collision.
- Dependencies that are also in this tap are rewritten to
  `macos-intel/tap/<dep>` by the render; the rest stay plain names.
- Casks are out of scope.
- `style_exceptions/*.json` copies entries from core's lists of the same
  name for tap formulae that need them (e.g. `coreutils` uses
  `ENV.runtime_cpu_detection`); `brew style` only honours them for files
  inside a tap. The render re-sorts `depends_on` runs after qualifying, so
  `FormulaAudit/DependencyOrder` holds, and drops `no_autobump!`, which brew
  only loads from official taps.
- Core formulae test dependency names bare (`deps.map(&:name)`,
  `dep.name.start_with?`), which tap-qualified names would silently fail
  (llvm builds without z3). The render inserts
  `.delete_prefix("macos-intel/tap/")` there; names passed to
  `formula_opt_prefix` may stay qualified, brew strips the tap.
- `Aliases/` is generated too: the render mirrors every core alias of a tap
  formula, read at that formula's header commit, as a relative symlink, and
  removes stale ones; drift checks them. brew creates an `opt/<alias>` link
  only from an alias recorded at install: superenv's `pkg-config` shim runs
  `opt/pkg-config/bin/pkg-config`, and ruby's `post_install` and test use
  `opt/ruby@4.0`.
- `core-patches/` holds copies of core's `Patches/` files that tap formulae
  use (`patch do file "Patches/..."`), which brew resolves against the tap's
  root. The render rewrites the path and copies each file from core at the
  formula's header commit; drift checks the copies. Bot pull requests only
  commit `Formula/`, so if core changes such a file, re-render by hand.
- `scripts/setup-intel.sh` is user-facing: it appends
  `export HOMEBREW_DEVELOPER=1` to the user's shell RC file, the only
  setting Homebrew checks before its Intel Tier 3 warning. Keep its
  confirmation prompt and checks (absolute `$HOME`, known shell, no writes
  through a symlinked RC unless `--allow-symlink`).

## Verification

Before any commit that touches a formula or `enabled.toml`:

Render reads `.cache/api/formula.json`: run `scripts/audit/fetch-api.sh`
first when it is missing or stale. It needs Python 3.11+ (pinned via mise).

```bash
mise run render
mise run drift
mise run lint
mise run test
brew style macos-intel/tap/<name>
brew audit --strict --online --tap=macos-intel/tap
brew install --build-from-source macos-intel/tap/<name>
brew test macos-intel/tap/<name>
```

- `mise run drift` must pass.
- The local machine is Intel (`/usr/local` prefix). Bottles must be built
  under `/usr/local`, or relocation breaks them.
- The tap is symlinked to this checkout, so `brew style
  macos-intel/tap` also scans the gitignored `actions-runner/` and
  reports hundreds of unrelated offenses. Locally, run `brew style` on
  specific formulae (`brew style macos-intel/tap/<name>`); CI
  checkouts do not have that directory.
- From a worktree, link it as a throwaway tap
  (`ln -s "$PWD" "$(brew --repo)/Library/Taps/macos-intel-tmp/homebrew-x"`),
  run `brew style macos-intel-tmp/x/<name>`, then remove the link.
- `brew audit` errors inherited from core are accepted. For example, lz4
  reports an HTTP-mirror error that core's lz4 also has.

## Audit

`scripts/audit/run.sh` (`SKIP_FETCH=1` reuses `.cache/api`, `VERBOSE=1`)
rebuilds `reports/` from a fresh API snapshot plus local git history, taps and
`~/Brewfile`. Scripts are stdlib Python. Lint with `ruff check scripts/audit`
(config in `ruff.toml`) and `shellcheck`.

- `reports/brewfile.*` stay gitignored. They list the owner's packages, and
  this repo is public.
- Always compare Intel and ARM data from the same `fetch-api.sh` run. Mixing
  in brew's own `~/Library/Caches/Homebrew/api` produced fake "Intel-pinned"
  versions.
- Run the scripts with plain `python3`, not `python3 -I`, which drops the
  script directory from `sys.path` and breaks `import brew_api`.

## CI and bottles

- Public CI (`.github/workflows/ci.yml`) runs on hosted runners only:
  `lint-and-test`, `tap-syntax` and `drift` on Ubuntu, and `pour-test` on
  `macos-15-intel`. Never run a job from this repository on the iMac.
  `pour-test` skips `brew test` (keeping `brew linkage --test`) only for
  formulae in `scripts/ci/hosted-test-skip.txt`, whose tests need hardware
  the hosted runner lacks (highway: RDTSCP); the builder still tests them.
- `trigger-builder` (`.github/workflows/trigger-builder.yml`) runs when a
  pull request that changes `Formula/` is merged, so its result shows on that
  pull request, and dispatches `build.yml` for the changed formulae with a
  token from the `homebrew-intel-internal` App (`INTERNAL_APP_CLIENT_ID`
  variable, `INTERNAL_APP_PRIVATE_KEY` secret, `actions: write` on
  `builder` only). It skips the builder's own bottle pull requests: those
  only add bottle blocks, and dispatching them would rebuild endlessly.
  It also skips pull requests labelled `skip-build`, for changes that
  leave every bottle valid (the macos-intel rename rewrote tap names and
  `root_url` only).
- `verify-bot-pr` (`.github/workflows/verify-bot-pr.yml`) is the auto-merge
  gate. It runs on `pull_request_target`, so the base branch's workflow and
  `scripts/ci/verify_bot_pr.py` judge every pull request; it must never check
  out or run pull request code. Human pull requests pass as skipped and need
  the owner to merge, unless their head commit carries a `bottle-builder`
  check run or is the head of another open same-repository `bottle/*` pull
  request: checks belong to a commit, so a skip there would turn the gate
  green for the bot's pull request too, and such a pull request fails. A
  pull request by `homebrew-intel[bot]` passes only
  when it comes from a same-repository `bottle/<date>-<n>` branch into
  `main`, only touches `Formula/`, its commit and file counts match the
  event (below the API listing limits), its commits are verified bot commits,
  and its head carries a successful `bottle-builder` check run from the
  `homebrew-intel` App whose `head_sha` and `external_id` are that head.
  That check run is the trust anchor; any later push to the branch removes
  it and auto-merge waits.
- The only GitHub-hosted Intel runner is `macos-15-intel`. It is the last
  Intel image and is expected to retire around August 2027. Don't add hosted
  labels such as `macos-13` (retired) or `macos-26-intel` (doesn't exist).
- Bottles are built by the private builder
  `macos-intel/builder`, which writes the bottle blocks
  with `brew bottle --merge --write` and publishes them through a bot pull
  request (not `brew pr-pull`). Only Sequoia bottles are built; they also
  pour on Tahoe.
- The plan (`scripts/tap/plan.py`) builds a formula only when forced or
  stale (no bottle block for its current `pkg_version`), never because a
  tap dependency was rebuilt: as in core, a dependent that needs a rebuild
  gets a `revision` bump, which makes it stale.
- The self-hosted runner `macos-intel-sequoia` (label `sequoia`) runs in
  the VMware Fusion VM `macos-intel-sequoia-builder` on the owner's iMac Pro,
  as the VM's own `runner` user, never on the host. Safeguards: never
  `brew test-bot --cleanup`, `brew cleanup` or `brew autoremove`; set
  `HOMEBREW_NO_AUTO_UPDATE=1` and `HOMEBREW_NO_INSTALL_CLEANUP=1`; one run at
  a time.
- No secret ever reaches the build host: formula code runs there as the
  runner's user and can read any ancestor's environment. Its `build.yml` has
  five jobs:
  - `prepare` (hosted): resolves `main` and homebrew-core's `HEAD` to one
    commit each; every other job checks out exactly that tap commit, never a
    ref named by the host or its artifact.
  - `build` (self-hosted, no token): `scripts/builder/run.sh --build-only
    --core-commit <prepare's core commit>` renders at that commit (logging
    any difference from the API snapshot's), plans, builds and bottles, and
    uploads `.builder/out` (manifest,
    bottles, rendered formulae, logs) as the `builder-out` artifact. It and
    `pour.sh` refuse to start when a GitHub token is in the environment.
  - `verify` (hosted, `actions: read` only): the trust boundary,
    `scripts/builder/verify_artifact.py`. It lists the run's artifacts, binds
    the run to its single `builder-out` by id and digest
    (`scripts/ci/builder_artifact.py`; publish and pour download that id and
    re-check that digest) and computes the enabled closure itself
    (`fetch-api.sh` plus `render.py --print-order`). The manifest's tap and
    core commits must be prepare's (each core commit also on homebrew-core's
    HEAD, `scripts/ci/fetch-core.sh`), and every formula must be in the
    closure and be, bottle block aside, exactly its core render with the
    closure as tap names, and every bottle block must parse as only the lines
    brew writes, before any formula is evaluated. It never uses
    `setup-homebrew` (which wipes the workspace of `homebrew-*` repositories)
    but the image's Homebrew with every token unset.
    `scripts/builder/derive-versions.sh` then reads each version with
    `brew info` from the trusted renders (never an artifact file, with no
    token in reach), and the full check requires the manifest's versions,
    root URLs, release tags, asset names, sha256 values and file names to
    agree with it; a render-only formula keeps main's bottle block only while
    its release tag is the derived version's.
  - `publish` (hosted): repeats the pure check with verify's closure, mints
    the App token only then, and runs `scripts/builder/publish.sh`: it
    uploads each bottle to the release `<name>-<pkg_version>` (never
    `--clobber`: an existing asset is kept only when its digest is the
    tarball's, else the formula is refused), commits each formula to
    `bottle/<date>-<run-number>`, a branch created at the verified tap commit,
    as a verified bot commit (render-only formulae first), attests the last
    commit with the `bottle-builder` check run, opens one pull request and one
    private issue per failed build (a fenced log tail with `@` neutralised).
  - `pour` (self-hosted, no token): swaps each `--build-bottle` keg for a
    pour of its released bottle, since such a keg would rebuild from source
    on `reinstall`/`upgrade`, never ran its `post_install` (openssl's
    `cert.pem`), and `brew reinstall` keeps it `--build-bottle`. It runs
    whenever `verify` passed and `publish` ran, including a `publish` that
    failed some formulae.
- Two Apps, never merged: `homebrew-intel` (the public bot: Contents, Pull
  requests and Checks set to Read and write on `homebrew-tap`) and
  `homebrew-intel-internal` (only dispatches builds). Before rebuilding after
  a run that uploaded bottles but opened no merged pull request, delete
  those release assets (no formula references them, a rebuild reuses their
  names, and publish refuses a different digest).
- No hosted job of the builder (`prepare`, `verify`, `publish`) or
  `verify-bot-pr` restores a cache (`actions/cache`, a `setup-*` cache,
  `jdx/mise-action`): any job can write cache entries, so a restore would run
  code the trusted job did not check out. They use the image's tools.
- What auto-merges: only the builder's own pull request, and only when
  `open-pr.sh` finds the branch head is the run's last commit, main's ruleset
  requires `verify-bot-pr` from GitHub Actions (integration id 15368), and
  then with `--match-head-commit` bound to that
  head. It merges after the five required checks (`lint-and-test`,
  `tap-syntax`, `drift`, `pour-test`, `verify-bot-pr`). Each commit chains on
  the run's previous one, so a commit pushed by anyone else is never built
  upon; then the run attests nothing, leaves the pull request to the owner
  and fails. Re-running the same workflow run fails at its first commit
  because its branch already exists; dispatch a new run instead.
- Never merge a pull request that changes `.github/workflows/` while a
  builder run is between `prepare` and `publish`: `publish` creates its
  branch at `prepare`'s commit, and with different workflow files on `main`
  GitHub refuses that ref to an App without the `workflows` permission
  (HTTP 403 on `git/refs`), leaving an orphan release to delete.
- Dispatch a build with `gh workflow run build.yml -R
  macos-intel/builder -f formulae=<name>` (add
  `-f dry-run=true` to only print the plan).
- Never cancel a run while it builds or pours: the old keg is uninstalled
  first and restored on failure. If a restore cannot finish, the keg's full
  name stays in `~/Library/Caches/homebrew-intel-builder/pending-restore`
  (`$BUILDER_CACHE`); the next build or pour reinstalls it, and no keg swap
  starts until it is back.
- `brew test` runs with every linked keg that is not the formula or one of
  its runtime or test dependencies unlinked, as on core's clean CI hosts
  (docker's test failed while docker-compose's CLI plugin was linked). The
  unlinked names wait in `pending-relink` until they are linked back; the
  next build or pour relinks them first.
- Never hand-edit `bottle do` blocks; the builder writes them.

## Shell environment

- The owner's shell is zsh: unquoted `$var` does not word-split; use arrays,
  `xargs` or `bash -c`.
- `sed` on the owner's Mac is GNU: `sed -i` takes no `''` argument.
- Non-interactive ssh or nohup on the builder VM lacks `/usr/local/bin`;
  export `PATH` first.

## Git

- Commits are GPG-signed (`git commit -S`) and never carry
  `Co-Authored-By` trailers.
- Commit subjects follow homebrew-core style: `<name> <version> (new formula)`,
  `<name>: <change>`.
