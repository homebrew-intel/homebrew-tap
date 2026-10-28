# Generated from Homebrew/homebrew-core@cfadc8c8d402d66cc7175918b34bea5c4d0ffa47 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/git-lfs.patch.
class GitLfs < Formula
  desc "Git extension for versioning large files"
  homepage "https://git-lfs.com/"
  url "https://github.com/git-lfs/git-lfs/releases/download/v3.8.1/git-lfs-v3.8.1.tar.gz"
  sha256 "1939307bef808580f7c8954ede7072889d7e76721f5d6fdc4ab110bf907330ab"
  license "MIT"
  compatibility_version 1

  # Upstream creates releases that are sometimes not the latest stable version,
  # so we use the `github_latest` strategy to fetch the release tagged as "latest".
  livecheck do
    url :stable
    strategy :github_latest
  end

  # bottle block: written by brew pr-pull

  depends_on "macos-intel/tap/asciidoctor" => :build
  depends_on "macos-intel/tap/go" => :build

  deny_network_access!

  def fetch
    system "go", "mod", "download"
  end

  def install
    ENV["GIT_LFS_SHA"] = ""
    ENV["VERSION"] = version

    system "make"
    system "make", "man"

    bin.install "bin/git-lfs"
    man1.install Dir["man/man1/*.1"]
    man5.install Dir["man/man5/*.5"]
    man7.install Dir["man/man7/*.7"]
    doc.install Dir["man/html/*.html"]
    generate_completions_from_executable(bin/"git-lfs", "completion")
  end

  def caveats
    <<~EOS
      Update your git config to finish installation:

        # Update global git config
        $ git lfs install

        # Update system git config
        $ git lfs install --system
    EOS
  end

  test do
    system "git", "init"
    system "git", "lfs", "track", "test"
    assert_match(/^test filter=lfs/, File.read(".gitattributes"))
  end
end
