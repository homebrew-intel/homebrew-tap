# Generated from Homebrew/homebrew-core@9b494b0a09aef39f7448227aa83aa2c13fd8d52e by scripts/tap/render.py; do not edit.
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
