# Generated from Homebrew/homebrew-core@34b9bceef03fee96aaa8ead8efc5c058ffe37de9 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/span-lite.patch.
class SpanLite < Formula
  desc "C++20-like span for C++98, C++11 and later in a single-file header-only library"
  homepage "https://github.com/nonstd-lite/span-lite"
  url "https://github.com/nonstd-lite/span-lite/archive/refs/tags/v0.11.0.tar.gz"
  sha256 "ef4e028e18ff21044da4b4641ca1bc8a2e2d656e2028322876c0e1b9b6904f9d"
  license "BSL-1.0"
  compatibility_version 1
  head "https://github.com/nonstd-lite/span-lite.git", branch: "master"

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/span-lite-0.11.0"
    rebuild 1
    sha256 cellar: :any_skip_relocation, sequoia: "7ec9046f366829598e3db52f03faa2c85509a8fd18cf3b90abb76576d099b368"
  end

  depends_on "macos-intel/tap/cmake" => :build

  deny_network_access!
  def install
    system "cmake", "-S", ".", "-B", "build", "-DSPAN_LITE_OPT_BUILD_TESTS=OFF", *std_cmake_args
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"basic.cpp").write <<~CPP
      #include "nonstd/span.hpp"
      #include <array>
      #include <vector>
      #include <iostream>

      std::ptrdiff_t size( nonstd::span<const int> spn )
      {
          return spn.size();
      }

      int main()
      {
          int arr[] = { 1, };

          std::cout <<
              "C-array:" << size( arr ) <<
              " array:"  << size( std::array <int, 2>{ 1, 2, } ) <<
              " vector:" << size( std::vector<int   >{ 1, 2, 3, } );
      }
    CPP

    system ENV.cxx, "-std=c++11", "-I#{include}", "basic.cpp", "-o", "basic"
    system "./basic"
  end
end
