# Generated from Homebrew/homebrew-core@f4781b7a0139d0850095188418ffb12682475cb8 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/rumdl.patch.
class Rumdl < Formula
  desc "Markdown Linter and Formatter written in Rust"
  homepage "https://github.com/rvben/rumdl"
  url "https://github.com/rvben/rumdl/archive/refs/tags/v0.3.2.tar.gz"
  sha256 "f398b2697bfdf5caed0a3852831771c4b56199e20c034b165af49502acc659dd"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  # bottle block: written by brew pr-pull

  depends_on "macos-intel/tap/rust" => :build

  deny_network_access!

  def fetch
    system "cargo", "fetch", *std_cargo_fetch_args
  end

  def install
    system "cargo", "install", *std_cargo_args
    generate_completions_from_executable(bin/"rumdl", "completions")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/rumdl version")

    (testpath/"test-bad.md").write <<~MARKDOWN
      # Header 1
      body
    MARKDOWN
    (testpath/"test-good.md").write <<~MARKDOWN
      # Header 1

      body
    MARKDOWN

    assert_match "Success", shell_output("#{bin}/rumdl check test-good.md")
    assert_match "MD022", shell_output("#{bin}/rumdl check test-bad.md 2>&1", 1)
    assert_match "Fixed", shell_output("#{bin}/rumdl fmt test-bad.md")
    assert_equal (testpath/"test-good.md").read, (testpath/"test-bad.md").read
  end
end
