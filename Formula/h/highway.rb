# Generated from Homebrew/homebrew-core@726b46e5846b7a2f6a5fc241fc60b06a3b8b0c71 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/highway.patch.
class Highway < Formula
  desc "Performance-portable, length-agnostic SIMD with runtime dispatch"
  homepage "https://github.com/google/highway"
  url "https://github.com/google/highway/archive/refs/tags/1.4.0.tar.gz"
  sha256 "e72241ac9524bb653ae52ced768b508045d4438726a303f10181a38f764a453c"
  license any_of: ["Apache-2.0", "BSD-3-Clause"]
  compatibility_version 1
  head "https://github.com/google/highway.git", branch: "master"

  # bottle block: written by brew pr-pull

  depends_on "macos-intel/tap/cmake" => :build

  # These used to be bundled with `jpeg-xl`.
  link_overwrite "include/hwy/*", "lib/pkgconfig/libhwy*"

  def install
    ENV.runtime_cpu_detection
    system "cmake", "-S", ".", "-B", "builddir",
                    "-DBUILD_SHARED_LIBS=ON",
                    "-DHWY_ENABLE_TESTS=OFF",
                    "-DHWY_ENABLE_EXAMPLES=OFF",
                    "-DCMAKE_INSTALL_RPATH=#{rpath}",
                    *std_cmake_args
    system "cmake", "--build", "builddir"
    system "cmake", "--install", "builddir"
    (share/"hwy").install "hwy/examples"
  end

  test do
    system ENV.cxx, "-std=c++11", "-I#{share}", "-I#{include}",
                    share/"hwy/examples/benchmark.cc", "-L#{lib}", "-lhwy"
    system "./a.out"
  end
end
