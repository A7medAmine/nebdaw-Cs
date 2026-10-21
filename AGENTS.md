# AGENTS.md

Instructions for AI coding agents (Claude Code, Codex, Copilot, Cursor, Gemini and others) working in this repository. Human contributors should read [CONTRIBUTING.md](CONTRIBUTING.md); everything here agrees with it.

## What this project is

nebdaw sets up a CS student's PC in one step: it installs Python, adds it to PATH, installs the course libraries, and ships a VS Code profile. The users are beginners on old laptops and slow connections, mostly in Algeria. Every change should keep the setup simple, quiet and safe to run twice.

## Files

| File | Purpose |
|---|---|
| `setup.ps1` | Windows setup. Runs as a file (`setup.bat`) or piped (`irm ... \| iex`). |
| `setup.bat` | Double-click launcher for `setup.ps1`. |
| `setup.sh` | Linux and macOS setup. Runs as a file (`bash setup.sh`) or piped (`curl ... \| bash`). |
| `requirements.txt` | The only list of libraries. Both scripts read it; when piped they download it from GitHub. |
| `python-dev.code-profile` | VS Code profile: settings, snippets and extensions. JSON whose values are JSON strings. |
| `.github/workflows/ci.yml` | Lint, profile privacy check, and real setup runs (piped and from the repo) on Windows, Ubuntu and macOS. |
| `docs/using-ai.md` | Guide for students who code with an AI assistant. |
| `.claude/skills/*/SKILL.md` | Step-by-step guides for common tasks. Any agent can read them, not just Claude. |

## Task guides

Before doing one of these tasks, read the matching guide and follow it:

- Add, remove or turn on a library: [.claude/skills/add-library/SKILL.md](.claude/skills/add-library/SKILL.md)
- Change `setup.ps1` or `setup.sh`: [.claude/skills/edit-setup-scripts/SKILL.md](.claude/skills/edit-setup-scripts/SKILL.md)
- Change the VS Code profile (settings, snippets, extensions, theme): [.claude/skills/update-vscode-profile/SKILL.md](.claude/skills/update-vscode-profile/SKILL.md)
- Help someone whose setup failed: [.claude/skills/troubleshoot-setup/SKILL.md](.claude/skills/troubleshoot-setup/SKILL.md)

## Rules

**Both scripts**

- `setup.ps1` and `setup.sh` stay in step: same four steps (Python, pip / environment, PATH, libraries), same messages where possible. Change both, or say in the PR why only one needs it.
- No questions. The scripts run start to finish on their own. `--yes` / `-Yes` / `--all` / `-All` are accepted only so old commands still work.
- Libraries come only from `requirements.txt`. Never hard-code a package list in a script.
- VS Code extensions belong in the profile, never in the scripts.
- Safe to run twice: no duplicate PATH entries, no broken existing install.
- Command output goes to the log file (`python-dev-setup.log` in the temp folder); the screen shows short status lines only.
- No new dependencies. The scripts must work on a fresh system.

**`setup.ps1` (must work in Windows PowerShell 5.1)**

- ASCII only. No `✔`, no smart quotes. CI rejects non-ASCII.
- No PowerShell 7 syntax: no `??`, `?.`, ternaries or `&&` / `||`.
- Everything lives inside the top-level `& { ... }` block so a piped run leaves nothing behind in the user's session. Don't add code outside it, don't use `$script:` or `$global:` variables, and don't add a `param()` block.
- Never call `exit` directly. Use `Stop-Setup "message"`; the main `try` / `catch` exits with code 1 only when run as a file, so a piped run doesn't close the user's window.
- Use `$ScriptDir`, not `$PSScriptRoot`, and handle it being empty (piped run).
- The here-string closing `'@` must stay at column 0.
- Write the user PATH through the registry as `Add-UserPath` does.

**`setup.sh` (must work in Bash 3.2, the macOS version)**

- No associative arrays, `mapfile`, `${var,,}` or other Bash 4 features.
- Runs with `set -euo pipefail`: use `${arr[*]-}` for arrays that may be empty.
- All steps run inside `main()`, called on the last line, so a piped or half-downloaded script never runs partly. Keep new step code inside `main`.
- When piped, stdin is the script itself. Don't read from stdin; read from `/dev/tty` if you truly must (only `sudo -v` does).
- `SCRIPT_DIR` is empty when piped. Don't use `$0` or `dirname "$0"` for paths.
- Must pass `shellcheck --severity=warning setup.sh`.

**VS Code profile**

- Never commit personal data: no `globalState`, no usernames, emails, home-folder paths, SSH hosts or tokens. CI checks for some of this, not all.

## Checks to run

```sh
bash -n setup.sh
shellcheck --severity=warning setup.sh
```

```powershell
$errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile("$PWD\setup.ps1", [ref]$null, [ref]$errors)
$errors.Count   # must be 0
```

To run the setup for real, use a VM, Windows Sandbox, WSL or CI. The scripts change PATH and shell startup files on the machine they run on, so don't run them on someone's PC unless they asked you to.

## Commits and pull requests

- Commit messages: `type: short imperative summary`, with type one of `feat`, `fix`, `docs`, `ci`, `refactor`, `chore`.
- Update `README.md` when behaviour, libraries or snippets change.
- In the PR, say which system you tested on and that an AI agent helped. A human must review and test the change before it is merged.
