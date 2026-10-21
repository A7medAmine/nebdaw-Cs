---
name: troubleshoot-setup
description: Diagnose and fix a failed or confusing nebdaw setup run on a student's PC, starting from python-dev-setup.log. Use when someone says the setup failed, python is not found, pip or a library didn't install, or VS Code doesn't see Python.
---

# Troubleshoot a setup run

The person asking is usually a beginner. Explain each step in plain words, give commands they can paste, and say which terminal to paste them into (PowerShell on Windows, Terminal on macOS and Linux).

## 1. Get the log first

Every run writes a full log. Ask for it before guessing:

- Windows: `%TEMP%\python-dev-setup.log`. Open it with `notepad $env:TEMP\python-dev-setup.log` in PowerShell.
- Linux: `/tmp/python-dev-setup.log`. macOS: `$TMPDIR/python-dev-setup.log`. Show it with `cat "${TMPDIR:-/tmp}/python-dev-setup.log"`.

Each command in the log starts with `>` (Windows) or `$` (Linux, macOS), followed by its output. The failing command is usually the last one before the error. Also ask which line the screen showed with `[x]` or `✘`.

## 2. Match the symptom

| Screen or symptom | Likely cause | Fix |
|---|---|---|
| `Could not get the library list from .../requirements.txt` | No internet, or GitHub is blocked on that network | Check the connection, or download the repo as a ZIP and run `setup.bat` / `bash setup.sh` from it |
| `winget failed, downloading the installer from python.org instead` | winget missing or broken. This is only a warning. | Nothing to do if the next step succeeds |
| `Download failed: ...` (Windows) | No internet, proxy, or antivirus blocking python.org | Retry on another network, or install Python from python.org and tick **Add python.exe to PATH**, then re-run |
| `Python was installed but could not be found` | The current terminal has the old PATH | Close the terminal, open a new one, run the setup again |
| `'python' currently opens X, not Y` (Windows) | Another Python (often the Microsoft Store stub in `WindowsApps`) is earlier in PATH | Settings → Apps → Advanced app settings → **App execution aliases** → turn off `python.exe` and `python3.exe`; or move the right folder up in Environment Variables |
| `Python folder is read-only for you` (Windows) | Python is installed for all users | Fine; libraries go to the user folder. Only an issue if `python` later can't import them |
| A library shows `[x]` / `✘` in step 4 | Slow or dropped connection, or no wheel for that Python version | Re-run the setup, which is safe. If it keeps failing, look in the log for `No matching distribution` or `error: Microsoft Visual C++` (no wheel, so a newer or older Python is needed) |
| `Checking that numpy works` failed | Broken or partial install, or a mismatched Python | `python -m pip install --force-reinstall numpy` (Windows) or `~/.python-dev/bin/python -m pip install --force-reinstall numpy` |
| `sudo authentication failed` (Linux) | Wrong password, or the user isn't in the sudo group | Retype the password; on a lab PC ask the admin |
| `No supported package manager found` (Linux) | Unusual distro | Install Python 3.10+ with the distro's tools, then re-run |
| `Python's venv module is missing` | Distro splits venv out | Install `python3-venv` (or the distro's equivalent) and re-run |
| `Unsupported system. On Windows run setup.bat instead.` | `setup.sh` was run in Git Bash or MSYS on Windows | Use the PowerShell one-liner instead |
| Setup finished, but `python` isn't found in a new terminal | PATH change not picked up | Sign out and back in (Windows), or open a new terminal / run `source ~/.profile` (Linux, macOS) |
| `VS Code      not found` in the summary | VS Code wasn't installed, or `code` isn't on PATH (macOS: VS Code not in Applications) | Install VS Code, then run the setup again |
| Theme or font didn't change in VS Code | VS Code was open during the setup | Restart VS Code. The old settings are in `settings.json.nebdaw-backup` in the VS Code user folder |
| An extension is listed as failed | Slow connection, or the Marketplace was unreachable | Run the setup again, or `code --install-extension <ID>` |
| VS Code doesn't find the libraries | VS Code is using a different interpreter | `Ctrl+Shift+P` → **Python: Select Interpreter** → pick the one from the setup summary (`Location` on Windows, `~/.python-dev/bin/python` on Linux and macOS) |
| `irm ... \| iex` shows a red execution-policy or TLS error | Old Windows 10 PowerShell settings | Download the repo ZIP and double-click `setup.bat` instead |

## 3. Confirm the fix

Ask them to open a new terminal and run:

```sh
python -c "import sys, numpy; print(sys.executable, numpy.__version__)"
```

On Linux and macOS, `python` should point into `~/.python-dev/bin/`.

## 4. If it's a bug in nebdaw

If the cause is a problem in the scripts and not on the PC, help them open an issue at https://github.com/A7medAmine/nebdaw-Cs/issues/new/choose with the system name and version, what the screen said, and the log. Before they post the log, ask them to remove their username or anything private from it.

## Don't

- Don't tell them to disable the antivirus, run random scripts from the internet, or `sudo pip install`.
- Don't delete their existing Python installs to "start clean" unless they understand and agree.
