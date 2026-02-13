"""Parser for WoW SavedVariables .lua files."""

import re
import logging

logger = logging.getLogger("SpotifyControl.lua_parser")

try:
    from slpp import slpp as lua
    HAS_SLPP = True
except ImportError:
    HAS_SLPP = False
    logger.warning("slpp library not found. Using built-in minimal parser.")


def parse_saved_variables_file(filepath):
    """
    Parse a WoW SavedVariables .lua file and return a dict of
    {variable_name: python_value} for each top-level assignment.
    """
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    results = {}
    pattern = re.compile(r"^(\w+)\s*=\s*", re.MULTILINE)

    for match in pattern.finditer(content):
        var_name = match.group(1)
        start_pos = match.end()

        table_str = _extract_balanced_value(content, start_pos)
        if table_str is None:
            continue

        try:
            if HAS_SLPP:
                value = lua.decode(table_str)
            else:
                value = _minimal_parse(table_str)
            results[var_name] = value
        except Exception as e:
            logger.error(f"Failed to parse variable '{var_name}': {e}")

    return results


def _extract_balanced_value(content, start):
    """Extract a balanced value (table, string, number, boolean) from content."""
    i = start
    while i < len(content) and content[i] in " \t\r\n":
        i += 1

    if i >= len(content):
        return None

    if content[i] == "{":
        depth = 0
        in_string = False
        string_char = None
        j = i
        while j < len(content):
            c = content[j]
            if in_string:
                if c == "\\":
                    j += 1
                elif c == string_char:
                    in_string = False
            else:
                if c in ('"', "'"):
                    in_string = True
                    string_char = c
                elif c == "-" and j + 1 < len(content) and content[j + 1] == "-":
                    # Skip Lua comments
                    while j < len(content) and content[j] != "\n":
                        j += 1
                elif c == "{":
                    depth += 1
                elif c == "}":
                    depth -= 1
                    if depth == 0:
                        return content[i : j + 1]
            j += 1
    elif content[i] in ('"', "'"):
        quote = content[i]
        j = i + 1
        while j < len(content):
            if content[j] == "\\":
                j += 2
                continue
            if content[j] == quote:
                return content[i : j + 1]
            j += 1
    else:
        j = i
        while j < len(content) and content[j] not in ",\r\n\t }":
            j += 1
        return content[i:j].strip()

    return None


def _minimal_parse(lua_str):
    """
    Minimal Lua table parser as fallback if slpp is not installed.
    Handles simple SavedVariables structures.
    """
    s = lua_str.strip()
    if s == "nil":
        return None
    if s == "true":
        return True
    if s == "false":
        return False
    try:
        if "." in s:
            return float(s)
        return int(s)
    except ValueError:
        pass
    if (s.startswith('"') and s.endswith('"')) or (
        s.startswith("'") and s.endswith("'")
    ):
        return (
            s[1:-1]
            .replace('\\"', '"')
            .replace("\\'", "'")
            .replace("\\\\", "\\")
        )
    if s.startswith("{") and s.endswith("}"):
        # For robust parsing, install slpp
        logger.warning(
            "Table parsing without slpp is limited. Install slpp for reliability."
        )
        return {}
    return s
