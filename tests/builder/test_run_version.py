from tests.builder.run_harness import RunTest


class RenderedVersionTest(RunTest):
    """A planned formula builds at the version its render describes, not the API snapshot's."""

    def test_render_newer_than_the_api_snapshot_wins(self):
        self.configure(plan="simdutf 9.3.2_1\n", rendered={"simdutf": "9.3.3"})
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([argv[:2] for argv in self.stub_argvs("build-formula.sh")], [["simdutf", "9.3.3"]])
        (built,) = self.manifest()["built"]
        self.assertEqual(built["version"], "9.3.3")
        self.assertIn("the API snapshot has 9.3.2_1, the render has 9.3.3", result.stderr)

    def test_unreadable_render_fails_the_formula_and_skips_dependents(self):
        self.configure(plan="z3 4.13.0\nllvm 19.1.0 z3\n")
        self.fake.forget("brew", "info", "--json=v2", "macos-intel/tap/z3")
        self.fake.respond("brew", "info", "--json=v2", "macos-intel/tap/z3", stderr="Error: z3: bad\n", exit_code=1)
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.built(), [])
        manifest = self.manifest()
        self.assertEqual(manifest["failed"], [{"name": "z3", "version": "4.13.0", "log": "z3.log"}])
        self.assertEqual(self.section("skipped"), ["llvm"])
        self.assertIn("Error: z3: bad", (self.out / "logs" / "z3.log").read_text(encoding="utf-8"))
