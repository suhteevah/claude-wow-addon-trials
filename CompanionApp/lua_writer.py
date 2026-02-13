"""Generates Lua files for the SpotifyControl addon to read."""

import os
import logging
from datetime import datetime

logger = logging.getLogger("SpotifyControl.lua_writer")


def serialize_lua_value(value, indent=1):
    """Convert a Python value to its Lua literal representation."""
    tab = "\t" * indent

    if value is None:
        return "nil"
    elif isinstance(value, bool):
        return "true" if value else "false"
    elif isinstance(value, int):
        return str(value)
    elif isinstance(value, float):
        return f"{value:.3f}"
    elif isinstance(value, str):
        escaped = (
            value.replace("\\", "\\\\")
            .replace('"', '\\"')
            .replace("\n", "\\n")
            .replace("\r", "\\r")
        )
        return f'"{escaped}"'
    elif isinstance(value, dict):
        if not value:
            return "{}"
        lines = ["{"]
        for k, v in sorted(value.items(), key=lambda x: str(x[0])):
            if isinstance(k, str):
                key_str = f'["{k}"]'
            else:
                key_str = f"[{k}]"
            val_str = serialize_lua_value(v, indent + 1)
            lines.append(f"{tab}\t{key_str} = {val_str},")
        lines.append(f"{tab}}}")
        return "\n".join(lines)
    elif isinstance(value, (list, tuple)):
        if not value:
            return "{}"
        lines = ["{"]
        for item in value:
            val_str = serialize_lua_value(item, indent + 1)
            lines.append(f"{tab}\t{val_str},")
        lines.append(f"{tab}}}")
        return "\n".join(lines)
    else:
        return str(value)


def write_spotify_data(filepath, data):
    """
    Write the SpotifyControlData.lua file atomically.
    Uses write-to-temp-then-rename for atomic writes on Windows/NTFS.
    """
    now = datetime.now().isoformat(timespec="seconds")
    lua_table = serialize_lua_value(data, indent=0)

    content = (
        f"-- SpotifyControl Companion Data\n"
        f"-- Last updated: {now}\n"
        f"-- DO NOT EDIT - this file is managed by the SpotifyControl companion app\n"
        f"SpotifyControlData = {lua_table}\n"
    )

    temp_path = filepath + ".tmp"
    try:
        with open(temp_path, "w", encoding="utf-8") as f:
            f.write(content)
            f.flush()
            os.fsync(f.fileno())

        os.replace(temp_path, filepath)
        logger.debug(f"Wrote status to {filepath}")
    except OSError as e:
        logger.error(f"Failed to write {filepath}: {e}")
        try:
            os.remove(temp_path)
        except OSError:
            pass
