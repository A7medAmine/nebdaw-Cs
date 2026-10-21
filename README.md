# Python Dev — VS Code profile

One file, `python-dev.code-profile`, holding settings, snippets and extensions for Python and C development, plus a setup script that installs Python and common libraries.

## 1. Set up Python

The setup script installs Python 3 if it is missing, adds it to PATH, installs libraries and the VS Code Python extensions. It asks before each library group.

**Windows:** double-click `setup.bat`.

**Linux / macOS:**

```sh
bash setup.sh
```

Options: `--yes` / `-Yes` accepts the defaults without asking, `--all` / `-All` installs every group.

| Group | Libraries | Default |
|---|---|---|
| core | numpy, pandas, matplotlib, requests, rich, pillow, python-dotenv, tqdm, ipython | yes |
| data | scipy, scikit-learn, seaborn, jupyterlab, openpyxl | no |
| web | flask, fastapi, uvicorn, httpx, beautifulsoup4 | no |
| dev | pytest, ruff, mypy | yes |

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
