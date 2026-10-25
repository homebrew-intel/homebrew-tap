import unittest

from transform import (
    BOTTLE_MARKER,
    CORE_PATCHES,
    TAP,
    TransformError,
    apply_bottle,
    bottle_blocks,
    core_patch_paths,
    drop_official_only,
    extract_bottle_block,
    header,
    mark_bottle_block,
    move_bottle_to_marker,
    order_dependencies,
    parse_header,
    qualify_dependencies,
    render_body,
    strip_bottle_block,
)

SHA = "0123456789abcdef0123456789abcdef01234567"

BOTTLE = (
    '  bottle do\n    sha256 cellar: :any, arm64_sequoia: "aaa"\n    sha256 cellar: :any, sonoma:        "bbb"\n  end\n'
)

FORMULA = (
    "class Lz4 < Formula\n"
    '  desc "Extremely Fast Compression algorithm"\n'
    '  url "https://example.com/lz4.tar.gz"\n'
    '  license "BSD-2-Clause"\n'
    "\n"
    "  livecheck do\n"
    "    url :stable\n"
    "  end\n"
    "\n" + BOTTLE + "\n"
    '  depends_on "z3"\n'
    "\n"
    "  def install\n"
    '    system "make" do\n'
    "      puts 1\n"
    "    end\n"
    "  end\n"
    "end\n"
)


class HeaderTest(unittest.TestCase):
    def test_header_round_trips(self):
        text = header(SHA, "lz4")
        self.assertEqual(
            text,
            f"# Generated from Homebrew/homebrew-core@{SHA} by scripts/tap/render.py; do not edit.\n"
            "# Hand-written changes belong in patches/lz4.patch.\n",
        )
        self.assertEqual(parse_header(text + "x"), SHA)

    def test_missing_header_raises(self):
        with self.assertRaises(TransformError):
            parse_header(FORMULA)

    def test_non_sha_commit_is_rejected(self):
        for commit in ("--upload-pack=x", SHA[:7], SHA.upper(), SHA + "0"):
            with self.subTest(commit=commit), self.assertRaises(TransformError):
                parse_header(header(commit, "lz4"))


class MarkBottleTest(unittest.TestCase):
    def test_marks_bottle_block(self):
        marked = mark_bottle_block(FORMULA)
        self.assertEqual(marked, FORMULA.replace(BOTTLE, BOTTLE_MARKER + "\n"))
        self.assertIn('    system "make" do\n      puts 1\n    end\n  end\nend\n', marked)

    def test_no_bottle_block_raises_when_required(self):
        with self.assertRaises(TransformError):
            mark_bottle_block("class A < Formula\nend\n")

    def test_no_bottle_block_unchanged_when_optional(self):
        text = "class A < Formula\nend\n"
        self.assertEqual(mark_bottle_block(text, required=False), text)

    def test_two_bottle_blocks_raise(self):
        with self.assertRaises(TransformError):
            mark_bottle_block(FORMULA + BOTTLE)

    def test_unterminated_block_raises(self):
        with self.assertRaises(TransformError):
            mark_bottle_block("  bottle do\n    sha256 x\n")


