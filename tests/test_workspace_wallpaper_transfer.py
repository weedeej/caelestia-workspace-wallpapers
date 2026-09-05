import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


CLI = Path(__file__).parents[1] / "scripts" / "workspace-wallpaper-transfer"


class WorkspaceWallpaperTransferTest(unittest.TestCase):
    def setUp(self):
        self.temporary_home = tempfile.TemporaryDirectory()
        self.home = Path(self.temporary_home.name)
        self.image = self.home / "Pictures/Wallpapers/still #1?.jpg"
        self.video = self.home / "Videos/Wallpapers/clip.webm"
        self.optimized_video = self.home / "cache/clip-1920x1080.mp4"
        self.image.parent.mkdir(parents=True)
        self.video.parent.mkdir(parents=True)
        self.optimized_video.parent.mkdir(parents=True)
        self.image.touch()
        self.video.touch()
        self.optimized_video.touch()
        self.environment = os.environ | {
            "WORKSPACE_WALLPAPER_HOME": str(self.home)
        }

    def tearDown(self):
        self.temporary_home.cleanup()

    @property
    def config_path(self):
        return self.home / ".config/caelestia/workspace-wallpapers.json"

    def run_cli(self, *arguments, check=True):
        return subprocess.run(
            [CLI, *arguments],
            env=self.environment,
            check=check,
            capture_output=True,
            text=True,
        )

    def read_config(self):
        return json.loads(self.config_path.read_text(encoding="utf-8"))

    def test_mutations_and_bundle_round_trip(self):
        self.run_cli("set-default", str(self.image))
        self.run_cli("set", "2", "__CAELESTIA_RANDOM__")
        self.run_cli(
            "set-video", "3", str(self.video), "12.5", "5",
            str(self.optimized_video), "1920", "1080",
        )
        self.run_cli("set-video", "4", str(self.video), "0", "5")
        self.run_cli("set-show-workspace-number", "true")
        self.run_cli("set-workspace-number-position", "bottom-right")

        config = self.read_config()
        self.assertTrue(config["showWorkspaceNumber"])
        self.assertEqual(config["workspaceNumberPosition"], "bottom-right")
        self.assertEqual(config["default"], str(self.image))
        self.assertEqual(config["workspaces"]["2"], "__CAELESTIA_RANDOM__")
        self.assertEqual(config["workspaces"]["3"]["path"], str(self.video))
        self.assertEqual(config["workspaces"]["3"]["themeFrame"], 12.5)
        self.assertEqual(
            config["workspaces"]["3"]["optimized"],
            {
                "path": str(self.optimized_video),
                "width": 1920,
                "height": 1080,
            },
        )

        self.run_cli("export-json", str(self.home / "exported"))
        self.run_cli("export-zip", str(self.home / "bundle"))
        self.assertTrue((self.home / "exported.json").is_file())
        self.assertTrue((self.home / "bundle.zip").is_file())

        self.run_cli("clear", "3")
        self.assertNotIn("3", self.read_config()["workspaces"])
        self.run_cli("import-zip", str(self.home / "bundle.zip"))
        self.assertEqual(self.read_config()["workspaces"]["3"]["themeFrame"], 12.5)
        self.assertNotIn("optimized", self.read_config()["workspaces"]["3"])

        self.run_cli(
            "set-optimized", str(self.video), str(self.optimized_video),
            "1920", "1080",
        )
        self.assertEqual(
            self.read_config()["workspaces"]["3"]["optimized"],
            {
                "path": str(self.optimized_video),
                "width": 1920,
                "height": 1080,
            },
        )
        self.assertEqual(
            self.read_config()["workspaces"]["4"]["optimized"],
            self.read_config()["workspaces"]["3"]["optimized"],
        )

    def test_failed_mutation_does_not_change_config(self):
        self.run_cli("set-default", str(self.image))
        before = hashlib.sha256(self.config_path.read_bytes()).digest()

        result = self.run_cli(
            "set-default", str(self.home / "missing.jpg"), check=False
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(
            hashlib.sha256(self.config_path.read_bytes()).digest(), before
        )

    def test_show_workspace_number_requires_boolean(self):
        result = self.run_cli(
            "set-show-workspace-number", "yes", check=False
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.config_path.exists())

    def test_workspace_number_position_requires_known_position(self):
        result = self.run_cli(
            "set-workspace-number-position", "middle", check=False
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.config_path.exists())


if __name__ == "__main__":
    unittest.main()
