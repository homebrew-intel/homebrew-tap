# Generated from Homebrew/homebrew-core@076d5c47d8f3f6f762744b6f02e93b19d784f0bf by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/nbytes.patch.
class Nbytes < Formula
  desc "Library of byte handling functions extracted from Node.js core"
  homepage "https://github.com/nodejs/nbytes"
  url "https://github.com/nodejs/nbytes/archive/refs/tags/v0.1.4.tar.gz"
  sha256 "67f4b8363f12abb64c07a0cecf2bf2dce7ab47b5f8b9fd2efdb852ea254c2d40"
  license "MIT"

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/nbytes-0.1.4"
    rebuild 1
    sha256 cellar: :any, sequoia: "2778cf52e8d9273f167f55b0a767c35dd385c712e6868b6894f2d3fca9363b30"
  end

  depends_on "macos-intel/tap/cmake" => :build

  deny_network_access!

  def install
    args = %w[
      -DBUILD_SHARED_LIBS=ON
      -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON
    ]

    system "cmake", "-S", ".", "-B", "build", *std_cmake_args, *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test-main.cpp").write <<~CPP
      #include <nbytes.h>
      #include <iostream>

      int main() {
        constexpr char input[] = "SGVsbG8sIFdvcmxkIQ=="; // "Hello, World!"
        char output[64] = {};
        size_t n = nbytes::Base64Decode(output, sizeof(output), input, sizeof(input) - 1);
        std::cout << output << std::endl;
        return 0;
      }
    CPP

    system ENV.cxx, "-std=c++20", "test-main.cpp", "-I#{include}", "-L#{lib}", "-lnbytes", "-o", "test-main"

    assert_equal "Hello, World!\n", shell_output("./test-main")
  end
end
