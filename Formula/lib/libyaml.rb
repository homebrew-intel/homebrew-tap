# Generated from Homebrew/homebrew-core@a4712f8802a66ece0977d85bd7bf2db458568993 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/libyaml.patch.
class Libyaml < Formula
  desc "YAML Parser"
  homepage "https://github.com/yaml/libyaml"
  url "https://github.com/yaml/libyaml/archive/refs/tags/0.2.5.tar.gz"
  sha256 "fa240dbf262be053f3898006d502d514936c818e422afdcf33921c63bed9bf2e"
  license "MIT"
  compatibility_version 1

  livecheck do
    url :stable
    strategy :github_latest
  end

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/libyaml-0.2.5"
    rebuild 1
    sha256 cellar: :any, sequoia: "2165cbc402e41ece9ebcf9d63a67e127d06d48b401bef1a7cab05a189904e72e"
  end

  depends_on "autoconf" => :build
  depends_on "libtool" => :build
  depends_on "macos-intel/tap/automake" => :build

  def install
    system "./bootstrap"
    system "./configure", "--disable-dependency-tracking", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <yaml.h>

      int main()
      {
        yaml_parser_t parser;
        yaml_parser_initialize(&parser);
        yaml_parser_delete(&parser);
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lyaml", "-o", "test"
    system "./test"
  end
end
