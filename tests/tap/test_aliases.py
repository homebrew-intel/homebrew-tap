import drift
from core_source import read_core_aliases

from tests.tap.fixtures import RenderTestCase, git


class AliasesTest(RenderTestCase):
    """Core aliases of tap formulae are mirrored into Aliases/ and drift-checked."""

    def setUp(self):
        super().setUp()
        self.core_alias("z3-solver", "Formula/z/z3.rb")
        self.core_alias("llvm@1", "Formula/l/llvm.rb")
        self.core_alias("lz4-alias", "Formula/l/lz4.rb")
        git(self.core, "add", "-A")
        git(self.core, "commit", "-q", "-m", "aliases")
        self.enable('[formula.llvm]\nkind = "generated"\n')

    def core_alias(self, alias: str, target: str) -> None:
        path = self.core / "Aliases" / alias
        path.parent.mkdir(parents=True, exist_ok=True)
        path.symlink_to(f"../{target}")

    def tap_aliases(self) -> dict[str, str]:
        directory = self.tap / "Aliases"
        return {path.name: str(path.readlink()) for path in sorted(directory.iterdir())} if directory.is_dir() else {}

    def test_reads_core_aliases_at_a_commit(self):
        head = git(self.core, "rev-parse", "HEAD")
        self.assertEqual(read_core_aliases(self.core, head), {"llvm@1": "llvm", "lz4-alias": "lz4", "z3-solver": "z3"})
        self.assertEqual(read_core_aliases(self.core, self.first), {})

    def test_render_mirrors_aliases_of_tap_formulae_only(self):
        code, _, stderr = self.run_render()
        self.assertEqual(code, 0, stderr)
        self.assertEqual(self.tap_aliases(), {"llvm@1": "../Formula/l/llvm.rb", "z3-solver": "../Formula/z/z3.rb"})
        self.assertTrue((self.tap / "Aliases/z3-solver").resolve().samefile(self.tap / "Formula/z/z3.rb"))

    def test_render_removes_a_stale_alias(self):
        stale = self.tap / "Aliases/gone"
        stale.parent.mkdir(parents=True)
        stale.symlink_to("../Formula/g/gone.rb")
        self.run_render()
        self.assertNotIn("gone", self.tap_aliases())

    def test_render_reads_aliases_at_the_header_commit(self):
        self.run_render("--core-commit", self.first)
        self.assertEqual(self.tap_aliases(), {})

    def test_drift_clean_after_render(self):
        self.run_render()
        self.assertEqual(drift.check(self.tap, self.core), [])

    def test_drift_flags_a_missing_alias(self):
        self.run_render()
        (self.tap / "Aliases/llvm@1").unlink()
        problems = drift.check(self.tap, self.core)
        self.assertEqual(len(problems), 1)
        self.assertIn("Aliases/llvm@1", problems[0])

    def test_drift_flags_an_extra_alias(self):
        self.run_render()
        (self.tap / "Aliases/clang").symlink_to("../Formula/l/llvm.rb")
        problems = drift.check(self.tap, self.core)
        self.assertEqual(len(problems), 1)
        self.assertIn("Aliases/clang", problems[0])

    def test_drift_flags_a_retargeted_alias(self):
        self.run_render()
        link = self.tap / "Aliases/llvm@1"
        link.unlink()
        link.symlink_to("../Formula/z/z3.rb")
        problems = drift.check(self.tap, self.core)
        self.assertEqual(len(problems), 1)
        self.assertIn("Aliases/llvm@1", problems[0])

    def test_drift_flags_a_regular_file(self):
        self.run_render()
        (self.tap / "Aliases/llvm@1").unlink()
        self.write(self.tap / "Aliases/llvm@1", "class Llvm\n")
        problems = drift.check(self.tap, self.core)
        self.assertEqual(len(problems), 1)
        self.assertIn("Aliases/llvm@1", problems[0])
