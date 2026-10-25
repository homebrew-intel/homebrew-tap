# Generated from Homebrew/homebrew-core@e8ef0108242be8280a06fd3349f2d00563388f70 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/utf8proc.patch.
class Utf8proc < Formula
  desc "Clean C library for processing UTF-8 Unicode data"
  homepage "https://juliastrings.github.io/utf8proc/"
  url "https://github.com/JuliaStrings/utf8proc/archive/refs/tags/v2.12.0.tar.gz"
  sha256 "f564011d38b2888d583d510b08e69ffa15aa117155db1b9b49ef1dfe1fa25111"
  license all_of: ["MIT", "Unicode-DFS-2015"]
  compatibility_version 1
  head "https://github.com/JuliaStrings/utf8proc.git", branch: "master"

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/homebrew-intel/homebrew-tap/releases/download/utf8proc-2.12.0"
    rebuild 1
    sha256 cellar: :any, sequoia: "99836690f5209a1bb16d4d3bf4c8d5bcacb2a9a1cef34062e309cb79286f4944"
  end

  depends_on "homebrew-intel/tap/cmake" => :build

  deny_network_access!

  def install
    system "cmake", "-S", ".", "-B", "build", "-DBUILD_SHARED_LIBS=ON", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <string.h>
      #include <utf8proc.h>

      int main() {
        const char *version = utf8proc_version();
        return strnlen(version, sizeof("1.3.1-dev")) > 0 ? 0 : -1;
      }
    C

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lutf8proc", "-o", "test"
    system "./test"
  end
end
