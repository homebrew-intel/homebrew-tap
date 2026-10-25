# Generated from Homebrew/homebrew-core@f2fa4540ee4fc41c70a3c94df121528a11c17cb6 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/htop.patch.
class Htop < Formula
  desc "Improved top (interactive process viewer)"
  homepage "https://htop.dev/"
  url "https://github.com/htop-dev/htop/releases/download/3.5.3/htop-3.5.3.tar.xz"
  sha256 "a8b164386494cb85bb255a415a3f5f80afe7a0c4491da5d113b3a0f951087e65"
  license "GPL-2.0-or-later"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/homebrew-intel/homebrew-tap/releases/download/htop-3.5.3"
    rebuild 1
    sha256 cellar: :any, sequoia: "7def7a504c1cbf7d282130e63a72c33032d79809879aa7315d4ab4f3c9e5205f"
  end

  head do
    url "https://github.com/htop-dev/htop.git", branch: "main"

    depends_on "autoconf" => :build
    depends_on "homebrew-intel/tap/automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "homebrew-intel/tap/pkgconf" => :build
  depends_on "ncurses" # enables mouse scroll

  on_linux do
    depends_on "lm-sensors"
  end

  deny_network_access!

  def install
    system "./autogen.sh" if build.head?
    args = ["--prefix=#{prefix}"]
    args << "--enable-sensors" if OS.linux?
    system "./configure", *args
    system "make", "install"
  end

  def caveats
    <<~EOS
      htop requires root privileges to correctly display all running processes,
      so you will need to run `sudo htop`.
      You should be certain that you trust any software you grant root privileges.
    EOS
  end

  test do
    pipe_output(bin/"htop", "q", 0)
  end
end
