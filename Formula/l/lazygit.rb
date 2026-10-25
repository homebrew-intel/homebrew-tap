# Generated from Homebrew/homebrew-core@f2fa4540ee4fc41c70a3c94df121528a11c17cb6 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/lazygit.patch.
class Lazygit < Formula
  desc "Simple terminal UI for git commands"
  homepage "https://github.com/jesseduffield/lazygit/"
  url "https://github.com/jesseduffield/lazygit/archive/refs/tags/v0.66.2.tar.gz"
  sha256 "fcaad0909af765ef87bd873164a4de78435515ab4d8b04f58d6ad51e8ecd00e5"
  license "MIT"
  head "https://github.com/jesseduffield/lazygit.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/lazygit-0.66.2"
    rebuild 1
    sha256 cellar: :any_skip_relocation, sequoia: "9f865cb1c906fd6b116c7c2001e90201a102ed66e47b2d19dce844744f8ce4e7"
  end

  depends_on "macos-intel/tap/go" => :build

  deny_network_access!

  def install
    ENV["CGO_ENABLED"] = OS.mac? ? "1" : "0"
    ldflags = "-X main.version=#{version} -X main.buildSource=#{tap.user}"
    system "go", "build", "-mod=vendor", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"lazygit", "completion", shells: [:bash, :zsh, :fish, :pwsh])
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/lazygit -v")

    system "git", "init", "--initial-branch=main"

    s = testpath/"test.txt"
    pid = spawn(bin/"lazygit", "-l", out: s.to_s, err: [:child, :out])
    sleep 2
    assert_match "Log file does not exist. Run `lazygit --debug` first to create the log file", s.read
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
