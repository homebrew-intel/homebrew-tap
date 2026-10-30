# Generated from Homebrew/homebrew-core@2d52dc6671cddf66a3bee75aa2b2b68236894664 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/openjdk.patch.
class Openjdk < Formula
  desc "Development kit for the Java programming language"
  homepage "https://openjdk.org/"
  url "https://github.com/openjdk/jdk27u/archive/refs/tags/jdk-27.0.1.0.3-ga.tar.gz"
  sha256 "d4f0d695767eee4842b1e6a22daf5af6a87bcaeea68f0597538a97bd8fb340a6"
  license "GPL-2.0-only" => { with: "Classpath-exception-2.0" }
  compatibility_version 2

  livecheck do
    url :stable
    regex(/^jdk[._-]v?(\d+(?:\.\d+)*)-ga$/i)
  end

  # bottle block: written by brew pr-pull

  keg_only :shadowed_by_macos

  depends_on "autoconf" => :build
  depends_on "macos-intel/tap/pkgconf" => :build
  depends_on "macos-intel/tap/freetype"
  depends_on "macos-intel/tap/giflib"
  depends_on "macos-intel/tap/harfbuzz"
  depends_on "macos-intel/tap/jpeg-turbo"
  depends_on "macos-intel/tap/libpng"
  depends_on "macos-intel/tap/little-cms2"

  uses_from_macos "unzip" => :build
  uses_from_macos "zip" => :build
  uses_from_macos "cups" => :no_linkage

  on_macos do
    depends_on xcode: :build # for metal
  end

  on_linux do
    depends_on "libxt" => :build
    depends_on "alsa-lib"
    depends_on "libxi"
    depends_on "libxrandr" => :no_linkage
    depends_on "libxtst"
    depends_on "macos-intel/tap/fontconfig" => :no_linkage
    depends_on "macos-intel/tap/libx11"
    depends_on "macos-intel/tap/libxext"
    depends_on "macos-intel/tap/libxrender"
    depends_on "zlib-ng-compat"
  end

  # From https://jdk.java.net/archive/
  resource "boot-jdk" do
    on_macos do
      on_arm do
        url "https://download.java.net/java/GA/jdk27/55ce5470a6294008af0057ff4626d0e5/35/GPL/openjdk-27_macos-aarch64_bin.tar.gz"
        sha256 "ff42134c1bc5ac81c5a91a95fd4df87479db5d0499ba875d6adb5bda5626c3e8"
      end
      # jdk.java.net ships no macOS x64 build of JDK 27; JDK 26 is a valid (N-1) boot JDK.
      on_intel do
        url "https://download.java.net/java/GA/jdk26.0.2.1/3b8e6c7ec6274148a7aa15e7e7dfb53c/1/GPL/openjdk-26.0.2.1_macos-x64_bin.tar.gz"
        sha256 "5ec3817530ffa1c38f15a55609a2767335bbd0c59ea8ce41aad68d3cd620c0ae"
      end
    end
    on_linux do
      on_arm do
        url "https://download.java.net/java/GA/jdk27/55ce5470a6294008af0057ff4626d0e5/35/GPL/openjdk-27_linux-aarch64_bin.tar.gz"
        sha256 "da4e9dde1fff90204739e969187bab4751bd59a2a1c479672e1a1810f7dd23ea"
      end
      on_intel do
        url "https://download.java.net/java/GA/jdk27/55ce5470a6294008af0057ff4626d0e5/35/GPL/openjdk-27_linux-x64_bin.tar.gz"
        sha256 "95fc37eb3a18a27a26d5904c2d89d52bace8dafa9a078ca27f4747fbc4bf070b"
      end
    end
  end

  # uses local ports during build process
  allow_network_access! :build

  def install
    boot_jdk = buildpath/"boot-jdk"
    resource("boot-jdk").stage boot_jdk
    boot_jdk /= "Contents/Home" if OS.mac?
    java_options = ENV.delete("_JAVA_OPTIONS")

    args = %W[
      --disable-warnings-as-errors
      --with-boot-jdk-jvmargs=#{java_options}
      --with-boot-jdk=#{boot_jdk}
      --with-debug-level=release
      --with-jvm-variants=server
      --with-native-debug-symbols=none
      --with-vendor-bug-url=#{tap.issues_url}
      --with-vendor-name=#{tap.user}
      --with-vendor-url=#{tap.issues_url}
      --with-vendor-version-string=#{tap.user}
      --with-vendor-vm-bug-url=#{tap.issues_url}
      --with-version-build=#{revision}
      --without-version-opt
      --without-version-pre
      --with-freetype=system
      --with-giflib=system
      --with-harfbuzz=system
      --with-lcms=system
      --with-libjpeg=system
      --with-libpng=system
      --with-zlib=system
    ]

    ldflags = %W[
      -Wl,-rpath,#{loader_path.gsub("$", "\\$$")}
      -Wl,-rpath,#{loader_path.gsub("$", "\\$$")}/server
    ]
    args += if OS.mac?
      ldflags << "-headerpad_max_install_names"

      # Allow unbundling `freetype` on macOS
      inreplace "make/autoconf/lib-freetype.m4", '= "xmacosx"', '= ""'

      %W[
        --enable-dtrace
        --with-freetype-include=#{formula_opt_include("freetype")}
        --with-freetype-lib=#{formula_opt_lib("freetype")}
        --with-sysroot=#{MacOS.sdk_path}
      ]
    else
      %W[
        --with-x=#{HOMEBREW_PREFIX}
        --with-cups=#{HOMEBREW_PREFIX}
        --with-fontconfig=#{HOMEBREW_PREFIX}
        --with-stdc++lib=dynamic
      ]
    end
    args << "--with-extra-ldflags=#{ldflags.join(" ")}"

    system "bash", "configure", *args

    ENV["MAKEFLAGS"] = "JOBS=#{ENV.make_jobs}"
    system "make", "images"

    jdk = libexec
    if OS.mac?
      libexec.install Dir["build/*/images/jdk-bundle/*"].first => "openjdk.jdk"
      jdk /= "openjdk.jdk/Contents/Home"
    else
      libexec.install Dir["build/linux-*-server-release/images/jdk/*"]
    end

    bin.install_symlink Dir[jdk/"bin/*"]
    include.install_symlink Dir[jdk/"include/*.h"]
    include.install_symlink Dir[jdk/"include"/OS.kernel_name.downcase/"*.h"]
    man1.install_symlink Dir[jdk/"man/man1/*"]
  end

  def caveats
    on_macos do
      <<~EOS
        For the system Java wrappers to find this JDK, symlink it with
          sudo ln -sfn #{opt_libexec}/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk
      EOS
    end
  end

  test do
    (testpath/"HelloWorld.java").write <<~JAVA
      class HelloWorld {
        public static void main(String args[]) {
          System.out.println("Hello, world!");
        }
      }
    JAVA

    system bin/"javac", "HelloWorld.java"

    assert_match "Hello, world!", shell_output("#{bin}/java HelloWorld")
  end
end
