---
name: update-vscode-profile
description: Change the nebdaw VS Code profile (python-dev.code-profile) - settings, snippets, extensions or theme - without leaking personal data. Use when asked to add an extension, a snippet, change a setting or the default theme.
---

# Update the VS Code profile

`python-dev.code-profile` is what the setup applies to the student's VS Code (through `apply_profile.py`), and what students can also import by hand. The setup installs the extensions listed in it, so **extensions go here, never in the setup scripts**. Extensions marked `"disabled": true` are not installed by the setup.

## The file format

It's a JSON object whose values are themselves JSON **strings**:

```json
{
  "name": "Python Dev",
  "icon": "...",
  "settings": "{\"settings\":\"{\\n  \\\"editor.fontSize\\\": 16, ...}\"}",
  "snippets": "{\"snippets\":{\"python.code-snippets\":\"{...}\",\"c.code-snippets\":\"{...}\"}}",
  "extensions": "[{\"identifier\":{\"id\":\"ms-python.python\"},\"displayName\":\"Python\"}, ...]"
}
```

Don't edit the escaped strings by hand. Either use VS Code (preferred for people), or decode, change and re-encode with a script.

## Way 1: in VS Code (for people)

1. **Profiles: Import Profile...** → pick `python-dev.code-profile`.
2. Make the change with that profile active.
3. **Profiles: Export Profile...** → overwrite `python-dev.code-profile`.
4. Do the privacy check below. VS Code exports more than you'd expect.

## Way 2: with a script (for agents)

```python
import json

path = "python-dev.code-profile"
with open(path, encoding="utf-8") as f:
    profile = json.load(f)

extensions = json.loads(profile["extensions"])
# Add an extension. Use the exact ID from the Marketplace page.
if not any(e["identifier"]["id"] == "usernamehw.errorlens" for e in extensions):
    extensions.append({"identifier": {"id": "usernamehw.errorlens"}, "displayName": "Error Lens"})
profile["extensions"] = json.dumps(extensions)

outer = json.loads(profile["settings"])
settings = json.loads(outer["settings"])        # settings are nested one level deeper
settings["editor.rulers"] = [88]
outer["settings"] = json.dumps(settings, indent=4)
profile["settings"] = json.dumps(outer)

with open(path, "w", encoding="utf-8", newline="\n") as f:
    json.dump(profile, f, ensure_ascii=False)
```

Snippets work the same way: `json.loads(profile["snippets"])["snippets"]["python.code-snippets"]` is the snippet file as a string.

Before you write the file, print the decoded value to check how it's laid out. If the structure differs from the example above, follow the file, not the example.

## Rules

- **Extensions:** must exist on the VS Code Marketplace and be free. Prefer well-known publishers. Mark optional ones `"disabled": true` rather than removing what students already have.
- **Snippets:** every snippet needs a `"scope"` (`"python"`, `"c"`) so it only shows in that language. Update the snippet tables in `README.md`.
- **Settings:** keep them beginner-friendly. Don't turn on strict type checking or settings that flood a beginner with warnings.
- **Theme:** if you change the default theme, update "Changing the theme" in `README.md`.
- **Fonts:** if you change `editor.fontFamily`, update the font list in both setup scripts (`$Fonts` / `FONTS`) so the setup installs the new font, and the fonts line in `README.md`.

## Privacy check (must pass before committing)

- No `globalState` key at the top level.
- No usernames, emails, home-folder paths (`C:\\Users\\name`, `/home/name`, `/Users/name`), SSH hosts, IP addresses or tokens anywhere in the file.

The whole file is one line, so print only the matches:

```sh
grep -oEi '.{40}(globalState|[a-z0-9._+-]+@[a-z0-9-]+\.[a-z]{2,}|users[\\/]+[a-z]+|/home/[a-z]+|token|ssh).{20}' python-dev.code-profile
```

Look at every hit and remove it unless it's clearly harmless. The `ms-vscode-remote.remote-ssh` extension IDs are expected. CI runs a similar check.

## Done when

- The file is valid JSON and every string value decodes as JSON.
- The privacy check is clean, the README matches, and CI is green.
- The commit is `feat: add Error Lens to the profile` or similar.
