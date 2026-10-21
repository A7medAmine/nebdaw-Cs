---
name: edit-setup-scripts
description: Change the nebdaw setup scripts (setup.ps1 for Windows, setup.sh for Linux/macOS) safely. Use for any fix or feature in the install steps, PATH handling, messages, logging, or the one-line piped install (irm | iex, curl | bash).
---

# Edit the setup scripts

`setup.ps1` and `setup.sh` do the same job on different systems and must stay in step. Each one runs in two ways, and a change must work in both:

| | From the repo | Piped one-liner |
|---|---|---|
| Windows | `setup.bat` runs `setup.ps1` | `irm .../setup.ps1 \| iex` |
| Linux / macOS | `bash setup.sh` | `curl -fsSL .../setup.sh \| bash` |

## 1. Understand the structure first

Both scripts have the same four steps: **Checking Python**, **Preparing pip** (Windows) / **Creating the Python Dev environment** (Linux, macOS), **Adding Python to PATH**, **Installing libraries**, then a summary. Read the whole script you're changing before you edit it, and find the matching code in the other script.

Helpers to reuse instead of rewriting:

| Job | `setup.ps1` | `setup.sh` |
|---|---|---|
| Start a numbered step | `Write-Step` | `step` |
| Status lines | `Write-Ok`, `Write-Warn`, `Write-Bad`, `Write-Info` | `ok`, `warn`, `bad`, `info` |
| Stop with an error | `Stop-Setup` | `die` |
| Run a command with a spinner, output to the log | `Invoke-Spin` | `spin` |
| Run pip install | `$PipInstall` | `"${PIP_INSTALL[@]}"` |
| Admin rights | (user install, none needed) | `need_sudo`, then `$SUDO` |

## 2. Rules that break things if ignored

**`setup.ps1`, Windows PowerShell 5.1**

- ASCII characters only.
- No `??`, `?.`, ternaries, `&&` or `||`.
- All code stays inside the top-level `& { ... }` block. No `param()`, no `$script:` or `$global:` variables. A piped run must leave nothing in the user's session.
- Never call `exit`. Call `Stop-Setup`; the `catch` at the bottom exits with code 1 only for a file run (`$PSCommandPath` set). A piped `exit` would close the student's window before they can read the error.
- Use `$ScriptDir`, which is empty when piped. Anything read from the repo must have a download fallback from `$RepoUrl`, like `Get-RequirementsText`.
- Keep the closing `'@` of the here-string in `Send-EnvironmentChange` at column 0.

**`setup.sh`, Bash 3.2**

- No Bash 4 features: associative arrays, `mapfile`, `${var,,}`, `|&`.
- `set -euo pipefail` is on: expand possibly empty arrays as `${arr[*]-}`.
- Step code goes inside `main()`. Top-level code outside functions only defines settings.
- Stdin is the script when piped: never read stdin. Use `</dev/tty` for the rare interactive need (only `sudo -v` does this).
- `SCRIPT_DIR` is empty when piped; anything read from the repo needs a download fallback from `$REPO_URL`, like `requirements_text`.

**Both**

- No questions to the user.
- Safe to run twice. Check before adding PATH lines (`Test-OnPath`, `MARKER`).
- Send command output to the log through `Invoke-Spin` / `spin`.

## 3. Check your change

```sh
bash -n setup.sh
shellcheck --severity=warning setup.sh
```

```powershell
$errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile("$PWD\setup.ps1", [ref]$null, [ref]$errors)
$errors.Count   # must be 0
Select-String -Path setup.ps1 -Pattern '[^\x00-\x7F]'   # must print nothing
```

To test a real run, use a VM, Windows Sandbox or WSL, or push a branch and let CI do it. CI runs both the piped and the from-the-repo modes on Windows, Ubuntu and macOS. Don't run the scripts on someone's own machine unless they asked: they change PATH and shell startup files.

To test the piped mode by hand from a folder without the repo:

```powershell
$env:NEBDAW_URL = 'https://raw.githubusercontent.com/<owner>/nebdaw-Cs/<branch>'
Get-Content <repo>\setup.ps1 -Raw | Invoke-Expression
```

```sh
NEBDAW_URL=https://raw.githubusercontent.com/<owner>/nebdaw-Cs/<branch> bash < <repo>/setup.sh
```

## 4. Finish

- Both scripts changed, or the PR says why only one is.
- `README.md` and `AGENTS.md` updated if behaviour or rules changed.
- Commit as `fix: ...` or `feat: ...`, and name the systems you tested on in the PR.
