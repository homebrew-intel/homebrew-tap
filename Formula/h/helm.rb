# Generated from Homebrew/homebrew-core@f2fa4540ee4fc41c70a3c94df121528a11c17cb6 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/helm.patch.
class Helm < Formula
  desc "Kubernetes package manager"
  homepage "https://helm.sh/"
  url "https://github.com/helm/helm.git",
      tag:      "v4.3.1",
      revision: "c0d08d0d6d9424d4a14febb5e8a3e51b0dd00dff"
  license "Apache-2.0"
  head "https://github.com/helm/helm.git", branch: "main"

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/helm-4.3.1"
    rebuild 1
    sha256 cellar: :any_skip_relocation, sequoia: "187dfc992d9eee84b0e6b46fe60aebdc84000885ce87fc36b4111c623765eec6"
  end

  depends_on "macos-intel/tap/go" => :build

  deny_network_access!

  def fetch
    # `make build` runs `go mod tidy`, which needs the full module graph
    system "go", "mod", "download", "all"
  end

  def install
    system "make", "build"
    bin.install "bin/helm"

    mkdir "man1" do
      system bin/"helm", "docs", "--type", "man"
      man1.install Dir["*"]
    end

    generate_completions_from_executable(bin/"helm", shell_parameter_format: :cobra)
  end

  test do
    system bin/"helm", "create", "foo"
    assert File.directory? testpath/"foo/charts"

    version_output = shell_output("#{bin}/helm version 2>&1")
    assert_match "GitCommit:\"#{stable.specs[:revision]}\"", version_output
    assert_match "Version:\"v#{version}\"", version_output
  end
end
