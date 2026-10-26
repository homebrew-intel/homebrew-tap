# Generated from Homebrew/homebrew-core@bace6d7b45d7f4a15b78f0a34eb8b696c058eb47 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/ninja.patch.
class Ninja < Formula
  desc "Small build system for use with gyp or CMake"
  homepage "https://ninja-build.org/"
  url "https://github.com/ninja-build/ninja/archive/refs/tags/v1.13.2.tar.gz"
  sha256 "974d6b2f4eeefa25625d34da3cb36bdcebe7fbce40f4c16ac0835fd1c0cbae17"
  license "Apache-2.0"
  compatibility_version 1
  head "https://github.com/ninja-build/ninja.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/ninja-1.13.2"
    rebuild 1
    sha256 cellar: :any_skip_relocation, sequoia: "3501cd17bae5c5989d6cf3d9c3539ff1574181388a4b1ce6c0ab047a67c2502c"
  end

  uses_from_macos "python" => [:build, :test]

  # runs a server in the test
  allow_network_access! :test

  def install
    system "python3", "configure.py", "--bootstrap", "--verbose", "--with-python=python3"

    bin.install "ninja"
    bash_completion.install "misc/bash-completion" => "ninja"
    zsh_completion.install "misc/zsh-completion" => "_ninja"
    doc.install "doc/manual.asciidoc"
    (share/"vim/vimfiles/syntax").install "misc/ninja.vim"
  end

  test do
    (testpath/"build.ninja").write <<~NINJA
      cflags = -Wall

      rule cc
        command = gcc $cflags -c $in -o $out

      build foo.o: cc foo.c
    NINJA
    system bin/"ninja", "-t", "targets"
    port = free_port
    spawn bin/"ninja", "-t", "browse", "--port=#{port}", "--hostname=127.0.0.1", "--no-browser", "foo.o"
    assert_match "foo.c", shell_output("curl --silent --retry 5 --retry-connrefused http://127.0.0.1:#{port}?foo.o")
  end
end
