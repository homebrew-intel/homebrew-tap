# Generated from Homebrew/homebrew-core@726b46e5846b7a2f6a5fc241fc60b06a3b8b0c71 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/simdjson.patch.
class Simdjson < Formula
  desc "SIMD-accelerated C++ JSON parser"
  homepage "https://simdjson.org"
  url "https://github.com/simdjson/simdjson/archive/refs/tags/v5.0.6.tar.gz"
  sha256 "a2535137f8da93c0a61a6eeb47e96e502e16db89223b64f76b4041d595f797d7"
  license "Apache-2.0"
  head "https://github.com/simdjson/simdjson.git", branch: "master"

  # bottle block: written by brew pr-pull

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
