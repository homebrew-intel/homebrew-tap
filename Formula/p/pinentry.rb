# Generated from Homebrew/homebrew-core@7913402d27bc6fb622ffe866bad75f810d0d3858 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/pinentry.patch.
class Pinentry < Formula
  desc "Passphrase entry dialog utilizing the Assuan protocol"
  homepage "https://www.gnupg.org/related_software/pinentry/"
  url "https://www.gnupg.org/ftp/gcrypt/pinentry/pinentry-1.3.3.tar.bz2"
  mirror "https://www.mirrorservice.org/sites/ftp.gnupg.org/gcrypt/pinentry/pinentry-1.3.3.tar.bz2"
  sha256 "c2970f16d6afb66ecddfca767d743936c86239bff936eed7fd7597a678414b63"
  license "GPL-2.0-or-later"
  compatibility_version 1

  livecheck do
    url "https://gnupg.org/ftp/gcrypt/pinentry/"
    regex(/href=.*?pinentry[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/pinentry-1.3.3"
    rebuild 2
    sha256 cellar: :any, sequoia: "aefcb9bf0cf9174823040add6aa970d6f633e805c5c7a5f3b35863bc6f29ecec"
  end

  depends_on "macos-intel/tap/pkgconf" => :build
  depends_on "macos-intel/tap/libassuan"
  depends_on "macos-intel/tap/libgpg-error"

  uses_from_macos "ncurses"

  on_linux do
    depends_on "libsecret"
    depends_on "macos-intel/tap/glib"
  end

  def install
    # Fix compile with newer Clang
    ENV.append_to_cflags "-Wno-implicit-function-declaration" if DevelopmentTools.clang_build_version >= 1403

    args = %w[
      --disable-silent-rules
      --disable-pinentry-fltk
      --disable-pinentry-gnome3
      --disable-pinentry-gtk2
      --disable-pinentry-qt
      --disable-pinentry-qt5
      --disable-pinentry-tqt
      --enable-pinentry-tty
    ]

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"pinentry", "--version"
    system bin/"pinentry-tty", "--version"
  end
end
