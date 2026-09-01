import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).parents[1]
INSTALL = ROOT / "install.sh"
UNINSTALL = ROOT / "uninstall.sh"
REQUIRED_COMMANDS = (
    "qs", "caelestia", "jq", "python3", "ffmpeg", "ffprobe", "hyprctl",
    "mpvpaper", "flock", "setsid",
)


class InstallTest(unittest.TestCase):
    def setUp(self):
        self.temporary_home = tempfile.TemporaryDirectory()
        self.home = Path(self.temporary_home.name)
        self.bin = self.home / "bin"
        self.bin.mkdir()
        for command in REQUIRED_COMMANDS:
            stub = self.bin / command
            stub.write_text("#!/usr/bin/env sh\nexit 0\n", encoding="utf-8")
            stub.chmod(0o755)
        self.environment = os.environ | {
            "HOME": str(self.home),
            "PATH": f"{self.bin}:{os.environ['PATH']}",
        }

    def tearDown(self):
        self.temporary_home.cleanup()

    def run_script(self, script):
        return subprocess.run(
            [script], env=self.environment, check=True,
            capture_output=True, text=True,
        )

    def test_install_and_uninstall_complete_runtime(self):
        self.run_script(INSTALL)

        installed_root = (
            self.home / ".config/quickshell/workspace-wallpapers"
        )
        source_files = {
            path.relative_to(ROOT / "quickshell")
            for suffix in ("*.qml", "*.js")
            for path in (ROOT / "quickshell").rglob(suffix)
        }
        installed_files = {
            path.relative_to(installed_root)
            for suffix in ("*.qml", "*.js")
            for path in installed_root.rglob(suffix)
        }
        self.assertEqual(installed_files, source_files)

        scripts = self.home / ".config/caelestia/scripts"
        for name in (
            "workspace-wallpaper", "workspace-wallpaper-ipc",
            "workspace-wallpaper-media", "workspace-wallpaper-transfer",
            "workspace_wallpaper_transfer_lib.py",
        ):
            self.assertTrue((scripts / name).is_file(), name)
        self.assertTrue((
            self.home / ".local/share/applications/workspace-wallpapers.desktop"
        ).is_file())
        self.assertTrue((
            self.home / ".config/caelestia/workspace-wallpapers.json"
        ).is_file())

        stale_files = [
            installed_root / "app/RetiredComponent.qml",
            installed_root / "app/retired-helper.js",
        ]
        for stale in stale_files:
            stale.touch()
        config = self.home / ".config/caelestia/workspace-wallpapers.json"
        config.write_text('{"default": "preserved", "workspaces": {}}\n')
        self.run_script(INSTALL)
        for stale in stale_files:
            self.assertFalse(stale.exists())
        self.assertEqual(
            config.read_text(),
            '{"default": "preserved", "workspaces": {}}\n',
        )

        unrelated = installed_root / "app/user-note.txt"
        unrelated.touch()
        self.run_script(UNINSTALL)
        self.assertTrue(unrelated.is_file())
        self.assertFalse((installed_root / "shell.qml").exists())
        self.assertFalse(any((installed_root / "app").glob("*.qml")))
        self.assertFalse(any((installed_root / "app").glob("*.js")))
        for name in (
            "workspace-wallpaper", "workspace-wallpaper-ipc",
            "workspace-wallpaper-media", "workspace-wallpaper-transfer",
            "workspace_wallpaper_transfer_lib.py",
        ):
            self.assertFalse((scripts / name).exists(), name)
        self.assertTrue(config.is_file())


if __name__ == "__main__":
    unittest.main()
