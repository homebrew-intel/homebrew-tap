# Generated from Homebrew/homebrew-core@076d5c47d8f3f6f762744b6f02e93b19d784f0bf by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/uvwasi.patch.
class Uvwasi < Formula
  desc "WASI syscall API built atop libuv"
  homepage "https://github.com/nodejs/uvwasi"
  url "https://github.com/nodejs/uvwasi/archive/refs/tags/v0.0.23.tar.gz"
  sha256 "cdb148aac298883b51da887657deca910c7c02f35435e24f125cef536fe8d5e1"
  license "MIT"
  compatibility_version 1
  head "https://github.com/nodejs/uvwasi.git", branch: "main"

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/uvwasi-0.0.23"
    rebuild 1
    sha256 cellar: :any, sequoia: "d3f53984b4ff0a9f26ac634afb05dc3c520e4605cdc010507cfda67730460f9c"
  end

  depends_on "macos-intel/tap/cmake" => :build
  depends_on "macos-intel/tap/libuv"

  # Remove find_dependency for a not-installed module in CMake config
  patch do
    url "https://github.com/nodejs/uvwasi/commit/fcc0be004867939389aba3cc715ea90b86ab869c.patch?full_index=1"
    sha256 "4a3a388e9831709089270b7c6bc779d86257857192dee247d32ec360cd7819cc"
    type :unofficial
    resolves "https://github.com/nodejs/uvwasi/pull/313"
  end

  deny_network_access!

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    # Adapted from "Example Usage" in README.
    (testpath/"test-uvwasi.c").write <<~C
      #include <stdlib.h>
      #include <string.h>
      #include "uv.h"
      #include "uvwasi.h"

      int main(void) {
        uvwasi_t uvwasi;
        uvwasi_options_t init_options;
        uvwasi_errno_t err;

        memset(&init_options, 0, sizeof(init_options));

        /* Setup the initialization options. */
        init_options.in = 0;
        init_options.out = 1;
        init_options.err = 2;
        init_options.fd_table_size = 4;

        init_options.argc = 1;
        init_options.argv = calloc(init_options.argc, sizeof(char*));
        init_options.argv[0] = strdup("test-uvwasi");

        init_options.envp = calloc(1, sizeof(char*));
        init_options.envp[0] = NULL;

        init_options.preopenc = 1;
        init_options.preopens = calloc(1, sizeof(uvwasi_preopen_t));
        init_options.preopens[0].mapped_path = strdup("/sandbox");
        init_options.preopens[0].real_path = strdup("/tmp");

        init_options.allocator = NULL;

        /* Initialize the sandbox. */
        err = uvwasi_init(&uvwasi, &init_options);

        if (err != UVWASI_ESUCCESS) {
          fprintf(stderr, "uvwasi_init() failed: %d\\n", err);
          return 1;
        }

        /* Clean up resources. */
        uvwasi_destroy(&uvwasi);
        return 0;
      }
    C

    ENV.append_to_cflags "-I#{include} -I#{formula_opt_include("libuv")}"
    ENV.append "LDFLAGS", "-L#{lib}"
    ENV.append "LDLIBS", "-luvwasi"

    system "make", "test-uvwasi"
    system "./test-uvwasi"
  end
end
