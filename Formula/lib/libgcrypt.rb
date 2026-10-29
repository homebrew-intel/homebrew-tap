# Generated from Homebrew/homebrew-core@bee15277559640637059d39ec4a0ea534332440a by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/libgcrypt.patch.
class Libgcrypt < Formula
  desc "Cryptographic library based on the code from GnuPG"
  homepage "https://gnupg.org/related_software/libgcrypt/"
  url "https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.12.4.tar.bz2"
  sha256 "d77f68f48879510e79a2f65977ccc68981781ea0923e5bdffac2a193ea3d660e"
  license all_of: ["LGPL-2.1-or-later", "GPL-2.0-or-later"]
  compatibility_version 1

  livecheck do
    url "https://gnupg.org/ftp/gcrypt/libgcrypt/"
    regex(/href=.*?libgcrypt[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/libgcrypt-1.12.4"
    rebuild 1
    sha256 cellar: :any, sequoia: "d3d270439a32bf9bcc938110859e7ce715241ab5c6684c328e926dc8cdf60b91"
  end

  depends_on "macos-intel/tap/libgpg-error"

  def install
    system "./configure", "--disable-asm",
                          "--disable-silent-rules",
                          "--enable-static",
                          "--with-libgpg-error-prefix=#{formula_opt_prefix("libgpg-error")}",
                          *std_configure_args

    # The jitter entropy collector must be built without optimisations
    ENV.O0 { system "make", "-C", "random", "rndjent.o", "rndjent.lo" }

    # Parallel builds work, but only when run as separate steps
    system "make"
    system "make", "check"
    system "make", "install"

    # avoid triggering mandatory rebuilds of software that hard-codes this path
    inreplace bin/"libgcrypt-config", prefix, opt_prefix
  end

  test do
    touch "testing"
    output = shell_output("#{bin}/hmac256 \"testing\" testing")
    assert_match "0e824ce7c056c82ba63cc40cffa60d3195b5bb5feccc999a47724cc19211aef6", output
  end
end
