# Generated from Homebrew/homebrew-core@f2fa4540ee4fc41c70a3c94df121528a11c17cb6 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/glab.patch.
class Glab < Formula
  desc "Open-source GitLab command-line tool"
  homepage "https://gitlab.com/gitlab-org/cli"
  url "https://gitlab.com/gitlab-org/cli.git",
    tag:      "v1.124.0",
    revision: "d43ccacecb043b0c060dd13224cf993140db6c2b"
  license "MIT"
  head "https://gitlab.com/gitlab-org/cli.git", branch: "main"

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/glab-1.124.0"
    rebuild 1
    sha256 cellar: :any_skip_relocation, sequoia: "21a231a899df0fabcc2e6a1c11fbe7988c517d714bc1de2321ca01cce8f225ae"
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
