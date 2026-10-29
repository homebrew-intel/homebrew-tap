# Generated from Homebrew/homebrew-core@bee15277559640637059d39ec4a0ea534332440a by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/libassuan.patch.
class Libassuan < Formula
  desc "Assuan IPC Library"
  homepage "https://www.gnupg.org/related_software/libassuan/"
  url "https://gnupg.org/ftp/gcrypt/libassuan/libassuan-3.0.2.tar.bz2"
  mirror "https://www.mirrorservice.org/sites/ftp.gnupg.org/gcrypt/libassuan/libassuan-3.0.2.tar.bz2"
  sha256 "d2931cdad266e633510f9970e1a2f346055e351bb19f9b78912475b8074c36f6"
  license all_of: [
    "LGPL-2.1-or-later",
    "GPL-3.0-or-later", # assuan.info
    "FSFULLR", # libassuan-config, libassuan.m4
  ]
  compatibility_version 1

  livecheck do
    url "https://gnupg.org/ftp/gcrypt/libassuan/"
    regex(/href=.*?libassuan[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/libassuan-3.0.2"
    rebuild 1
    sha256 cellar: :any, sequoia: "2b8371b9d12be336b5d23d8c1b68f553f14b7a331c65e5415b1ab88e583ffe14"
  end

  depends_on "macos-intel/tap/libgpg-error"

  def install
    system "./configure", "--disable-silent-rules",
                          "--enable-static",
                          *std_configure_args
    system "make", "install"

    # avoid triggering mandatory rebuilds of software that hard-codes this path
    inreplace bin/"libassuan-config", prefix, opt_prefix
  end

  test do
    system bin/"libassuan-config", "--version"
  end
end
