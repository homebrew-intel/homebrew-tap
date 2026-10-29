# Generated from Homebrew/homebrew-core@bee15277559640637059d39ec4a0ea534332440a by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/gnu-tar.patch.
class GnuTar < Formula
  desc "GNU version of the tar archiving utility"
  homepage "https://www.gnu.org/software/tar/"
  url "https://ftpmirror.gnu.org/tar/tar-1.35.tar.gz"
  mirror "https://ftp.gnu.org/gnu/tar/tar-1.35.tar.gz"
  sha256 "14d55e32063ea9526e057fbf35fcabd53378e769787eff7919c3755b02d2b57e"
  license "GPL-3.0-or-later"
  revision 1
  compatibility_version 1

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/gnu-tar-1.35_1"
    rebuild 1
    sha256 cellar: :any_skip_relocation, sequoia: "b458d5928978d9545d86cb6126e346ba7a90f554d5e2cd160a7397f34250a1c9"
  end

  head do
    url "https://git.savannah.gnu.org/git/tar.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "macos-intel/tap/automake" => :build
    depends_on "macos-intel/tap/gettext" => :build
  end

  on_linux do
    depends_on "acl"
  end

  deny_network_access!

  def install
    args = %W[
      --prefix=#{prefix}
      --mandir=#{man}
      --disable-nls
    ]

    args << if OS.mac?
      "--program-prefix=g"
    else
      "--without-selinux"
    end

    # iconv is detected during configure process but -liconv is missing
    # from LDFLAGS as of gnu-tar 1.35. Remove once iconv linking works
    # without this. See https://savannah.gnu.org/bugs/?64441.
    # fix commit, https://git.savannah.gnu.org/cgit/tar.git/commit/?id=8632df39, remove in next release
    ENV.append "LDFLAGS", "-liconv" if OS.mac?

    if OS.linux? && build.stable?
      # Backport https://git.savannah.gnu.org/cgit/tar.git/commit/?id=08c3fc2e9337094aff01a511170fd35fdb8f1ee3
      %w[acl_get_file_at acl_set_file_at acl_delete_def_file_at].each do |function|
        inreplace "src/xattrs.c", function, "tar_#{function}"
      end
    end

    system "./bootstrap" if build.head?
    system "./configure", *args
    inreplace "lib/Makefile", /^DEFAULT_RMT_DIR = .+$/, "DEFAULT_RMT_DIR = /etc" if OS.linux?
    system "make", "install"

    return unless OS.mac?

    # Symlink the executable into libexec/gnubin as "tar"
    (libexec/"gnubin").install_symlink bin/"gtar" => "tar"
    (libexec/"gnuman/man1").install_symlink man1/"gtar.1" => "tar.1"
    (libexec/"gnubin").install_symlink "../gnuman" => "man"
  end

  def caveats
    on_macos do
      <<~EOS
        GNU "tar" has been installed as "gtar".
        If you need to use it as "tar", you can add a "gnubin" directory
        to your PATH from your bashrc like:

            PATH="#{opt_libexec}/gnubin:$PATH"
      EOS
    end
  end

  test do
    (testpath/"test").write("test")
    if OS.mac?
      system bin/"gtar", "-czvf", "test.tar.gz", "test"
      assert_match "test", shell_output("#{bin}/gtar -xOzf test.tar.gz")
      assert_match "test", shell_output("#{opt_libexec}/gnubin/tar -xOzf test.tar.gz")
    else
      system bin/"tar", "-czvf", "test.tar.gz", "test"
      assert_match "test", shell_output("#{bin}/tar -xOzf test.tar.gz")
      assert_match "--rmt-command=/etc/rmt", shell_output("#{bin}/tar --show-defaults")
      assert_path_exists libexec/"rmt"
    end
  end
end
