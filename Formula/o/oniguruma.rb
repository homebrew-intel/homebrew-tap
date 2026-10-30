# Generated from Homebrew/homebrew-core@34b9bceef03fee96aaa8ead8efc5c058ffe37de9 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/oniguruma.patch.
class Oniguruma < Formula
  desc "Regular expressions library"
  homepage "https://github.com/kkos/oniguruma/"
  url "https://github.com/kkos/oniguruma/releases/download/v6.9.10/onig-6.9.10.tar.gz"
  sha256 "2a5cfc5ae259e4e97f86b68dfffc152cdaffe94e2060b770cb827238d769fc05"
  license "BSD-2-Clause"
  compatibility_version 1
  head "https://github.com/kkos/oniguruma.git", branch: "master"

  livecheck do
    skip "No longer developed or maintained"
  end

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/oniguruma-6.9.10"
    rebuild 1
    sha256 cellar: :any, sequoia: "bb28ae71086b75e581028b5fda8914447c04b86be622bfdc0731e2397c40bd79"
  end

  depends_on "autoconf" => :build
  depends_on "libtool" => :build
  depends_on "macos-intel/tap/automake" => :build

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--disable-dependency-tracking", "--prefix=#{prefix}"
    system "make"
    system "make", "install"
  end

  test do
    assert_match(/#{prefix}/, shell_output("#{bin}/onig-config --prefix"))
  end
end