class QualifyTest(unittest.TestCase):
    def test_qualifies_only_tap_names(self):
        text = (
            'depends_on "z3"\n'
            '  depends_on "z3" => :build # why\n'
            '  depends_on "llvm" => [:build, :test]\n'
            "  on_macos do\n"
            '    depends_on "z3" if OS.mac?\n'
            "  end\n"
            '  depends_on "llvm@21"\n'
            '  depends_on "zstd"\n'
            '  uses_from_macos "z3"\n'
            f'  depends_on "{TAP}/z3"\n'
        )
        expected = (
            f'depends_on "{TAP}/z3"\n'
            f'  depends_on "{TAP}/z3" => :build # why\n'
            f'  depends_on "{TAP}/llvm" => [:build, :test]\n'
            "  on_macos do\n"
            f'    depends_on "{TAP}/z3" if OS.mac?\n'
            "  end\n"
            '  depends_on "llvm@21"\n'
            '  depends_on "zstd"\n'
            '  uses_from_macos "z3"\n'
            f'  depends_on "{TAP}/z3"\n'
        )
        self.assertEqual(qualify_dependencies(text, {"z3", "llvm"}), expected)

    def test_qualifies_special_names(self):
        text = 'depends_on "python@3.15"\ndepends_on "gtk+3"\ndepends_on "pythonx3.15"\n'
        expected = f'depends_on "{TAP}/python@3.15"\ndepends_on "{TAP}/gtk+3"\ndepends_on "pythonx3.15"\n'
        self.assertEqual(qualify_dependencies(text, {"python@3.15", "gtk+3"}), expected)

    def test_empty_tap_names_is_identity(self):
        self.assertEqual(qualify_dependencies(FORMULA, set()), FORMULA)


class MoveBottleTest(unittest.TestCase):
    BLOCK = '  bottle do\n    sha256 cellar: :any, sequoia: "abc"\n  end\n'

    def test_moves_a_block_brew_wrote_elsewhere_after_the_marker(self):
        text = '  license "MIT"\n\n' + self.BLOCK + f"\n  livecheck do\n  end\n\n{BOTTLE_MARKER}\n\n  def install\n"
        expected = f'  license "MIT"\n\n  livecheck do\n  end\n\n{BOTTLE_MARKER}\n' + self.BLOCK + "\n  def install\n"
        self.assertEqual(move_bottle_to_marker(text), expected)

    def test_a_block_already_next_to_the_marker_is_kept(self):
        text = f"{BOTTLE_MARKER}\n" + self.BLOCK + "\n  def install\n"
        self.assertEqual(move_bottle_to_marker(text), text)

    def test_without_a_block_is_identity(self):
        text = f"{BOTTLE_MARKER}\n\n  def install\n"
        self.assertEqual(move_bottle_to_marker(text), text)


class CorePatchTest(unittest.TestCase):
    def test_render_body_points_core_patch_files_into_the_tap(self):
        source = FORMULA.replace("  bottle do", '  patch do\n    file "Patches/z3/fix.diff"\n  end\n\n  bottle do', 1)
        body = render_body(source, name="x", commit=SHA, tap_names=set())
        self.assertIn(f'    file "{CORE_PATCHES}/z3/fix.diff"\n', body)
        self.assertEqual(core_patch_paths(body), ["z3/fix.diff"])

    def test_formula_without_core_patches_lists_none(self):
        self.assertEqual(core_patch_paths(FORMULA), [])


class OfficialOnlyTest(unittest.TestCase):
    def test_drops_no_autobump_and_one_surrounding_blank_line(self):
        text = '  end\n\n  no_autobump! because: :incompatible_version_format\n\n  depends_on "a"\n'
        self.assertEqual(drop_official_only(text), '  end\n\n  depends_on "a"\n')

    def test_without_no_autobump_is_identity(self):
        self.assertEqual(drop_official_only(FORMULA), FORMULA)

    def test_render_body_drops_no_autobump(self):
        source = FORMULA.replace("  bottle do", "  no_autobump! because: :requires_manual_review\n\n  bottle do", 1)
        self.assertNotIn("no_autobump!", render_body(source, name="x", commit=SHA, tap_names=set()))


