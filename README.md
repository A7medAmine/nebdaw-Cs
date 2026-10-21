# nebdaw

[![CI](https://github.com/A7medAmine/nebdaw-Cs/actions/workflows/ci.yml/badge.svg)](https://github.com/A7medAmine/nebdaw-Cs/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

*Nebdaw* means "let's start" in Darija. It sets up a CS student's PC in one step: it installs Python and the libraries used in class, adds Python to PATH and gives you a ready-made VS Code profile with themes, formatters and snippets.

It is made for CS students in Algeria and is open to contributions from everyone.

Works on **Windows**, **Linux** and **macOS**.

## 1. Set up Python

The setup script installs Python 3 if it is missing, adds it to PATH, installs numpy without asking, and the VS Code Python extensions.

**Windows:** double-click `setup.bat`.

**Linux / macOS:**

```sh
bash setup.sh
```

Options: `--yes` / `-Yes` runs without any questions (it also skips the VS Code extensions prompt).

For now it installs only **numpy**. The other library groups are listed in the scripts and will be turned on when the course needs them.

How it works on each system:

- **Windows:** installs Python with `winget` (or the python.org installer), adds Python and its `Scripts` folder to your user PATH, and installs the libraries into that Python.
- **Linux:** installs Python with your package manager (apt, dnf, yum, pacman, zypper or apk). It asks for your password only when it needs to install system packages.
- **macOS:** installs Python with Homebrew, or the python.org installer if Homebrew is missing.
- **Linux and macOS:** the libraries go into a shared environment at `~/.python-dev`, which is added to PATH in your shell startup files. Modern Linux and Homebrew block installing libraries into the system Python, so a separate environment is needed.

Open a new terminal when it finishes. A full log is written to `python-dev-setup.log` in your temp folder.

## 2. Install the profile

1. Open VS Code.
2. `Ctrl+Shift+P` → **Profiles: Import Profile...**
3. **Select File...** → pick `python-dev.code-profile`.
4. Click **Create Profile**. VS Code installs the extensions automatically.

Fonts needed: **Cascadia Mono** (editor) and **Aljazeera** (Arabic fallback).

## What's inside

- Dracula theme, Material icons, font `Cascadia Mono, 'aljazeera', monospace` size 16.
- Format on save: Ruff for Python, Prettier for HTML/JS, C/C++ tools for C.
- Pylance basic type checking, ruler at 88 columns.
- Code Runner runs in the terminal, so `input()` and `scanf` work.

## Changing the theme

The profile uses **Dracula Theme** for colors and **Material Icon Theme** for file icons.

### Quick way

1. Press `Ctrl+K` then `Ctrl+T` (macOS: `Cmd+K` then `Cmd+T`).
2. Use the arrow keys to preview themes live.
3. Press `Enter` to keep one, or `Esc` to go back.

Themes already included in the profile:

| Theme | From |
|---|---|
| `Dracula Theme` (current) | Dracula Official |
| `Ayu Dark`, `Ayu Mirage`, `Ayu Light` | Ayu |
| `Material Palenight` | Material Palenight Theme |
| `Default Dark Modern`, `Default Light Modern`, `Default Dark+` | Built into VS Code |

### Install a new theme

1. Open the Extensions view (`Ctrl+Shift+X`).
2. Search `@category:themes`, or a theme name such as `One Dark Pro` or `GitHub Theme`.
3. Click **Install**, then pick it with `Ctrl+K` `Ctrl+T`.

### Change the file icons

`Ctrl+Shift+P` → **Preferences: File Icon Theme**, then pick one (for example `Material Icon Theme`, `Seti` or `Minimal`).

### Change it in settings.json

`Ctrl+Shift+P` → **Preferences: Open User Settings (JSON)** and edit these lines:

```jsonc
"workbench.colorTheme": "Ayu Mirage",
"workbench.iconTheme": "material-icon-theme",
```

### Follow the system light/dark mode

Add these lines to switch themes automatically when Windows or macOS changes between light and dark:

```jsonc
"window.autoDetectColorScheme": true,
"workbench.preferredDarkColorTheme": "Dracula Theme",
"workbench.preferredLightColorTheme": "Ayu Light",
```

### Save the new theme into the profile file

The steps above change only your own VS Code. To share the new theme, export the profile again (see [Editing](#editing)).

## Python snippets

Type the prefix, press `Tab`.

| Prefix | Inserts |
|---|---|
| `ifmain` | `if __name__ == "__main__":` |
| `pyscript` | Script with `main()` |
| `deft` | Typed function |
| `asyncmain` | `asyncio.run(main())` |
| `dc` | `@dataclass` |
| `clsi` | Class with `__init__` / `__repr__` |
| `tryex` | `try` / `except` |
| `fread` / `fwrite` | Read / write a text file |
| `jload` / `jdump` | Load / save JSON |
| `pglob` | Loop files with `pathlib` |
| `argp` | `argparse` skeleton |
| `logset` | Logging setup |
| `timeit` | Timer decorator |
| `pd` | `print(f"{var=}")` |
| `lc` / `dcomp` | List / dict comprehension |
| `fenum` | `for i, x in enumerate(...)` |
| `fastio` | Fast input template |
| `ptest` / `pparam` | pytest test / parametrized test |
| `rget` | `requests.get` |

## C snippets

`startc` (main template), `printf`, `scanf`, `redc` (red/reset color), `elseb` (else block).

## Recommended Python extensions

The profile already includes Python, Pylance, Python Debugger and Ruff. These are worth adding:

| Extension | ID | Why |
|---|---|---|
| Jupyter | `ms-toolsai.jupyter` | Run notebooks and `# %%` cells |
| Data Wrangler | `ms-toolsai.datawrangler` | Browse and clean pandas DataFrames |
| Python Environments | `ms-python.vscode-python-envs` | Create and switch virtual environments |
| Error Lens | `usernamehw.errorlens` | Errors shown on the line itself |
| autoDocstring | `njpwerner.autodocstring` | Docstring templates from function signatures |
| Mypy Type Checker | `ms-python.mypy-type-checker` | Strict type checking |
| Python Indent | `kevinrose.vsc-python-indent` | Correct indentation when pressing Enter |
| Even Better TOML | `tamasfe.even-better-toml` | `pyproject.toml` support |

Install one from a terminal with `code --install-extension <ID>`.

## Editing

Edit settings and snippets inside VS Code with this profile active, then `Ctrl+Shift+P` → **Profiles: Export Profile...** and overwrite `python-dev.code-profile`.

## Contributing

Everyone is welcome, whether you're fixing a typo or adding a new feature. You can also help without writing code: test the setup on your PC, report bugs, suggest libraries or translate the docs.

- Read the [contributing guide](CONTRIBUTING.md) to get started.
- Look for issues labelled [`good first issue`](https://github.com/A7medAmine/nebdaw-Cs/labels/good%20first%20issue).
- Please follow the [code of conduct](CODE_OF_CONDUCT.md).
- Report security problems privately, as explained in [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE): free to use, change and share.
