# Generated from Homebrew/homebrew-core@71f2f069cf7b6695d57f6bd91668f55e68d280cc by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/glab.patch.
class Glab < Formula
  desc "Open-source GitLab command-line tool"
  homepage "https://gitlab.com/gitlab-org/cli"
  url "https://gitlab.com/gitlab-org/cli.git",
    tag:      "v1.125.0",
    revision: "685c1cbd74c882e0c93d7011657adde811582ed7"
  license "MIT"
  head "https://gitlab.com/gitlab-org/cli.git", branch: "main"

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/glab-1.125.0"
    sha256 cellar: :any_skip_relocation, sequoia: "2bb886142ae968ab4e44b05f7d6e5cc17d333dd91ea8db29926742e7205ecf94"
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
