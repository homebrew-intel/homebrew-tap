# Generated from Homebrew/homebrew-core@bee15277559640637059d39ec4a0ea534332440a by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/blake3.patch.
class Blake3 < Formula
  desc "C implementation of the BLAKE3 cryptographic hash function"
  homepage "https://github.com/BLAKE3-team/BLAKE3"
  url "https://github.com/BLAKE3-team/BLAKE3/archive/refs/tags/1.8.7.tar.gz"
  sha256 "c6782a28842b1c0478524ac06a4f2ede784038ee298d6e2162c0b089c4306a3c"
  license any_of: ["CC0-1.0", "Apache-2.0"]
  compatibility_version 1

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/blake3-1.8.7"
    rebuild 1
    sha256 cellar: :any, sequoia: "03167764aff8e620e510807dfe79a74491c76dbae4393015e986e925ac000945"
  end

  depends_on "macos-intel/tap/cmake" => :build

  deny_network_access!

  def install
    system "cmake", "-S", "c", "-B", "build", "-DBUILD_SHARED_LIBS=ON", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <errno.h>
      #include <stdio.h>
      #include <stdlib.h>
      #include <string.h>
      #include <unistd.h>

      #include <blake3.h>

      int main(void) {
        blake3_hasher hasher;
        blake3_hasher_init(&hasher);

        unsigned char buf[65536];
        while (1) {
          ssize_t n = read(STDIN_FILENO, buf, sizeof(buf));
          if (n > 0) {
            blake3_hasher_update(&hasher, buf, n);
          } else if (n == 0) {
            break; // end of file
          } else {
            fprintf(stderr, "read failed: %s\\n", strerror(errno));
            exit(1);
          }
        }

        uint8_t output[BLAKE3_OUT_LEN];
        blake3_hasher_finalize(&hasher, output, BLAKE3_OUT_LEN);

        for (size_t i = 0; i < BLAKE3_OUT_LEN; i++) {
          printf("%02x", output[i]);
        }
        printf("\\n");
        return 0;
      }
    C

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lblake3", "-o", "test"
    output = pipe_output("./test", "content\n", 0)
    assert_equal "df0c40684c6bda3958244ee330300fdcbc5a37fb7ae06fe886b786bc474be87e", output.strip
  end
end
