# Generated from Homebrew/homebrew-core@bee15277559640637059d39ec4a0ea534332440a by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/rclone.patch.
class Rclone < Formula
  desc "Rsync for cloud storage"
  homepage "https://rclone.org/"
  url "https://github.com/rclone/rclone/archive/refs/tags/v1.75.2.tar.gz"
  sha256 "68afd7f68c84bd978966feae2116339aa7bf454b39c573910c462e87c3774d5a"
  license "MIT"
  compatibility_version 1
  head "https://github.com/rclone/rclone.git", branch: "master"

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/rclone-1.75.2"
    rebuild 1
    sha256 cellar: :any_skip_relocation, sequoia: "ac3202138379d63d7ab6c339d704e3e55044ddb06c12a857ca0f1641145f8fa1"
  end

  depends_on "macos-intel/tap/go" => :build

  deny_network_access!

  def fetch
    system "go", "mod", "download"
  end

  def install
    ldflags = %W[-X github.com/rclone/rclone/fs.Version=v#{version}]
    tags = "brew" if OS.mac?
    system "go", "build", *std_go_args(ldflags:, tags:)
    man1.install "rclone.1"
    system bin/"rclone", "genautocomplete", "bash", "rclone.bash"
    system bin/"rclone", "genautocomplete", "zsh", "_rclone"
    system bin/"rclone", "genautocomplete", "fish", "rclone.fish"
    bash_completion.install "rclone.bash" => "rclone"
    zsh_completion.install "_rclone"
    fish_completion.install "rclone.fish"
  end

  def caveats
    <<~EOS
      Homebrew's installation does not include the `mount` subcommand on macOS which depends on FUSE, use `nfsmount` instead.
    EOS
  end

  test do
    (testpath/"file1.txt").write "Test!"
    system bin/"rclone", "copy", testpath/"file1.txt", testpath/"dist"
    assert_match File.read(testpath/"file1.txt"), File.read(testpath/"dist/file1.txt")
  end
end
