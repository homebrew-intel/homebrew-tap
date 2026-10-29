import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from tests.builder.fakes import FakeBin

SCRIPT = Path(__file__).resolve().parents[2] / "scripts" / "ci" / "unlink-siblings.sh"


class UnlinkSiblingsTest(unittest.TestCase):
    def setUp(self):
        self.fake = self.enterContext(FakeBin())
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.prefix = Path(directory.name).resolve()
        (self.prefix / "var" / "homebrew" / "linked").mkdir(parents=True)
        self.fake.respond("brew", "--prefix", stdout=f"{self.prefix}\n")

    def link(self, keg: str, tap: str) -> None:
        opt = self.prefix / "opt" / keg
        opt.mkdir(parents=True)
        receipt = {"source": {"tap": tap, "path": f"/x/{keg}.rb"}}
        (opt / "INSTALL_RECEIPT.json").write_text(json.dumps(receipt, indent=2), encoding="utf-8")
        (self.prefix / "var" / "homebrew" / "linked" / keg).symlink_to(opt)

    def run_script(self, *names: str) -> subprocess.CompletedProcess:
        argv = ["bash", str(SCRIPT), *names]
        return subprocess.run(argv, env=self.fake.environment(), capture_output=True, text=True, check=False)

    def unlinked(self) -> list[str]:
        return [argv[2] for argv in self.fake.argvs() if argv[:2] == ["brew", "unlink"]]

    def test_unlinks_a_core_versioned_sibling(self):
        self.link("ruby@3.3", "homebrew/core")
        result = self.run_script("ruby", "libyaml")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.unlinked(), ["ruby@3.3"])
        self.assertIn("::notice::unlinking ruby@3.3", result.stdout)

    def test_a_versioned_tap_formula_unlinks_its_core_siblings(self):
        self.link("openssl@3", "homebrew/core")
        self.link("openssl", "homebrew/core")
        result = self.run_script("openssl@4")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(sorted(self.unlinked()), ["openssl", "openssl@3"])

    def test_keeps_tap_kegs_requested_names_and_other_formulae(self):
        self.link("ruby@3.4", "macos-intel/tap")
        self.link("python@3.13", "homebrew/core")
        self.link("ruby-build", "homebrew/core")
        self.link("rubyx@1", "homebrew/core")
        result = self.run_script("ruby", "python@3.13")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.unlinked(), [])

    def test_a_failed_unlink_fails_the_script(self):
        self.link("ruby@3.3", "homebrew/core")
        self.fake.respond("brew", "unlink", "ruby@3.3", stderr="Error: nope\n", exit_code=1)
        result = self.run_script("ruby")
        self.assertNotEqual(result.returncode, 0)

    def test_refuses_a_name_that_is_not_a_formula_name(self):
        result = self.run_script("../ruby")
        self.assertEqual(result.returncode, 2)
        self.assertEqual(self.unlinked(), [])

    def test_no_names_is_a_no_op(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.fake.argvs(), [])


if __name__ == "__main__":
    unittest.main()
