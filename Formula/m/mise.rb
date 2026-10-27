# Generated from Homebrew/homebrew-core@3045cd43ecd48db75bd7d8577cd73a85b3f65b1f by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/mise.patch.
class Mise < Formula
  desc "Polyglot runtime manager (asdf rust clone)"
  homepage "https://mise.jdx.dev/"
  url "https://github.com/jdx/mise/archive/refs/tags/v2026.10.19.tar.gz"
  sha256 "01e180b643c462180a408f8715f52e57bebea206881650ab3f3f93e6e09ef4a1"
  license "MIT"
  head "https://github.com/jdx/mise.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/mise-2026.10.19"
    rebuild 1
    sha256 cellar: :any_skip_relocation, sequoia: "6ab020dc0062ad81dab3e467d20c9afde2883711cf22f3f9750969d8a5a2361a"
  end

  depends_on "macos-intel/tap/cmake" => :build
  depends_on "macos-intel/tap/llvm" => :build
  depends_on "macos-intel/tap/pkgconf" => :build
  depends_on "macos-intel/tap/rust" => :build

  uses_from_macos "bzip2"

  on_linux do
    depends_on "macos-intel/tap/openssl@4"
  end

  # downloads crates during install and binaries in the test
  deny_network_access! :postinstall

  def install
    # Ensure that the `openssl` crate picks up the intended library.
    ENV["OPENSSL_DIR"] = formula_opt_prefix("openssl@4") if OS.linux?

    system "cargo", "install", *std_cargo_args
    man1.install "man/man1/mise.1"
    lib.mkpath
    touch lib/".disable-self-update"
    (share/"fish/vendor_conf.d/mise-activate.fish").write <<~FISH
      if [ "$MISE_FISH_AUTO_ACTIVATE" != "0" ]
        #{opt_bin}/mise activate fish | source
      end
    FISH

    # Untrusted config path problem, `generate_completions_from_executable` is not usable
    bash_completion.install "completions/mise.bash" => "mise"
    fish_completion.install "completions/mise.fish"
    zsh_completion.install "completions/_mise"
  end

  def caveats
    <<~EOS
      If you are using fish shell, mise will be activated for you automatically.
    EOS
  end

  test do
    system bin/"mise", "settings", "set", "experimental", "true"
    system bin/"mise", "use", "go@1.23"
    assert_match "1.23", shell_output("#{bin}/mise exec -- go version")
  end
end
