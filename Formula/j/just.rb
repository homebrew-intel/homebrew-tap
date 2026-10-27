# Generated from Homebrew/homebrew-core@95d9ee8feaa6d110f0f98cd761d2102a69b83ce2 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/just.patch.
class Just < Formula
  desc "Handy way to save and run project-specific commands"
  homepage "https://just.systems"
  url "https://github.com/casey/just/archive/refs/tags/1.59.0.tar.gz"
  sha256 "20f876880851f1cc67fc7eb7589c7f7ccaa7612d827feac75797cf4a6ed729aa"
  license "CC0-1.0"
  head "https://github.com/casey/just.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/just-1.59.0"
    rebuild 2
    sha256 cellar: :any_skip_relocation, sequoia: "01af920a2d9fc37492bb51e3229089bc2be44a9665c99e5c7f6a74a6d8cb97f5"
  end

  depends_on "macos-intel/tap/rust" => :build

  deny_network_access!

  def fetch
    system "cargo", "fetch", *std_cargo_fetch_args
  end

  def install
    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"just", shell_parameter_format: "--completions=")
    (man1/"just.1").write Utils.safe_popen_read(bin/"just", "--man")
  end

  test do
    (testpath/"justfile").write <<~MAKE
      default:
        touch it-worked
    MAKE
    system bin/"just"
    assert_path_exists testpath/"it-worked"

    assert_match version.to_s, shell_output("#{bin}/just --version")
  end
end
