# Generated from Homebrew/homebrew-core@a2dee8ba714e60f35a4edf44c77561d60ac92a1a by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/libevent.patch.
class Libevent < Formula
  desc "Asynchronous event library"
  homepage "https://libevent.org/"
  url "https://github.com/libevent/libevent/releases/download/release-2.1.13-stable/libevent-2.1.13-stable.tar.gz"
  sha256 "f7e9383b8c0baa81b687e5b5eecc01beefaf1b19b64151d95ed61647fe7a315c"
  license "BSD-3-Clause"
  revision 1
  compatibility_version 1

  livecheck do
    url :homepage
    regex(/libevent[._-]v?(\d+(?:\.\d+)+)-stable/i)
  end

  bottle do
    root_url "https://github.com/homebrew-intel/homebrew-tap/releases/download/libevent-2.1.13_1"
    rebuild 1
    sha256 cellar: :any, sequoia: "ecff254e6463e39ea3dca6af4cb4426ade40fcaa9f77b86f44eb8e51c8f724e2"
  end

  # bottle block: written by brew pr-pull

  depends_on "homebrew-intel/tap/pkgconf" => :build
  depends_on "homebrew-intel/tap/openssl@4"

  def install
    system "./configure", "--disable-debug-mode", *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <event2/event.h>

      int main()
      {
        struct event_base *base;
        base = event_base_new();
        event_base_free(base);
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-levent", "-o", "test"
    system "./test"
  end
end
