# Generated from Homebrew/homebrew-core@f4781b7a0139d0850095188418ffb12682475cb8 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/xtrans.patch.
class Xtrans < Formula
  desc "X.Org: X Network Transport layer shared code"
  homepage "https://www.x.org/"
  url "https://xorg.freedesktop.org/archive/individual/lib/xtrans-1.6.0.tar.xz"
  sha256 "faafea166bf2451a173d9d593352940ec6404145c5d1da5c213423ce4d359e92"
  license "MIT"
  compatibility_version 1

  # bottle block: written by brew pr-pull

  depends_on "macos-intel/tap/pkgconf" => :build
  depends_on "macos-intel/tap/util-macros" => :build
  depends_on "macos-intel/tap/xorgproto" => :test

  def install
    args = %W[
      --sysconfdir=#{etc}
      --localstatedir=#{var}
      --disable-silent-rules
      --enable-docs=no
    ]

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include "X11/Xtrans/Xtrans.h"

      int main(int argc, char* argv[]) {
        Xtransaddr addr;
        return 0;
      }
    C
    system ENV.cc, "test.c"
    assert_equal 0, $CHILD_STATUS.exitstatus
  end
end
