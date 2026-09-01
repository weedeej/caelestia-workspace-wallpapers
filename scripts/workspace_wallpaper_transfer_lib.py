"""Configuration persistence and portable bundle operations."""

from __future__ import annotations

import copy
import json
import os
import shutil
import tempfile
import zipfile
from pathlib import Path, PurePosixPath
from typing import Any

HOME = Path(os.environ.get("WORKSPACE_WALLPAPER_HOME", Path.home()))
CONFIG = HOME / ".config/caelestia/workspace-wallpapers.json"
IMAGE_DIR = HOME / "Pictures/Wallpapers"
VIDEO_DIR = HOME / "Videos/Wallpapers"
RANDOM_VALUE = "__CAELESTIA_RANDOM__"


def read_config(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"Unable to read JSON config: {error}") from error
    if not isinstance(value, dict):
        raise ValueError("Config must be a JSON object.")
    workspaces = value.get("workspaces", {})
    if not isinstance(workspaces, dict):
        raise ValueError("Config 'workspaces' must be a JSON object.")
    value.setdefault("default", "")
    value["workspaces"] = workspaces
    return value


def write_json_atomic(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.", dir=path.parent
    )
    temporary = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
            json.dump(value, stream, indent=2, ensure_ascii=False)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def entry_path(entry: Any) -> tuple[str, str] | None:
    if isinstance(entry, str):
        if not entry or entry == RANDOM_VALUE:
            return None
        return "image", entry
    if isinstance(entry, dict) and isinstance(entry.get("path"), str):
        kind = "video" if entry.get("type") == "video" else "image"
        return kind, entry["path"]
    return None


def entries(config: dict[str, Any]):
    yield "default", config.get("default", "")
    for workspace, entry in config.get("workspaces", {}).items():
        yield str(workspace), entry


def set_entry_path(entry: Any, path: str) -> Any:
    if isinstance(entry, str):
        return path
    updated = copy.deepcopy(entry)
    updated["path"] = path
    updated.pop("optimized", None)
    return updated


def unique_archive_name(directory: str, filename: str, used: set[str]) -> str:
    candidate = f"{directory}/{filename}"
    stem, suffix = Path(filename).stem, Path(filename).suffix
    counter = 2
    while candidate.casefold() in used:
        candidate = f"{directory}/{stem}-{counter}{suffix}"
        counter += 1
    used.add(candidate.casefold())
    return candidate


def export_json(destination: Path) -> None:
    config = read_config(CONFIG)
    if destination.suffix.lower() != ".json":
        destination = destination.with_suffix(".json")
    write_json_atomic(destination, config)
    print(f"Exported config to {destination}")


def export_zip(destination: Path) -> None:
    config = read_config(CONFIG)
    portable = copy.deepcopy(config)
    assets: list[tuple[Path, str]] = []
    archived_sources: dict[tuple[str, str], str] = {}
    used_names: set[str] = set()
    for key, entry in entries(config):
        media = entry_path(entry)
        if media is None:
            continue
        kind, raw_path = media
        source = Path(raw_path).expanduser()
        if not source.is_file():
            raise ValueError(f"Referenced wallpaper does not exist: {source}")
        source_key = kind, str(source.resolve())
        archive_path = archived_sources.get(source_key)
        if archive_path is None:
            directory = "Videos/Wallpapers" if kind == "video" else "Pictures/Wallpapers"
            archive_path = unique_archive_name(directory, source.name, used_names)
            archived_sources[source_key] = archive_path
            assets.append((source, archive_path))
        if key == "default":
            portable["default"] = set_entry_path(portable["default"], archive_path)
        else:
            portable["workspaces"][key] = set_entry_path(
                portable["workspaces"][key], archive_path
            )
    if destination.suffix.lower() != ".zip":
        destination = destination.with_suffix(".zip")
    destination.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{destination.name}.", dir=destination.parent
    )
    os.close(descriptor)
    temporary = Path(temporary_name)
    try:
        with zipfile.ZipFile(
            temporary, "w", compression=zipfile.ZIP_DEFLATED
        ) as archive:
            archive.writestr(
                "workspace-wallpapers.json",
                json.dumps(portable, indent=2, ensure_ascii=False) + "\n",
            )
            for source, archive_path in assets:
                archive.write(source, archive_path)
        os.replace(temporary, destination)
    finally:
        temporary.unlink(missing_ok=True)
    print(f"Exported config and {len(assets)} media file(s) to {destination}")


