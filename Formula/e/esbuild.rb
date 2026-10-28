# Generated from Homebrew/homebrew-core@bee15277559640637059d39ec4a0ea534332440a by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/esbuild.patch.
class Esbuild < Formula
  desc "Extremely fast JavaScript bundler and minifier"
  homepage "https://esbuild.github.io/"
  url "https://github.com/evanw/esbuild/archive/refs/tags/v0.28.2.tar.gz"
  sha256 "300162f899361d9f0263065f8728ef9086dcfc1a3d36bcbc4e0abe5de9c58bf8"
  license "MIT"
  head "https://github.com/evanw/esbuild.git", branch: "main"

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/esbuild-0.28.2"
    rebuild 1
    sha256 cellar: :any_skip_relocation, sequoia: "04adb1c654ff1d7cdbe45f5267a6820adbb0221ffb155da62ef51d30f36f623f"
  end

  depends_on "macos-intel/tap/go" => :build
  depends_on "macos-intel/tap/node" => :test

  allow_network_access! :test

  def fetch
    system "go", "mod", "download"
  end

  def install
    ENV["CGO_ENABLED"] = OS.mac? ? "1" : "0"
    system "go", "build", *std_go_args, "./cmd/esbuild"
  end

  test do
    (testpath/"app.jsx").write <<~JS
      import * as React from 'react'
      import * as Server from 'react-dom/server'

      let Greet = () => <h1>Hello, world!</h1>
      console.log(Server.renderToString(<Greet />))
      process.exit()
    JS

    system formula_opt_libexec("node")/"bin/npm", "install", "react", "react-dom"
    system bin/"esbuild", "app.jsx", "--bundle", "--outfile=out.js"

    assert_equal "<h1>Hello, world!</h1>\n", shell_output("node out.js")
  end
end
