# Generated from Homebrew/homebrew-core@34b9bceef03fee96aaa8ead8efc5c058ffe37de9 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/aklomp-base64.patch.
class AklompBase64 < Formula
  desc "Fast Base64 stream encoder/decoder in C99, with SIMD acceleration"
  homepage "https://github.com/aklomp/base64"
  url "https://github.com/aklomp/base64/archive/refs/tags/v0.5.2.tar.gz"
  sha256 "723a0f9f4cf44cf79e97bcc315ec8f85e52eb104c8882942c3f2fba95acc080d"
  license "BSD-2-Clause"
  compatibility_version 1

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/aklomp-base64-0.5.2"
    rebuild 1
    sha256 cellar: :any, sequoia: "81b1d10bbd8dfcfe30a640554c8325e42955eca3fd956917bf3184def557cb10"
  end

  depends_on "macos-intel/tap/cmake" => :build

  conflicts_with "base64", because: "both install `base64` binaries"

  deny_network_access!

  def install
    system "cmake", "-S", ".", "-B", "build",
                    "-DBUILD_SHARED_LIBS=ON",
                    "-DCMAKE_INSTALL_RPATH=#{rpath}",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    assert_equal "aGVsbG8=", pipe_output(bin/"base64", "hello", 0).strip
  end
end
