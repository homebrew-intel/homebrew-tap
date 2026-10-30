# Generated from Homebrew/homebrew-core@c48d966391c9a986cd8c7ba7f0c59e62a40d91d4 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/simdjson.patch.
class Simdjson < Formula
  desc "SIMD-accelerated C++ JSON parser"
  homepage "https://simdjson.org"
  url "https://github.com/simdjson/simdjson/archive/refs/tags/v5.0.7.tar.gz"
  sha256 "a5282c9b00f6c8b5217f434636c78ee7c9019f2fd2aa478ba850d2e2584c0994"
  license "Apache-2.0"
  compatibility_version 1
  head "https://github.com/simdjson/simdjson.git", branch: "master"

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/simdjson-5.0.7"
    sha256 cellar: :any, sequoia: "2703c390a28cf2f48b98e740e12a9ed981afbb174b03760944fce5a63cc2adf1"
  end

  depends_on "macos-intel/tap/cmake" => :build

  deny_network_access!

  def install
    system "cmake", "-S", ".", "-B", "build",
                    "-DBUILD_SHARED_LIBS=ON",
                    "-DSIMDJSON_BUILD_STATIC_LIB=ON",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.json").write({ name: "Homebrew", isNull: nil }.to_json)
    (testpath/"test.cpp").write <<~CPP
      #include <iostream>
      #include <simdjson.h>
      int main(void) {
        simdjson::dom::parser parser;
        simdjson::dom::element json = parser.load("test.json");
        std::cout << json["name"] << std::endl;
      }
    CPP

    system ENV.cxx, "test.cpp", "-std=c++11",
           "-I#{include}", "-L#{lib}", "-lsimdjson", "-o", "test"
    assert_equal "\"Homebrew\"\n", shell_output("./test")
  end
end
