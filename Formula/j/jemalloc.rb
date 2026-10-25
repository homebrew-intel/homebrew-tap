# Generated from Homebrew/homebrew-core@e8ef0108242be8280a06fd3349f2d00563388f70 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/jemalloc.patch.
class Jemalloc < Formula
  desc "Implementation of malloc emphasizing fragmentation avoidance"
  homepage "https://jemalloc.net/"
  url "https://github.com/jemalloc/jemalloc/releases/download/5.4.0/jemalloc-5.4.0.tar.bz2"
  sha256 "200776fac271093e7c2f21edd6d62657ecd2be578d9328633f2a86bfa6ef4f1d"
  license "BSD-2-Clause"

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/jemalloc-5.4.0"
    rebuild 1
    sha256 cellar: :any, sequoia: "a99afffc42c17b600970c2a1c2381f84c0343b2e409818d21576b70b41aa65cb"
  end

  head do
    url "https://github.com/jemalloc/jemalloc.git", branch: "dev"

    depends_on "autoconf" => :build
    depends_on "docbook-xsl" => :build
  end

  def install
    args = %W[
      --disable-debug
      --prefix=#{prefix}
      --with-jemalloc-prefix=
    ]
    args << "--with-lg-page=16" if Hardware::CPU.arm64? && OS.linux?

    if build.head?
      args << "--with-xslroot=#{formula_opt_prefix("docbook-xsl")}/docbook-xsl"
      system "./autogen.sh", *args
      system "make", "dist"
    else
      system "./configure", *args
    end

    system "make"
    # Do not run checks with Xcode 15, they fail because of
    # overly eager optimization in the new compiler:
    # https://github.com/jemalloc/jemalloc/issues/2540
    # Reported to Apple as FB13209585
    system "make", "check" if DevelopmentTools.clang_build_version < 1500
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdlib.h>
      #include <jemalloc/jemalloc.h>

      int main(void) {

        for (size_t i = 0; i < 1000; i++) {
            // Leak some memory
            malloc(i * 100);
        }

        // Dump allocator statistics to stderr
        malloc_stats_print(NULL, NULL, NULL);
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-ljemalloc", "-o", "test"
    system "./test"
  end
end
