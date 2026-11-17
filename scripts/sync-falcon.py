"""Update Falcon's compatibility text from the latest stable release notes."""

import json
import re
import sys
from pathlib import Path


def replace_once(text, pattern, replacement):
    updated, count = re.subn(pattern, lambda _: replacement, text)
    if count != 1:
        raise SystemExit(f"Expected one compatibility field matching {pattern}, found {count}")
    return updated


release = json.load(sys.stdin)
match = re.search(
    r"^\*\*Falcon [^\n]+ for Minecraft: Bedrock Edition ([\d.]+) \(protocol (\d+)\)\*\*",
    release["body"] or "",
    re.MULTILINE,
)
if match is None:
    raise SystemExit("The Falcon release notes are missing the Bedrock version and protocol")

version, protocol = match.groups()
egg = Path("egg-falcon.json")
readme = Path("README.md")
egg_text = replace_once(
    egg.read_text(),
    r"targeting protocol \d+ \([\d.]+\)",
    f"targeting protocol {protocol} ({version})",
)
readme_text = replace_once(
    readme.read_text(),
    r"\(protocol \d+, Minecraft [\d.]+\)",
    f"(protocol {protocol}, Minecraft {version})",
)
json.loads(egg_text)
egg.write_text(egg_text)
readme.write_text(readme_text)
