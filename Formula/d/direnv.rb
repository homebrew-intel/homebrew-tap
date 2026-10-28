# Generated from Homebrew/homebrew-core@cfadc8c8d402d66cc7175918b34bea5c4d0ffa47 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/direnv.patch.
class Direnv < Formula
  desc "Load/unload environment variables based on $PWD"
  homepage "https://direnv.net/"
  url "https://github.com/direnv/direnv/archive/refs/tags/v2.38.2.tar.gz"
  sha256 "02c5e873e9ebcf2798513f7dd3775e5b8aace99bfa1e0c1b93091b6d4cbcaffb"
  license "MIT"

  # bottle block: written by brew pr-pull

  head do
    url "https://github.com/direnv/direnv.git", branch: "master"

    depends_on "macos-intel/tap/go-md2man" => :build
  end

  depends_on "macos-intel/tap/go" => :build
  depends_on "macos-intel/tap/bash"

  deny_network_access!

  def fetch
    system "go", "mod", "download"
  end

  def install
    ENV["CGO_ENABLED"] = OS.mac? ? "1" : "0"
    system "make", "install", "PREFIX=#{prefix}", "BASH_PATH=#{formula_opt_bin("bash")}/bash"
  end

  test do
    assert_match "No .envrc or .env found", shell_output("#{bin}/direnv status")

    ENV["TEST"] = "failed"
    (testpath/".envrc").write "export TEST=passed"

    assert_match "No .envrc or .env loaded", shell_output("#{bin}/direnv status")
    system bin/"direnv", "allow"

    assert_match "passed", shell_output("#{bin}/direnv exec . sh -c 'echo $TEST'")
  end
end
