# Generated from Homebrew/homebrew-core@34b9bceef03fee96aaa8ead8efc5c058ffe37de9 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/cxxopts.patch.
class Cxxopts < Formula
  desc "Lightweight C++ command-line option parser"
  homepage "https://github.com/jarro2783/cxxopts"
  url "https://github.com/jarro2783/cxxopts/archive/refs/tags/v3.3.1.tar.gz"
  sha256 "3bfc70542c521d4b55a46429d808178916a579b28d048bd8c727ee76c39e2072"
  license "MIT"
  compatibility_version 1
  head "https://github.com/jarro2783/cxxopts.git", branch: "master"

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/cxxopts-3.3.1"
    rebuild 1
    sha256 cellar: :any_skip_relocation, sequoia: "937c3f95af0e1e4c197a7a0a1436b5edb2063fc1647324be78b6647951a4f115"
  end

  depends_on "macos-intel/tap/cmake" => :build

  deny_network_access!

  def install
    # set `CXXOPTS_CMAKE_DIR` and `CMAKE_INSTALL_LIBDIR_ARCHIND` to create an `:all` bottle.
    args = %w[
      -DCMAKE_INSTALL_LIBDIR_ARCHIND=share
      -DCXXOPTS_BUILD_EXAMPLES=OFF
      -DCXXOPTS_BUILD_TESTS=OFF
      -DCXXOPTS_CMAKE_DIR=share/cmake/cxxopts
    ]

    # We don't need to run `cmake --build` because this is header-only.
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--install", "build"

    return unless (lib/"pkgconfig").directory?

    share.install lib/"pkgconfig"
  end

  test do
    (testpath/"test.cc").write <<~CPP
      #include <iostream>
      #include <cstdlib>
      #include <cxxopts.hpp>

      int main(int argc, char *argv[]) {
          cxxopts::Options options(argv[0]);

          std::string input;
          options.add_options()
              ("e,echo", "String to be echoed", cxxopts::value(input))
              ("h,help", "Print this help", cxxopts::value<bool>()->default_value("false"));

          auto result = options.parse(argc, argv);

          if (result.count("help")) {
              std::cout << options.help() << std::endl;
              std::exit(0);
          }

          std::cout << input << std::endl;

          return 0;
      }
    CPP

    system ENV.cxx, "-std=c++11", "test.cc", "-I#{include}", "-o", "test"
    assert_equal "echo string", shell_output("./test -e 'echo string'").strip
    assert_equal "echo string", shell_output("./test --echo='echo string'").strip
  end
end
