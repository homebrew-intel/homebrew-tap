# Generated from Homebrew/homebrew-core@f4781b7a0139d0850095188418ffb12682475cb8 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/sonar-scanner.patch.
class SonarScanner < Formula
  desc "Launcher to analyze a project with SonarQube"
  homepage "https://docs.sonarqube.org/latest/analysis/scan/sonarscanner/"
  url "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-8.3.0.16463.zip"
  sha256 "d82326758561af2b3fba8bf9404d33ffc6a90edb8f47f8df976741beff4e34de"
  license "LGPL-3.0-or-later"
  head "https://github.com/SonarSource/sonar-scanner-cli.git", branch: "master"

  # bottle block: written by brew pr-pull

  depends_on "macos-intel/tap/openjdk"

  def install
    rm_r(Dir["bin/*.bat"])
    libexec.install Dir["*"]
    bin.install libexec/"bin/sonar-scanner"
    etc.install libexec/"conf/sonar-scanner.properties"
    ln_s etc/"sonar-scanner.properties", libexec/"conf/sonar-scanner.properties"
    bin.env_script_all_files libexec/"bin/",
                              SONAR_SCANNER_HOME: libexec,
                              JAVA_HOME:          Language::Java.overridable_java_home_env[:JAVA_HOME]
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/sonar-scanner --version")
  end
end
