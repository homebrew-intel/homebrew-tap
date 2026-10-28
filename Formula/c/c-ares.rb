# Generated from Homebrew/homebrew-core@076d5c47d8f3f6f762744b6f02e93b19d784f0bf by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/c-ares.patch.
class CAres < Formula
  desc "Asynchronous DNS library"
  homepage "https://c-ares.org/"
  url "https://github.com/c-ares/c-ares/releases/download/v1.34.9/c-ares-1.34.9.tar.gz"
  sha256 "9364b70a12eb59a06830fb488d9357f90100dff0d98b23ea3593a183d43e6f2f"
  license "MIT"
  compatibility_version 1
  head "https://github.com/c-ares/c-ares.git", branch: "main"

  livecheck do
    url :homepage
    regex(/href=.*?c-ares[._-](\d+(?:\.\d+)+)\.t/i)
  end

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/c-ares-1.34.9"
    rebuild 1
    sha256 cellar: :any, sequoia: "80b658bc51d282feb06cf901d8ac49a2a31ed45388b4932f69ebc0b5a399a0d2"
  end

  depends_on "macos-intel/tap/cmake" => :build

  def install
    args = %W[
      -DCARES_STATIC=ON
      -DCARES_SHARED=ON
      -DCMAKE_INSTALL_RPATH=#{rpath}
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <ares.h>

      int main()
      {
        ares_library_init(ARES_LIB_INIT_ALL);
        ares_library_cleanup();
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lcares", "-o", "test"
    system "./test"

    system bin/"ahost", "127.0.0.1"
  end
end
