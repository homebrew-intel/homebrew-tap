import contextlib
import io
import json
import tempfile
import unittest
import unittest.mock
from pathlib import Path

import bottles

SHA_A = "a" * 40
SHA_B = "b" * 40
LZ4_BLOCK = (
    "  bottle do\n"
    '    root_url "https://github.com/macos-intel/homebrew-tap/releases/download/lz4-1.10.0"\n'
    '    sha256 cellar: :any, sequoia: "abc"\n'
    "  end\n"
)


class BottlesTest(unittest.TestCase):
    def test_pkg_version_plain(self):
        self.assertEqual(bottles.pkg_version({"versions": {"stable": "1.10.0"}, "revision": 0}), "1.10.0")

    def test_pkg_version_revision(self):
        self.assertEqual(bottles.pkg_version({"versions": {"stable": "1.10.0"}, "revision": 2}), "1.10.0_2")

    def test_root_url_and_tag(self):
        self.assertEqual(bottles.release_tag("lz4", "1.10.0"), "lz4-1.10.0")
        self.assertEqual(
            bottles.root_url("lz4", "1.10.0"),
            "https://github.com/macos-intel/homebrew-tap/releases/download/lz4-1.10.0",
        )

    def test_bottle_release_tag(self):
        self.assertEqual(bottles.bottle_release_tag(LZ4_BLOCK), "lz4-1.10.0")
        self.assertIsNone(bottles.bottle_release_tag("  bottle do\n  end\n"))

    def test_api_core_commit_most_common(self):
        formulae = [{"tap_git_head": SHA_A}, {"tap_git_head": SHA_B}, {"tap_git_head": SHA_A}]
        self.assertEqual(bottles.api_core_commit(formulae), SHA_A)

    def test_api_core_commit_rejects_non_sha(self):
        with self.assertRaises(ValueError):
            bottles.api_core_commit([{"tap_git_head": "abc"}])

    def test_cli_root_url(self):
        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            code = bottles.main(["root-url", "lz4", "1.10.0"])
        self.assertEqual(code, 0)
        self.assertEqual(stdout.getvalue(), bottles.root_url("lz4", "1.10.0") + "\n")


class InfoVersionTest(unittest.TestCase):
    def info(self, *formulae: tuple[str, str, int]) -> str:
        entries = [{"name": n, "versions": {"stable": v}, "revision": r} for n, v, r in formulae]
        return json.dumps({"formulae": entries, "casks": []})

    def run_cli(self, name: str, document: str) -> tuple[int, str]:
        out = io.StringIO()
        with contextlib.redirect_stdout(out), unittest.mock.patch("sys.stdin", io.StringIO(document)):
            try:
                status = bottles.main(["info-version", name])
            except SystemExit as error:
                status = error.code
        return status, out.getvalue()

    def test_prints_the_pkg_version_brew_describes(self):
        self.assertEqual(self.run_cli("simdutf", self.info(("simdutf", "9.3.3", 0))), (0, "9.3.3\n"))
        self.assertEqual(self.run_cli("llvm", self.info(("llvm", "19.1.0", 2))), (0, "19.1.0_2\n"))

    def test_refuses_another_formula(self):
        status, out = self.run_cli("z3", self.info(("zstd", "1.5.6", 0)))
        self.assertNotEqual(status, 0)
        self.assertEqual(out, "")

    def test_refuses_several_formulae(self):
        status, _ = self.run_cli("z3", self.info(("z3", "4.13.0", 0), ("z3", "4.13.0", 0)))
        self.assertNotEqual(status, 0)


class PlaceTest(unittest.TestCase):
    def test_cli_place_moves_the_block_next_to_the_marker(self):
        marker = "  # bottle block: written by brew pr-pull"
        text = f'class A < Formula\n  license "MIT"\n\n{LZ4_BLOCK}\n{marker}\n\n  def install\n  end\nend\n'
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "a.rb"
            path.write_text(text, encoding="utf-8")
            self.assertEqual(bottles.main(["place", str(path)]), 0)
            self.assertIn(f"{marker}\n{LZ4_BLOCK}", path.read_text(encoding="utf-8"))