class OrderTest(unittest.TestCase):
    def test_sorts_a_run_by_full_name_as_brew_style_does(self):
        text = f'  depends_on "{TAP}/libevent"\n  depends_on "ncurses"\n  depends_on "{TAP}/utf8proc"\n'
        expected = f'  depends_on "{TAP}/libevent"\n  depends_on "{TAP}/utf8proc"\n  depends_on "ncurses"\n'
        self.assertEqual(order_dependencies(text), expected)

    def test_groups_build_test_normal_recommended_optional(self):
        text = (
            '  depends_on "a" => :optional\n'
            '  depends_on "b" => :recommended\n'
            '  depends_on "c"\n'
            '  depends_on "d" => :test\n'
            '  depends_on "e" => [:build, :test] # why\n'
            '  depends_on "f" => :build\n'
        )
        expected = (
            '  depends_on "e" => [:build, :test] # why\n'
            '  depends_on "f" => :build\n'
            '  depends_on "d" => :test\n'
            '  depends_on "c"\n'
            '  depends_on "b" => :recommended\n'
            '  depends_on "a" => :optional\n'
        )
        self.assertEqual(order_dependencies(text), expected)

    def test_runs_end_at_other_lines_and_indentation(self):
        text = (
            '  depends_on "z"\n'
            "  on_linux do\n"
            '    depends_on "b"\n'
            '    depends_on "a"\n'
            "  end\n"
            '  depends_on "y"\n'
            '  depends_on "x"\n'
        )
        expected = (
            '  depends_on "z"\n'
            "  on_linux do\n"
            '    depends_on "a"\n'
            '    depends_on "b"\n'
            "  end\n"
            '  depends_on "x"\n'
            '  depends_on "y"\n'
        )
        self.assertEqual(order_dependencies(text), expected)

    def test_conditional_runs_are_left_alone(self):
        text = '  depends_on "b" if build.with? "x"\n  depends_on "a"\n'
        self.assertEqual(order_dependencies(text), text)

    def test_render_body_orders_qualified_dependencies(self):
        source = FORMULA.replace("  bottle do", '  depends_on "pkgconf"\n  depends_on "lz4"\n\n  bottle do', 1)
        body = render_body(source, name="x", commit=SHA, tap_names={"pkgconf"})
        self.assertIn(f'  depends_on "{TAP}/pkgconf"\n  depends_on "lz4"\n', body)


class BottleBlockTest(unittest.TestCase):
    def setUp(self):
        self.body = render_body(FORMULA, name="lz4", commit=SHA, tap_names=set())

    def test_render_body_keeps_marker(self):
        self.assertTrue(self.body.startswith(header(SHA, "lz4") + "class Lz4"))
        self.assertIn(BOTTLE_MARKER + "\n", self.body)
        self.assertNotIn("bottle do", self.body)

    def test_apply_bottle_inserts_block_after_marker(self):
        applied = apply_bottle(self.body, BOTTLE)
        self.assertIn(BOTTLE_MARKER + "\n" + BOTTLE + "\n", applied)

    def test_apply_bottle_none_is_identity(self):
        self.assertEqual(apply_bottle(self.body, None), self.body)

    def test_apply_bottle_without_marker_raises(self):
        with self.assertRaises(TransformError):
            apply_bottle(FORMULA, BOTTLE)

    def test_extract_round_trips(self):
        applied = apply_bottle(self.body, BOTTLE)
        self.assertEqual(extract_bottle_block(applied), BOTTLE)
        self.assertEqual(apply_bottle(self.body, extract_bottle_block(applied)), applied)
        self.assertIsNone(extract_bottle_block(self.body))

    def test_bottle_blocks_lists_every_top_level_block(self):
        twice = apply_bottle(self.body, BOTTLE) + BOTTLE
        self.assertEqual(bottle_blocks(twice), [BOTTLE, BOTTLE])
        self.assertEqual(bottle_blocks(self.body), [])

    def test_strip_round_trip(self):
        self.assertEqual(strip_bottle_block(apply_bottle(self.body, BOTTLE)), self.body)

    def test_strip_block_placed_elsewhere(self):
        moved = self.body.replace(BOTTLE_MARKER + "\n", BOTTLE + "\n" + BOTTLE_MARKER + "\n")
        stripped = strip_bottle_block(moved)
        self.assertEqual(stripped, self.body)
        self.assertNotIn("\n\n\n", stripped)


if __name__ == "__main__":
    unittest.main()
