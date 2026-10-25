# Generated from Homebrew/homebrew-core@28354f466a6bfb34a765128ea13379087fc243e1 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/wget.patch.
class Wget < Formula
  desc "Internet file retriever"
  homepage "https://www.gnu.org/software/wget/"
  license "GPL-3.0-or-later"
  revision 2
  compatibility_version 1

  stable do
    url "https://ftpmirror.gnu.org/wget/wget-1.25.0.tar.gz"
    mirror "https://ftp.gnu.org/gnu/wget/wget-1.25.0.tar.gz"
    sha256 "766e48423e79359ea31e41db9e5c289675947a7fcf2efdcedb726ac9d0da3784"

    # Backport support for OpenSSL 4
    patch do
      url "https://gitlab.com/gnuwget/wget/-/commit/aaec8d52a06c46eeab570b8ef3e10760ebc66b7a.diff"
      sha256 "96aa2923ce9a12dbc2c82969705da4f72792816b087dbee19c04cd2cb2769ea8"
      type :backport
    end
  end

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/wget-1.25.0_2"
    rebuild 1
    sha256 sequoia: "7c02c5506c2c33967bc7dd9d2e3285651bd4fbe5f973a89f33d7a1aaefedf8b6"
  end

  head do
    url "https://git.savannah.gnu.org/git/wget.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "macos-intel/tap/automake" => :build
    depends_on "macos-intel/tap/xz" => :build
  end

  depends_on "macos-intel/tap/pkgconf" => :build
  depends_on "macos-intel/tap/libidn2"
  depends_on "macos-intel/tap/libpsl"
  depends_on "macos-intel/tap/openssl@4"

  on_macos do
    depends_on "macos-intel/tap/gettext"
    depends_on "macos-intel/tap/libunistring"
  end

  on_linux do
    depends_on "util-linux"
    depends_on "zlib-ng-compat"
  end

  # Test downloads from the network
  allow_network_access! :test

  def install
    system "./bootstrap", "--skip-po" if build.head?
    system "./configure", "--sysconfdir=#{etc}",
                          "--with-ssl=openssl",
                          "--with-libssl-prefix=#{formula_opt_prefix("openssl@4")}",
                          "--disable-pcre",
                          "--disable-pcre2",
                          "--with-libpsl",
                          "--without-included-regex",
                          *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"wget", "-O", File::NULL, "https://google.com"

    # Verify PSL support is built in via libpsl
    assert_match "+psl", shell_output("#{bin}/wget --version")
  end
end
