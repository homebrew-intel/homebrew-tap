# Generated from Homebrew/homebrew-core@8701235251a995187352bd621a2f182a1127fa8c by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/curl.patch.
class Curl < Formula
  desc "Get a file from an HTTP, HTTPS or FTP server"
  homepage "https://curl.se"
  # Don't forget to update both instances of the version in the GitHub mirror URL.
  url "https://curl.se/download/curl-8.23.0.tar.bz2"
  mirror "https://github.com/curl/curl/releases/download/curl-8_23_0/curl-8.23.0.tar.bz2"
  mirror "http://fresh-center.net/linux/www/curl-8.23.0.tar.bz2"
  mirror "http://fresh-center.net/linux/www/legacy/curl-8.23.0.tar.bz2"
  sha256 "95b22eb32bf6d1fa6e3e9463bdb61cece3efc56d86576a9b3cbd428246a6d854"
  license "curl"
  compatibility_version 1

  livecheck do
    url "https://curl.se/download/"
    regex(/href=.*?curl[._-]v?(.*?)\.t/i)
  end

  # bottle block: written by brew pr-pull
  bottle do
    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/curl-8.23.0"
    sha256 cellar: :any, sequoia: "852283901388095ea04db67fe4167d27874917d5496302b58a6a1d4c2405f292"
  end

  head do
    url "https://github.com/curl/curl.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "libtool" => :build
    depends_on "macos-intel/tap/automake" => :build
  end

  keg_only :provided_by_macos

  depends_on "macos-intel/tap/pkgconf" => [:build, :test]
  depends_on "macos-intel/tap/brotli"
  depends_on "macos-intel/tap/libnghttp2"
  depends_on "macos-intel/tap/libnghttp3"
  depends_on "macos-intel/tap/libngtcp2"
  depends_on "macos-intel/tap/libpsl"
  depends_on "macos-intel/tap/libssh2"
  depends_on "macos-intel/tap/openssl@4"
  depends_on "macos-intel/tap/zstd"

  uses_from_macos "krb5"
  uses_from_macos "openldap"

  on_system :linux, macos: :monterey_or_older do
    depends_on "macos-intel/tap/libidn2"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  # Test fetches remote URLs
  allow_network_access! :test

  def install
    tag_name = "curl-#{version.to_s.tr(".", "_")}"
    if build.stable? && stable.mirrors.grep(%r{\Ahttps?://(www\.)?github\.com/}).first.exclude?(tag_name)
      odie "Tag name #{tag_name} is not found in the GitHub mirror URL! " \
           "Please make sure the URL is correct."
    end

    # Use our `curl` formula with `wcurl`
    inreplace "scripts/wcurl", 'CMD="curl "', "CMD=\"#{opt_bin}/curl \""

    system "autoreconf", "--force", "--install", "--verbose" if build.head?

    args = %W[
      --disable-silent-rules
      --with-ssl=#{formula_opt_prefix("openssl@4")}
      --without-ca-bundle
      --without-ca-path
      --with-ca-fallback
      --with-default-ssl-backend=openssl
      --with-libssh2
      --with-nghttp3
      --with-ngtcp2
      --with-libpsl
      --with-zsh-functions-dir=#{zsh_completion}
      --with-fish-functions-dir=#{fish_completion}
    ]

    args += if OS.mac?
      %w[
        --with-apple-sectrust
        --with-gssapi
      ]
    else
      ["--with-gssapi=#{formula_opt_prefix("krb5")}"]
    end

    args += if OS.mac? && MacOS.version >= :ventura
      %w[
        --with-apple-idn
        --without-libidn2
      ]
    else
      %w[
        --without-apple-idn
        --with-libidn2
      ]
    end

    system "./configure", *args, *std_configure_args
    system "make", "install"
    system "make", "install", "-C", "scripts"
    libexec.install "scripts/mk-ca-bundle.pl"
  end

  test do
    # Fetch the curl tarball and see that the checksum matches.
    # This requires a network connection, but so does Homebrew in general.
    filename = testpath/"test.tar.gz"
    system bin/"curl", "-L", stable.url, "-o", filename
    filename.verify_checksum stable.checksum

    # Verify QUIC and HTTP3 support
    system bin/"curl", "--verbose", "--http3-only", "--head", "https://cloudflare-quic.com"

    # Check dependencies linked correctly
    curl_features = shell_output("#{bin}/curl-config --features").split("\n")
    %w[brotli GSS-API HTTP2 HTTP3 IDN libz PSL SSL zstd].each do |feature|
      assert_includes curl_features, feature
    end
    curl_protocols = shell_output("#{bin}/curl-config --protocols").split("\n")
    %w[LDAPS SCP SFTP].each do |protocol|
      assert_includes curl_protocols, protocol
    end

    system libexec/"mk-ca-bundle.pl", "test.pem"
    assert_path_exists testpath/"test.pem"
    assert_path_exists testpath/"certdata.txt"

    ENV["PKG_CONFIG_PATH"] = lib/"pkgconfig"
    system "pkgconf", "--cflags", "libcurl"
  end
end
