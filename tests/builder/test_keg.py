import os
import signal
import subprocess
import tempfile
import time
import unittest
from pathlib import Path

KEG = Path(__file__).resolve().parents[2] / "scripts" / "builder" / "keg.sh"


class ReapStaleBrewTest(unittest.TestCase):
    def setUp(self):
        cache = tempfile.TemporaryDirectory()
        self.addCleanup(cache.cleanup)
        self.cache = Path(cache.name)
        self.marker = self.cache / "brew-pid"

    def stale_group(self, phase: str, seconds: int = 60) -> int:
        """A process group like one a killed job's run_brew left behind.

        Its leader exits at once, so the sleep is an orphan that init reaps,
        as on the build host: a child of this test would linger as a zombie,
        which still counts as alive to `kill -0`.
        """
        leader = subprocess.Popen(["bash", "-c", f"sleep {seconds} &"], start_new_session=True)
        leader.wait()
        self.addCleanup(self.stop, leader.pid)
        self.marker.write_text(f"{leader.pid} {phase}\n", encoding="utf-8")
        return leader.pid

    @staticmethod
    def alive(group: int) -> bool:
        try:
            os.killpg(group, 0)
        except ProcessLookupError:
            return False
        return True

    def stop(self, group: int) -> None:
        if self.alive(group):
            os.killpg(group, signal.SIGKILL)

    def assert_gone(self, group: int) -> None:
        deadline = time.monotonic() + 10
        while self.alive(group):
            if time.monotonic() > deadline:
                self.fail(f"process group {group} is still alive")
            time.sleep(0.1)

    def reap(self, wait: str = "1200") -> subprocess.CompletedProcess:
        script = f'log() {{ echo "$*" >&2; }}; source "{KEG}"; reap_stale_brew'
        env = {**os.environ, "BUILDER_CACHE": str(self.cache), "BUILDER_STALE_WAIT": wait}
        return subprocess.run(["bash", "-c", script], env=env, capture_output=True, text=True, check=False, timeout=60)

    def test_no_marker_is_a_no_op(self):
        result = self.reap()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")

    def test_stale_install_is_stopped_at_once(self):
        group = self.stale_group("install")
        started = time.monotonic()
        result = self.reap()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertLess(time.monotonic() - started, 10)
        self.assert_gone(group)
        self.assertIn("stopping brew left by a previous job", result.stderr)
        self.assertFalse(self.marker.exists())

    def test_stale_restore_is_left_to_finish(self):
        group = self.stale_group("restore", seconds=2)
        result = self.reap()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assert_gone(group)
        self.assertIn("waiting for a previous job's brew restore", result.stderr)
        self.assertNotIn("stopping", result.stderr)
        self.assertFalse(self.marker.exists())

    def test_stale_restore_is_stopped_after_the_wait(self):
        group = self.stale_group("restore")
        result = self.reap(wait="5")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assert_gone(group)
        self.assertIn("stopping brew left by a previous job", result.stderr)

    def test_dead_group_only_removes_the_marker(self):
        process = subprocess.Popen(["true"], start_new_session=True)
        process.wait()
        self.marker.write_text(f"{process.pid} install\n", encoding="utf-8")
        result = self.reap()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertFalse(self.marker.exists())

    def test_invalid_marker_is_removed_without_signalling(self):
        self.marker.write_text("1 install\n", encoding="utf-8")
        result = self.reap()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.marker.exists())


if __name__ == "__main__":
    unittest.main()
