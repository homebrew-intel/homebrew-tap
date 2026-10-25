# Generated from Homebrew/homebrew-core@5dc8e789d823006a4b7ca94336645ae3f3b248f5 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/jq.patch.
class Jq < Formula
  desc "Lightweight and flexible command-line JSON processor"
  homepage "https://jqlang.github.io/jq/"
  url "https://github.com/jqlang/jq/releases/download/jq-1.8.2/jq-1.8.2.tar.gz"
  sha256 "71b8d6e8f5fe81f6c6d0d110e3892251f6ce76ed095abd315e26e6e1193af3af"
  license "MIT"
  compatibility_version 1

  livecheck do
    url :stable
    regex(/^(?:jq[._-])?v?(\d+(?:\.\d+)+)$/i)
  end

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/jq-1.8.2"
    rebuild 2
    sha256 cellar: :any, sequoia: "9d39c4231b9b1e6441642d53891510a81bfbe32f0d0a7a04adeb16ea4fa5646e"
  end

  head do
    url "https://github.com/jqlang/jq.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "libtool" => :build
    depends_on "macos-intel/tap/automake" => :build
  end

  depends_on "macos-intel/tap/oniguruma"

  deny_network_access!

  def install
    system "autoreconf", "--force", "--install", "--verbose" if build.head?
    system "./configure", *std_configure_args,
                          "--disable-silent-rules",
                          "--disable-maintainer-mode"
    system "make", "install"
  end

  test do
    assert_equal "2\n", pipe_output("#{bin}/jq .bar", '{"foo":1, "bar":2}')
  end
end
