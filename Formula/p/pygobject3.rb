# Generated from Homebrew/homebrew-core@f4781b7a0139d0850095188418ffb12682475cb8 by scripts/tap/render.py; do not edit.
# Hand-written changes belong in patches/pygobject3.patch.
class Pygobject3 < Formula
  desc "GNOME Python bindings (based on GObject Introspection)"
  homepage "https://pygobject.gnome.org"
  url "https://download.gnome.org/sources/pygobject/3.58/pygobject-3.58.1.tar.gz"
  sha256 "4c80598ade17fbaa7798e01a25d0bf29ce109740786026a074c5c62bb3e79d23"
  license "LGPL-2.1-or-later"
  revision 1
  compatibility_version 1

  # bottle block: written by brew pr-pull

  depends_on "macos-intel/tap/meson" => :build
  depends_on "macos-intel/tap/ninja" => :build
  depends_on "macos-intel/tap/pkgconf" => :build
  depends_on "macos-intel/tap/python@3.14" => [:build, :test]
  depends_on "macos-intel/tap/python@3.15" => [:build, :test]

  depends_on "macos-intel/tap/cairo"
  depends_on "macos-intel/tap/glib"
  depends_on "macos-intel/tap/gobject-introspection"
  depends_on "macos-intel/tap/py3cairo"

  uses_from_macos "libffi"

  deny_network_access!

  def pythons
    deps.map(&:to_formula)
        .select { |f| f.name.match?(/^python@\d\.\d+$/) }
        .map { |f| f.opt_libexec/"bin/python" }
  end

  def install
    pythons.each do |python|
      xy = Language::Python.major_minor_version(python)
      builddir = "buildpy#{xy}".delete(".")
      site_packages = prefix/Language::Python.site_packages(python)

      system "meson", "setup", builddir, "-Dpycairo=enabled",
                                         "-Dpython=#{python}",
                                         "-Dpython.platlibdir=#{site_packages}",
                                         "-Dpython.purelibdir=#{site_packages}",
                                         "-Dtests=false",
                                         *std_meson_args
      system "meson", "compile", "-C", builddir, "--verbose"
      system "meson", "install", "-C", builddir
    end
  end

  test do
    Pathname("test.py").write <<~PYTHON
      import gi
      gi.require_version("GLib", "2.0")
      assert("__init__" in gi.__file__)
      from gi.repository import GLib
      assert(31 == GLib.Date.get_days_in_month(GLib.DateMonth.JANUARY, 2000))
    PYTHON

    pythons.each do |python|
      system python, "test.py"
    end
  end
end
