# Generated from Homebrew/homebrew-core@e8ef0108242be8280a06fd3349f2d00563388f70 by scripts/tap/render.py; do not edit.
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

  depends_on "homebrew-intel/tap/go" => :build

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
