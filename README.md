# Python Dev — VS Code profile

One file, `python-dev.code-profile`, holding settings, snippets and extensions for Python and C development.

## Install

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

## Editing

Edit settings and snippets inside VS Code with this profile active, then `Ctrl+Shift+P` → **Profiles: Export Profile...** and overwrite `python-dev.code-profile`.
