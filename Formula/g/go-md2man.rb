# Generated from Homebrew/homebrew-core@9b494b0a09aef39f7448227aa83aa2c13fd8d52e by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/go-md2man.patch.
class GoMd2man < Formula
  desc "Converts markdown into roff (man pages)"
  homepage "https://github.com/cpuguy83/go-md2man"
  url "https://github.com/cpuguy83/go-md2man/archive/refs/tags/v2.0.7.tar.gz"
  sha256 "ca3a5b57e2c01759f5a00ad2a578d034c5370fae9aa7a6c3af5648b2fc802a92"
  license "MIT"
  head "https://github.com/cpuguy83/go-md2man.git", branch: "master"

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/go-md2man-2.0.7"
    rebuild 1
    sha256 cellar: :any_skip_relocation, sequoia: "eb08fa54da84acccb1ce0772c1a624214fc31c5141316e51c4f3c1b2599d76ba"
  end

  depends_on "macos-intel/tap/go" => :build

  deny_network_access!

  def fetch
    system "go", "mod", "download"
  end

  def install
    system "go", "build", *std_go_args
    system bin/"go-md2man", "-in=go-md2man.1.md", "-out=go-md2man.1"
    man1.install "go-md2man.1"
  end

  test do
    assert_includes pipe_output(bin/"go-md2man", "# manpage\nand a half\n"),
                    ".TH manpage\nand a half\n"
  end
end
