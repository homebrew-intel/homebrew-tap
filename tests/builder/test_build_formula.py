import json
import os
import signal
import subprocess
import tempfile
import time
import unittest
from pathlib import Path

from tests.builder.fakes import FakeBin

SCRIPT = Path(__file__).resolve().parents[2] / "scripts" / "builder" / "build-formula.sh"
TAP = "macos-intel/tap"
ROOT_URL = "https://github.com/macos-intel/homebrew-tap/releases/download/lz4-1.10.0"
ASSET = "lz4-1.10.0.sequoia.bottle.tar.gz"
BOTTLE_JSON = "lz4--1.10.0.sequoia.bottle.json"
INFO = ["brew", "info", "--json=v2", "--installed", "lz4"]
BUILD = ["brew", "install", "--build-bottle", "--include-test", f"{TAP}/lz4"]
UNINSTALL = ["brew", "uninstall", "--ignore-dependencies", "lz4"]
RESTORE_CORE = ["brew", "install", "lz4"]
RESTORE_TAP = ["brew", "install", f"{TAP}/lz4"]
POSTINSTALL = ["brew", "postinstall", f"{TAP}/lz4"]
TEST = ["brew", "test", f"{TAP}/lz4"]
PREFIX = ["brew", "--prefix"]
DEPS = ["brew", "deps", "--include-test", f"{TAP}/lz4"]
SAFEGUARDS = {
    "HOMEBREW_NO_AUTO_UPDATE": "1",
    "HOMEBREW_NO_AUTOREMOVE": "1",
    "HOMEBREW_NO_INSTALL_CLEANUP": "1",
    "HOMEBREW_NO_INSTALL_UPGRADE": "1",
    "HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK": "1",
}


MARKER = "  # bottle block: written by brew pr-pull"
BLOCK = '  bottle do\n    sha256 cellar: :any, sequoia: "abc"\n  end\n'
FORMULA_WITHOUT_BLOCK = f'class Lz4 < Formula\n  license "BSD-2-Clause"\n\n{MARKER}\n\n  def install\n  end\nend\n'


def installed_from(tap: str) -> str:
    formula = {"name": "lz4", "tap": tap, "installed": [{"version": "1.10.0"}]}
    return json.dumps({"formulae": [formula], "casks": []})


class BuildFormulaCase(unittest.TestCase):
    """Fake brew, out-dir and builder cache for build-formula.sh; holds no tests."""

    def setUp(self):
        self.fake = self.enterContext(FakeBin())
        out = tempfile.TemporaryDirectory()
        self.addCleanup(out.cleanup)
        self.out = Path(out.name).resolve()
        cache = tempfile.TemporaryDirectory()
        self.addCleanup(cache.cleanup)
        self.cache = Path(cache.name)
        self.marker = self.cache / "pending-restore"
        self.formula = self.out / "lz4.rb"
        self.formula.write_text(FORMULA_WITHOUT_BLOCK, encoding="utf-8")
        self.fake.respond("brew", "formula", f"{TAP}/lz4", stdout=f"{self.formula}\n")

    def installed(self, tap: str) -> None:
        self.fake.respond(*INFO, stdout=installed_from(tap))

    def argv(self, name: str = "lz4", version: str = "1.10.0") -> list[str]:
        return ["bash", str(SCRIPT), name, version, str(self.out)]

    def environment(self) -> dict[str, str]:
        return {**self.fake.environment(), "BUILDER_CACHE": str(self.cache)}

    def run_script(self, name: str = "lz4", version: str = "1.10.0") -> subprocess.CompletedProcess:
        env = self.environment()
        return subprocess.run(self.argv(name, version), env=env, capture_output=True, text=True, check=False)

    def wait_for_call(self, argv: list[str]) -> None:
        deadline = time.monotonic() + 10
        while argv not in self.fake.argvs():
            if time.monotonic() > deadline:
                self.fail(f"{argv} was never called")
            time.sleep(0.05)

    def bottle(self) -> list[str]:
        return ["brew", "bottle", "--json", f"--root-url={ROOT_URL}", f"{TAP}/lz4"]

    def merge(self) -> list[str]:
        return ["brew", "bottle", "--merge", "--write", "--no-commit", str(self.out / BOTTLE_JSON)]


