import tempfile
from pathlib import Path

from tests.builder.test_build_formula import (
    DEPS,
    PREFIX,
    RESTORE_CORE,
    TAP,
    TEST,
    UNINSTALL,
    BuildFormulaCase,
)

UNLINK = ["brew", "unlink", "docker-compose", "lazygit"]
RELINK = ["brew", "link", "--force", "docker-compose", "lazygit"]


class TestIsolationTest(BuildFormulaCase):
    """`brew test` sees only the formula and its runtime and test dependencies linked."""

    def setUp(self):
        super().setUp()
        prefix = tempfile.TemporaryDirectory()
        self.addCleanup(prefix.cleanup)
        self.linked = Path(prefix.name) / "var" / "homebrew" / "linked"
        self.linked.mkdir(parents=True)
        for keg in ("docker-compose", "lazygit", "lz4", "xz"):
            (self.linked / keg).mkdir()
        self.fake.respond(*PREFIX, stdout=f"{prefix.name}\n")
        self.fake.respond(*DEPS, stdout=f"{TAP}/xz\n")
        self.relink_marker = self.cache / "pending-relink"
        self.installed("homebrew/core")

    def test_unlinks_other_kegs_for_the_test_only(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        argvs = self.fake.argvs()
        self.assertEqual(argvs[argvs.index(PREFIX) + 1 : argvs.index(PREFIX) + 4], [UNLINK, TEST, RELINK])
        self.assertFalse(self.relink_marker.exists())

    def test_relinks_before_restoring_after_a_failed_test(self):
        self.fake.fail(*TEST)
        result = self.run_script()
        self.assertEqual(result.returncode, 1)
        self.assertEqual(self.fake.argvs()[-4:], [TEST, RELINK, UNINSTALL, RESTORE_CORE])
        self.assertFalse(self.relink_marker.exists())

    def test_marker_kept_when_relinking_fails(self):
        self.fake.fail(*RELINK)
        result = self.run_script()
        self.assertEqual(result.returncode, 1)
        self.assertEqual(self.relink_marker.read_text(encoding="utf-8"), "docker-compose lazygit\n")
        self.assertIn("could not relink", result.stderr)

    def test_nothing_to_unlink_skips_link_calls(self):
        for keg in ("docker-compose", "lazygit"):
            (self.linked / keg).rmdir()
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([argv for argv in self.fake.argvs() if argv[1] in ("link", "unlink")], [])

    def test_refuses_while_another_relink_is_pending(self):
        self.relink_marker.write_text("tmux\n", encoding="utf-8")
        result = self.run_script()
        self.assertEqual(result.returncode, 1)
        self.assertIn("tmux is still unlinked", result.stderr)
        self.assertNotIn(TEST, self.fake.argvs())
        self.assertEqual(self.relink_marker.read_text(encoding="utf-8"), "tmux\n")
