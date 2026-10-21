---
name: add-library
description: Add, remove, or turn on a Python library that the nebdaw setup installs. Use when someone asks to install pandas/matplotlib/etc. for students, enable a commented-out library group, or drop a library from the setup.
---

# Add or remove a library

The setup scripts install exactly the active lines of `requirements.txt`. Nothing else lists libraries, so this is the only file that changes for the install itself.

## Steps

1. **Open `requirements.txt`.** Libraries are grouped under comments (`# core`, `# data`, `# web`, `# dev`). An active line is a bare name like `numpy`. A disabled one starts with `# `.

2. **Make the change.**
   - Turn on a listed library: remove the `# ` in front of its line.
   - Add a new library: put it on its own line under the matching group. Use the PyPI name (`scikit-learn`, not `sklearn`). Extras are fine: `uvicorn[standard]`.
   - Remove a library: put `# ` in front of the line, or delete it.
   - Only pin a version (`numpy>=2`) if the course truly needs it. Pins break on new Python releases.

3. **Check that it installs from wheels.** Students must not need a C compiler. On https://pypi.org/project/<name>/#files, check for wheels for Windows (`win_amd64`), macOS (`macosx_*_arm64` and `x86_64`) and Linux (`manylinux`) for Python 3.10 to 3.13. If any is missing, say so and don't add it.

4. **Think about download size.** Every active library is downloaded by every student, often on a slow connection. Mention big ones (for example `jupyterlab`, `scipy`, `torch`) to the person who asked before adding them.

5. **Update the docs** if the README mentions which libraries are installed (section "1. Set up Python").

6. **CI only imports numpy.** If the new library matters as much as numpy, add it to the import checks in `.github/workflows/ci.yml` (the `python -c "import numpy; ..."` lines). Note that the import name can differ from the package name (`scikit-learn` imports as `sklearn`, `pillow` as `PIL`, `beautifulsoup4` as `bs4`, `python-dotenv` as `dotenv`).

## Don't

- Don't add package lists to `setup.ps1` or `setup.sh`.
- Don't add a prompt asking whether to install a library. The setup asks no questions.

## Done when

- `requirements.txt` has the change, the README matches, and CI is green.
- The commit message looks like `feat: install pandas by default` or `chore: stop installing jupyterlab`.