class BuildFormulaTest(BuildFormulaCase):
    def test_happy_path_call_order(self):
        self.installed("homebrew/core")
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.fake.argvs(),
            [
                INFO,
                ["brew", "uninstall", "--ignore-dependencies", "lz4"],
                BUILD,
                self.bottle(),
                POSTINSTALL,
                DEPS,
                PREFIX,
                TEST,
                self.merge(),
                ["brew", "formula", f"{TAP}/lz4"],
            ],
        )
        self.assertEqual(self.fake.calls()[3]["cwd"], str(self.out))
        self.assertTrue((self.out / ASSET).is_file())
        self.assertFalse((self.out / "lz4--1.10.0.sequoia.bottle.tar.gz").exists())
        self.assertFalse(self.marker.exists())

    def test_bottle_block_brew_wrote_elsewhere_moves_to_the_marker(self):
        self.installed("homebrew/core")
        self.formula.write_text(
            FORMULA_WITHOUT_BLOCK.replace("\n\n" + MARKER, "\n\n" + BLOCK + "\n" + MARKER), encoding="utf-8"
        )
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(f"{MARKER}\n{BLOCK}", self.formula.read_text(encoding="utf-8"))

    def test_never_calls_github(self):
        self.fake.fail("gh")
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([argv for argv in self.fake.argvs() if argv[0] == "gh"], [])

    def test_merge_failure_restores_tap_keg(self):
        self.installed(TAP)
        self.fake.fail("brew", "bottle", "--merge")
        result = self.run_script()
        self.assertEqual(result.returncode, 1)
        self.assertEqual(self.fake.argvs()[-3:], [self.merge(), UNINSTALL, RESTORE_TAP])
        self.assertFalse(self.marker.exists())

    def test_test_failure_merges_no_bottle_block(self):
        self.installed("homebrew/core")
        self.fake.fail(*TEST)
        result = self.run_script()
        self.assertEqual(result.returncode, 1)
        argvs = self.fake.argvs()
        self.assertLess(argvs.index(POSTINSTALL), argvs.index(TEST))
        self.assertNotIn(self.merge(), argvs)
        self.assertEqual(argvs[-2:], [UNINSTALL, RESTORE_CORE])
        self.assertEqual(self.formula.read_text(encoding="utf-8"), FORMULA_WITHOUT_BLOCK)

    def test_build_failure_restores_previous_keg(self):
        self.installed("homebrew/core")
        self.fake.fail(*BUILD)
        result = self.run_script()
        self.assertEqual(result.returncode, 1)
        argvs = self.fake.argvs()
        self.assertEqual(argvs[-2:], [UNINSTALL, RESTORE_CORE])
        self.assertNotIn(TEST, argvs)

    def test_failed_tap_restore_falls_back_to_core(self):
        self.installed(TAP)
        self.fake.fail(*BUILD)
        self.fake.fail(*RESTORE_TAP)
        result = self.run_script()
        self.assertEqual(result.returncode, 1)
        self.assertEqual(self.fake.argvs()[-3:], [UNINSTALL, RESTORE_TAP, RESTORE_CORE])
        self.assertIn("falling back", result.stderr)

    def test_not_installed_removes_half_built_keg_without_restore(self):
        self.fake.respond(*INFO, stdout="Error: No such keg: /usr/local/Cellar/lz4\n", exit_code=1)
        self.fake.fail(*TEST)
        result = self.run_script()
        self.assertEqual(result.returncode, 1)
        self.assertEqual(self.fake.argvs(), [INFO, BUILD, self.bottle(), POSTINSTALL, DEPS, PREFIX, TEST, UNINSTALL])

    def test_signals_cannot_interrupt_the_restore(self):
        self.installed("homebrew/core")
        self.fake.respond(*BUILD, sleep=1)
        self.fake.respond(*RESTORE_CORE, sleep=1)
        # Like a cancelled Actions job: SIGINT, then SIGTERM, to the whole group.
        env = self.environment()
        process = subprocess.Popen(self.argv(), env=env, stderr=subprocess.DEVNULL, start_new_session=True)
        self.wait_for_call(BUILD)
        os.killpg(process.pid, signal.SIGINT)
        self.wait_for_call(RESTORE_CORE)
        os.killpg(process.pid, signal.SIGTERM)
        self.assertNotEqual(process.wait(timeout=20), 0)
        self.assertEqual(self.fake.argvs()[-2:], [UNINSTALL, RESTORE_CORE])
        self.assertEqual(self.fake.finished()[-1], RESTORE_CORE)

    def test_signal_to_the_script_alone_stops_brew_then_restores(self):
        # The runner signals the processes it tracks, and brew drops the
        # variable it tracks them by: the script must stop brew itself.
        self.installed("homebrew/core")
        self.fake.respond(*BUILD, sleep=30)
        process = subprocess.Popen(self.argv(), env=self.environment(), stderr=subprocess.DEVNULL)
        self.wait_for_call(BUILD)
        brew_pid = self.cache / "brew-pid"
        self.assertRegex(brew_pid.read_text(encoding="utf-8"), r"^[0-9]+ install\n$")
        process.send_signal(signal.SIGTERM)
        self.assertEqual(process.wait(timeout=20), 143)
        self.assertNotIn(BUILD, self.fake.finished())
        self.assertEqual(self.fake.argvs()[-2:], [UNINSTALL, RESTORE_CORE])
        self.assertEqual(self.fake.finished()[-1], RESTORE_CORE)
        self.assertFalse(brew_pid.exists())

    def test_versioned_name_asset_is_url_decoded(self):
        self.fake.respond("brew", "formula", f"{TAP}/python@3.12", stdout=f"{self.formula}\n")
        result = self.run_script("python@3.12", "3.12.7")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.out / "python@3.12--3.12.7.sequoia.bottle.tar.gz").exists())
        self.assertTrue((self.out / "python@3.12-3.12.7.sequoia.bottle.tar.gz").is_file())

    def test_empty_installed_list_skips_uninstall(self):
        self.fake.respond(*INFO, stdout=json.dumps({"formulae": [], "casks": []}))
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.fake.argvs()[1], BUILD)

    def test_safeguard_env_is_set(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        for call in self.fake.calls():
            if call["argv"][0] == "brew":
                self.assertEqual({key: call["env"].get(key) for key in SAFEGUARDS}, SAFEGUARDS)

    def test_rejects_bad_arguments(self):
        argv = ["bash", str(SCRIPT), "../lz4", "1.10.0", str(self.out)]
        result = subprocess.run(argv, env=self.environment(), capture_output=True, text=True, check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.fake.argvs(), [])

    def test_pending_restore_marker_lives_while_the_keg_is_missing(self):
        self.installed(TAP)
        self.fake.respond(*BUILD, sleep=1)
        process = subprocess.Popen(self.argv(), env=self.environment(), stderr=subprocess.DEVNULL)
        self.wait_for_call(BUILD)
        self.assertEqual(self.marker.read_text(encoding="utf-8"), f"{TAP}/lz4\n")
        self.assertEqual(process.wait(timeout=20), 0)
        self.assertFalse(self.marker.exists())

    def test_pending_restore_marker_removed_after_restore(self):
        self.installed("homebrew/core")
        self.fake.fail(*BUILD)
        self.assertEqual(self.run_script().returncode, 1)
        self.assertEqual(self.fake.argvs()[-1], RESTORE_CORE)
        self.assertFalse(self.marker.exists())

    def test_pending_restore_marker_kept_when_restore_fails(self):
        self.installed(TAP)
        self.fake.fail(*BUILD)
        self.fake.fail(*RESTORE_TAP)
        self.fake.fail(*RESTORE_CORE)
        result = self.run_script()
        self.assertEqual(result.returncode, 1)
        self.assertEqual(self.marker.read_text(encoding="utf-8"), f"{TAP}/lz4\n")
        self.assertIn("reinstall it by hand", result.stderr)

    def test_no_marker_when_nothing_was_installed(self):
        self.fake.respond(*INFO, stdout=json.dumps({"formulae": [], "casks": []}))
        self.fake.fail(*BUILD)
        self.assertEqual(self.run_script().returncode, 1)
        self.assertFalse(self.marker.exists())

    def test_refuses_while_another_restore_is_pending(self):
        self.installed("homebrew/core")
        self.marker.write_text("zstd\n", encoding="utf-8")
        result = self.run_script()
        self.assertEqual(result.returncode, 1)
        self.assertIn("zstd is still uninstalled", result.stderr)
        self.assertEqual(self.marker.read_text(encoding="utf-8"), "zstd\n")
        self.assertNotIn(UNINSTALL, self.fake.argvs())
