# Generated from Homebrew/homebrew-core@8701235251a995187352bd621a2f182a1127fa8c by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/glab.patch.
class Glab < Formula
  desc "Open-source GitLab command-line tool"
  homepage "https://gitlab.com/gitlab-org/cli"
  url "https://gitlab.com/gitlab-org/cli.git",
    tag:      "v1.126.0",
    revision: "4dd0d32d18361db6c1c668eb4ac691c0d6edf255"
  license "MIT"
  head "https://gitlab.com/gitlab-org/cli.git", branch: "main"

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/glab-1.126.0"
    sha256 cellar: :any_skip_relocation, sequoia: "92b26df4b0d764fc5c9b2da6aa272dcf8776cfb1f7d13ad017d7e7356afa88f9"
  end

  depends_on "macos-intel/tap/go" => :build

  # `test do` block queries the GitLab API
  allow_network_access! :test

  def fetch
    system "go", "mod", "download"
  end

  def install
    ENV["CGO_ENABLED"] = "1" if OS.mac?
    system "make"
    bin.install "bin/glab"
    generate_completions_from_executable(bin/"glab", "completion", "--shell")
  end

  test do
    system "git", "clone", "https://gitlab.com/cli-automated-testing/homebrew-testing.git"
    cd "homebrew-testing" do
      assert_match "Matt Nohr", shell_output("#{bin}/glab repo contributors")
      assert_match "This is a test issue", shell_output("#{bin}/glab issue list --all")
    end
  end
end
