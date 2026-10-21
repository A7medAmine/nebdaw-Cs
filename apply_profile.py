"""Apply python-dev.code-profile to the user's own VS Code.

VS Code has no command to import a .code-profile file, so the setup scripts call this
helper instead. It needs only the Python standard library.

    python apply_profile.py PROFILE extensions
        Print the IDs of the profile's enabled extensions, one per line.

    python apply_profile.py PROFILE settings USER_DIR
        Merge the profile's settings into USER_DIR/settings.json and its snippets into
        USER_DIR/snippets. The profile wins on keys it sets; everything else the user
        has is kept. Each file is backed up once, before the first change, as
        <name>.nebdaw-backup.
"""

import json
import re
import shutil
import sys
from pathlib import Path


def load_profile(path):
    with open(path, encoding="utf-8-sig") as f:
        return json.load(f)


# settings.json and snippet files are JSON with comments and trailing commas.
def parse_jsonc(text):
    out = []
    i, n = 0, len(text)
    while i < n:
        if text[i] == '"':
            j = i + 1
            while j < n and text[j] != '"':
                j += 2 if text[j] == "\\" else 1
            out.append(text[i : j + 1])
            i = j + 1
        elif text.startswith("//", i):
            end = text.find("\n", i)
            i = n if end < 0 else end
        elif text.startswith("/*", i):
            end = text.find("*/", i + 2)
            i = n if end < 0 else end + 2
        else:
            out.append(text[i])
            i += 1
    clean = re.sub(r",(\s*[}\]])", r"\1", "".join(out))
    return json.loads(clean) if clean.strip() else {}


def merge_file(path, new):
    """Merge the dict `new` into the JSON file at `path`. Returns True if it changed."""
    old = {}
    if path.exists():
        old = parse_jsonc(path.read_text(encoding="utf-8-sig"))
        if not isinstance(old, dict):
            raise ValueError(f"{path} is not a JSON object")
    merged = dict(old)
    for key, value in new.items():
        if isinstance(value, dict) and isinstance(merged.get(key), dict):
            merged[key] = {**merged[key], **value}
        else:
            merged[key] = value
    if merged == old and path.exists():
        return False
    backup = path.with_name(path.name + ".nebdaw-backup")
    if path.exists() and not backup.exists():
        shutil.copy2(path, backup)
        print(f"Backed up {path} to {backup.name}")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(merged, indent=4, ensure_ascii=False) + "\n", encoding="utf-8")
    return True


def list_extensions(profile):
    for ext in json.loads(profile["extensions"]):
        if not ext.get("disabled"):
            print(ext["identifier"]["id"])


def apply_settings(profile, user_dir):
    settings = json.loads(json.loads(profile["settings"])["settings"])
    path = user_dir / "settings.json"
    print(f"{'Updated' if merge_file(path, settings) else 'No change to'} {path}")
    snippets = json.loads(profile["snippets"])["snippets"]
    for name, text in snippets.items():
        path = user_dir / "snippets" / name
        print(f"{'Updated' if merge_file(path, parse_jsonc(text)) else 'No change to'} {path}")


def main(argv):
    # The output goes to the setup log; don't crash on a path the console code page can't show.
    sys.stdout.reconfigure(errors="replace")
    if len(argv) == 3 and argv[2] == "extensions":
        list_extensions(load_profile(argv[1]))
    elif len(argv) == 4 and argv[2] == "settings":
        apply_settings(load_profile(argv[1]), Path(argv[3]))
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv)