def asset_location(member: str) -> tuple[str, str] | None:
    parts = PurePosixPath(member).parts
    lowered = [part.casefold() for part in parts]
    for index in range(len(parts) - 2):
        pair = lowered[index:index + 2]
        if pair == ["pictures", "wallpapers"]:
            return "image", parts[-1]
        if pair == ["videos", "wallpapers"]:
            return "video", parts[-1]
    return None


def import_zip(source: Path) -> None:
    if not source.is_file():
        raise ValueError(f"ZIP file does not exist: {source}")
    with zipfile.ZipFile(source) as archive:
        files = [item for item in archive.infolist() if not item.is_dir()]
        configs = [item for item in files if
            PurePosixPath(item.filename).name.casefold() ==
            "workspace-wallpapers.json"]
        if not configs:
            configs = [item for item in files
                if item.filename.lower().endswith(".json")]
        if len(configs) != 1:
            raise ValueError(
                "ZIP must contain exactly one workspace wallpaper JSON config."
            )
        try:
            config = json.loads(archive.read(configs[0]).decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as error:
            raise ValueError(f"ZIP contains an invalid JSON config: {error}") from error
        with tempfile.TemporaryDirectory(
            prefix="workspace-wallpapers-import-"
        ) as temporary:
            temp_root = Path(temporary)
            assets: list[tuple[str, str, Path]] = []
            by_archive_path: dict[str, tuple[str, str]] = {}
            by_basename: dict[tuple[str, str], list[str]] = {}
            for index, item in enumerate(files):
                location = asset_location(item.filename)
                if location is None:
                    continue
                kind, filename = location
                if not filename or filename in {".", ".."}:
                    continue
                if ((item.external_attr >> 16) & 0o170000) == 0o120000:
                    raise ValueError(
                        f"ZIP contains an unsupported symlink: {item.filename}"
                    )
                extracted = temp_root / f"asset-{index}"
                with archive.open(item) as incoming, extracted.open("wb") as outgoing:
                    shutil.copyfileobj(incoming, outgoing)
                assets.append((kind, filename, extracted))
                by_archive_path[item.filename.casefold()] = kind, filename
                by_basename.setdefault((kind, filename.casefold()), []).append(filename)
            if not isinstance(config, dict) or not isinstance(
                config.get("workspaces", {}), dict
            ):
                raise ValueError(
                    "Config must contain a JSON object with a 'workspaces' object."
                )
            config.setdefault("default", "")
            config.setdefault("workspaces", {})
            for key, entry in list(entries(config)):
                media = entry_path(entry)
                if media is None:
                    continue
                kind, raw_path = media
                normalized = raw_path.replace("\\", "/").lstrip("./").casefold()
                mapped = by_archive_path.get(normalized)
                if mapped is None:
                    matches = by_basename.get(
                        (kind, PurePosixPath(raw_path).name.casefold()), []
                    )
                    if len(matches) == 1:
                        mapped = kind, matches[0]
                if mapped is None:
                    continue
                target_dir = VIDEO_DIR if mapped[0] == "video" else IMAGE_DIR
                target_path = str(target_dir / mapped[1])
                if key == "default":
                    config["default"] = set_entry_path(config["default"], target_path)
                else:
                    config["workspaces"][key] = set_entry_path(
                        config["workspaces"][key], target_path
                    )
            IMAGE_DIR.mkdir(parents=True, exist_ok=True)
            VIDEO_DIR.mkdir(parents=True, exist_ok=True)
            for kind, filename, extracted in assets:
                target_dir = VIDEO_DIR if kind == "video" else IMAGE_DIR
                shutil.copy2(extracted, target_dir / filename)
            write_json_atomic(CONFIG, config)
    print(f"Imported config and {len(assets)} media file(s) from {source}")


def import_json(source: Path) -> None:
    config = read_config(source)
    write_json_atomic(CONFIG, config)
    print(f"Imported config from {source}")
