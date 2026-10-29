# Generated from Homebrew/homebrew-core@8701235251a995187352bd621a2f182a1127fa8c by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/pnpm.patch.
class Pnpm < Formula
  desc "Fast, disk space efficient package manager"
  homepage "https://pnpm.io/"
  url "https://github.com/pnpm/pnpm/archive/refs/tags/v12.16.1.tar.gz"
  sha256 "baaffdb2671a414882d13379d978339a58a9e66fe099f1f00f05a47b6232322c"
  license "MIT"
  compatibility_version 1
  head "https://github.com/pnpm/pnpm.git", branch: "main"

  livecheck do
    url "https://registry.npmjs.org/pnpm/latest"
    strategy :json do |json|
      json["version"]
    end
  end

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/pnpm-12.16.1"
    sha256 cellar: :any_skip_relocation, sequoia: "beaef08d7f16a47db3ece419beb34bb23766b6642b093cbf718ebbaa2aec6de1"
  end

  depends_on "macos-intel/tap/esbuild" => :build
  depends_on "macos-intel/tap/node" => :build
  depends_on "macos-intel/tap/rust" => :build

  conflicts_with "corepack", because: "both install `pnpm` and `pnpx` binaries"

  deny_network_access!

  def fetch
    rm ".cargo/config.toml"
    system "cargo", "fetch", *std_cargo_fetch_args
    cd "pnpm/esm-loader" do
      inreplace "package.json" do |s|
        s.gsub! '"enhanced-resolve": "catalog:"', '"enhanced-resolve": "5.26.0"'
        s.gsub! '"esbuild": "catalog:"', "\"esbuild\": \"#{Formula["macos-intel/tap/esbuild"].version}\""
      end
      system "npm", "install", "--workspaces=false", "--omit=optional",
                    *std_npm_args(prefix: false)
    end
  end

  def install
    ENV["ESBUILD_BINARY_PATH"] = formula_opt_bin("esbuild")/"esbuild"
    system "node", "pnpm/esm-loader/scripts/bundle-runtime.mjs"

    system "cargo", "install", *std_cargo_args(path: "pnpm/crates/cli")

    # Upstream ships these beside the binary as shell scripts rather than
    # symlinks: the `dlx` injection for `pnpx`/`pnx` matches on the name of
    # the resolved `current_exe`, which a symlink would report as `pnpm`.
    { "pn" => [], "pnpx" => ["dlx"], "pnx" => ["dlx"] }.each do |name, args|
      (bin/name).write_env_script opt_bin/"pnpm", *args, {}
    end

    generate_completions_from_executable(bin/"pnpm", "completion")
  end

  test do
    # `pnpm init` writes a `packageManager` pin naming this exact pnpm, and
    # every later invocation resolves that pin against the registry, so
    # anything that must run without network has to come first.
    assert_match version.to_s, shell_output("#{bin}/pn --version")

    system bin/"pnpm", "init"
    assert_path_exists testpath/"package.json", "package.json must exist"
  end
end
