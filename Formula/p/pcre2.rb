# Generated from Homebrew/homebrew-core@f71148290f0a0204a502ea61c6a03265c703c86a by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/pcre2.patch.
class Pcre2 < Formula
  desc "Perl compatible regular expressions library with a new API"
  homepage "https://www.pcre.org/"
  url "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.49/pcre2-10.49.tar.bz2"
  sha256 "53c156e1ba416a20da8e65395daa132da0d80e76910424caca3fcdae7831d384"
  license "BSD-3-Clause"
  compatibility_version 1

  livecheck do
    url :stable
    regex(/^pcre2[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://github.com/homebrew-intel/homebrew-tap/releases/download/pcre2-10.49"
    rebuild 1
    sha256 cellar: :any, sequoia: "0e0e440f87698704bad2bc60207bea2bdd2963971bf24ccc09a73d89f8128b11"
  end

  # bottle block: written by brew pr-pull

  head do
    url "https://github.com/PCRE2Project/pcre2.git", branch: "main"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  uses_from_macos "bzip2"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  deny_network_access!

  def install
    args = %w[
      --enable-pcre2-16
      --enable-pcre2-32
      --enable-pcre2grep-libz
      --enable-pcre2grep-libbz2
      --enable-jit
    ]

    args << "--enable-pcre2test-libedit" if OS.mac?

    system "./autogen.sh" if build.head?

    system "./configure", *args, *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    system bin/"pcre2grep", "regular expression", prefix/"README"
  end
end
