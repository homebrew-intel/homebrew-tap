# Generated from Homebrew/homebrew-core@dc696222c55eeef85dc35114e6ec027cae3604ca by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/json-c.patch.
class JsonC < Formula
  desc "JSON parser for C"
  homepage "https://github.com/json-c/json-c/wiki"
  url "https://s3.amazonaws.com/json-c_releases/releases/json-c-0.19.tar.gz"
  sha256 "37ad0249902e301bd9052bf712e511fcc6acff4ecaad4b5900aad9ce564e26de"
  license "MIT"
  head "https://github.com/json-c/json-c.git", branch: "master"

  livecheck do
    url :head
    regex(/^json-c[._-](\d+(?:\.\d+)+)(?:[._-]\d{6,8})?$/i)
  end

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/homebrew-intel/homebrew-tap/releases/download/json-c-0.19"
    rebuild 1
    sha256 cellar: :any, sequoia: "ae26ec0d564c0ba38a381b249d7ade73ec5d73fbf0d293b11d6d2211206b7901"
  end

  depends_on "homebrew-intel/tap/cmake" => :build

  deny_network_access!

  def install
    # We pass `BUILD_APPS=OFF` since any built apps are never installed. See:
    #   https://github.com/json-c/json-c/blob/master/apps/CMakeLists.txt#L119-L121
    system "cmake", "-S", ".", "-B", "build", "-DBUILD_APPS=OFF", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~'EOS'
      #include <stdio.h>
      #include <json-c/json.h>

      int main() {
        json_object *obj = json_object_new_object();
        json_object *value = json_object_new_string("value");
        json_object_object_add(obj, "key", value);
        printf("%s\n", json_object_to_json_string(obj));
        return 0;
      }
    EOS

    system ENV.cc, "-I#{include}", "test.c", "-L#{lib}", "-ljson-c", "-o", "test"
    assert_equal '{ "key": "value" }', shell_output("./test").chomp
  end
end
