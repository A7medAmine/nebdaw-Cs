# Contributing to nebdaw

Thanks for helping! nebdaw exists so that CS students can go from a fresh PC to writing code in one step. Every contribution that makes that easier is welcome, whether or not you write code.

## Ways to help

- **Test it on your PC.** Run the setup on your system and [open an issue](https://github.com/A7medAmine/nebdaw-Cs/issues/new/choose) saying what worked and what didn't. Reports from old laptops, slow connections and unusual Linux distros are especially useful.
- **Report bugs.** Use the bug report template and attach the log file (see [Logs](#logs)).
- **Suggest things.** A library your course uses, a snippet you type all the time, or an extension students should have.
- **Translate.** French and Arabic versions of the README and script messages would help many students.
- **Improve the docs.** If something confused you, it will confuse the next student too.
- **Write code.** Pick an issue labelled `good first issue` or `help wanted`.

## Before you start

- For small fixes (typos, one-line bugs), just open a pull request.
- For bigger changes (a new step in the setup, a new language or toolchain), open an issue first so we can agree on the approach before you spend time on it.
- Comment on an issue to say you're working on it, so two people don't do the same work.

## Getting the code

1. Fork the repository on GitHub.
2. Clone your fork and create a branch:

   ```sh
   git clone https://github.com/<your-username>/nebdaw-Cs.git
   cd nebdaw-Cs
   git checkout -b fix-short-description
   ```

3. Make your changes, commit, push to your fork and open a pull request against `main`.

## Project layout

| File | Purpose |
|---|---|
| `setup.bat` | Double-click launcher for Windows; runs `setup.ps1` |
| `setup.ps1` | Windows setup (PowerShell) |
| `setup.sh` | Linux and macOS setup (Bash) |
| `requirements.txt` | Libraries the setup scripts install |
| `python-dev.code-profile` | VS Code profile: settings, snippets and extensions |
| `.github/workflows/ci.yml` | Checks that run on every pull request |
| `AGENTS.md`, `CLAUDE.md` | Rules for AI coding agents |
| `.claude/skills/` | Step-by-step guides for common tasks, for people and AI agents |
| `docs/using-ai.md` | Guide for students who code with an AI assistant |

## Rules for the setup scripts

`setup.ps1` and `setup.sh` must stay in step: same four steps and the same options. Each one must work both from the repo and piped from GitHub (`irm ... | iex`, `curl ... | bash`); the [edit-setup-scripts guide](.claude/skills/edit-setup-scripts/SKILL.md) explains what that means for your code. Both read the library list from `requirements.txt`. If you change one, change the other, or say in the PR why only one needs it.

**Both scripts**

- Safe to run twice. A second run must not duplicate PATH entries or break an existing install.
- No questions. The scripts run start to finish on their own.
- VS Code extensions belong in `python-dev.code-profile`, not in the scripts.
- Ask for admin rights (sudo) only for steps that need them.
- Send command output to the log file and keep the screen to short status lines.
- No new dependencies. The scripts must work on a fresh system with nothing installed.

**`setup.ps1`**

- Must work in Windows PowerShell 5.1, which ships with Windows 10 and 11. Don't use PowerShell 7-only syntax such as `??`, `?.` or ternaries.
- ASCII characters only. PowerShell 5.1 misreads UTF-8 files without a BOM, so `✔` turns into garbage.
- Write the user PATH through the registry as the existing `Add-UserPath` does, so `%VARIABLES%` in the PATH are kept.

**`setup.sh`**

- Must work in Bash 3.2, the version macOS ships with: no associative arrays, no `${var,,}`, no `mapfile`.
- Runs with `set -euo pipefail`. Check that empty arrays and unset variables are handled.
- Must pass `shellcheck --severity=warning setup.sh`.

### Adding a library

1. Add it to `requirements.txt` under the matching group, or remove the `# ` in front of its line if it is already listed. Both setup scripts read this file.
2. Check that it installs from pre-built wheels on Windows, Linux and macOS. Students shouldn't need a C compiler.
3. Keep the list short. Every library in it installs automatically, so each one costs every student download time.

## Changing the VS Code profile

1. Import `python-dev.code-profile` into VS Code (**Profiles: Import Profile...**).
2. Make your changes in VS Code with that profile active.
3. Export it (**Profiles: Export Profile...**) and overwrite `python-dev.code-profile`.
4. **Remove personal data before committing.** VS Code exports more than you'd expect. Check that the file has:
   - no `globalState` section (it contains your account names, recent commands and remote hosts);
   - no usernames, email addresses or home folder paths such as `C:\Users\yourname`;
   - no SSH hosts, IP addresses or tokens.
5. Snippets need a `"scope"` (for example `"scope": "python"`) so they only show up in the right language.
6. Update the snippet tables in `README.md` if you add or change a snippet.

## Testing your change

Every pull request runs CI. It lints both scripts, checks the profile file, and runs the full setup on Windows, Ubuntu and macOS, both piped (the way students run it) and from the repo.

Run the quick checks locally before pushing:

```sh
bash -n setup.sh
shellcheck --severity=warning setup.sh
```

```powershell
$errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile("$PWD\setup.ps1", [ref]$null, [ref]$errors)
$errors.Count   # must be 0
```

For a real run without touching your own setup, use a virtual machine, Windows Sandbox or WSL. On Linux and macOS you can also point the environment somewhere temporary:

```sh
PYDEV_HOME=/tmp/nebdaw-test bash setup.sh
```

Note that this still edits your shell startup files to add the PATH line.

### Logs

Both scripts write a full log to `python-dev-setup.log` in the temp folder:

- Windows: `%TEMP%\python-dev-setup.log`
- Linux / macOS: `/tmp/python-dev-setup.log` (or `$TMPDIR` on macOS)

## Using AI tools

You're welcome to use AI assistants and agents to contribute. The repository is set up for them: [`AGENTS.md`](AGENTS.md) holds the rules they read automatically, and [`.claude/skills/`](.claude/skills/) has task guides (adding a library, editing the scripts, updating the profile, troubleshooting). The guides are useful to read even without AI.

You stay responsible for what you submit:

- Read and understand every changed line before you open the PR.
- Test it on a real system. "The AI said it works" is not a test.
- Say in the PR that an AI helped.

## Commit messages

Short and in the imperative, with a type prefix:

```
fix: detect Python installed from the Microsoft Store
feat: add a C compiler step for Windows
docs: add French README
```

Common types: `feat`, `fix`, `docs`, `ci`, `refactor`, `chore`.

## Pull request checklist

- [ ] Both scripts updated (or the PR explains why only one is)
- [ ] Tested on at least one real system, which is named in the PR
- [ ] `README.md` updated if behaviour, libraries or snippets changed
- [ ] No personal data in the profile file
- [ ] If an AI helped, I read and tested every changed line and said so in the PR
- [ ] CI is green

## Code of conduct

This project follows the [Code of Conduct](CODE_OF_CONDUCT.md). Be kind, especially to beginners: for many students this is their first open source project.
