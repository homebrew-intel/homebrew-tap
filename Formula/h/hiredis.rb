# Generated from Homebrew/homebrew-core@02e642fb33630603a58f53d14d9f3d1e93fc56a7 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/hiredis.patch.
class Hiredis < Formula
  desc "Minimalistic client for Redis"
  homepage "https://github.com/redis/hiredis"
  url "https://github.com/redis/hiredis/archive/refs/tags/v1.5.0.tar.gz"
  sha256 "eec7ef8641d221e144a58d5ef8d733c8c75c7fd487097a233aacb4fa33981cfb"
  license "BSD-3-Clause"
  compatibility_version 3
  head "https://github.com/redis/hiredis.git", branch: "master"

  # bottle block: written by brew pr-pull

  depends_on "macos-intel/tap/openssl@4"

  deny_network_access!

  def install
    system "make", "install", "PREFIX=#{prefix}", "USE_SSL=1"
    pkgshare.install "examples"
  end

  test do
    # running `./test` requires a database to connect to, so just make
    # sure it compiles
    system ENV.cc, pkgshare/"examples/example.c", "-o", testpath/"test",
                   "-I#{include}/hiredis", "-L#{lib}", "-lhiredis"
    assert_path_exists testpath/"test"
  end
end
