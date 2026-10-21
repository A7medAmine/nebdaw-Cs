#!/usr/bin/env bash
# Python Dev setup for Linux and macOS.
# Installs Python 3, creates a shared environment at ~/.python-dev, adds it to PATH
# and installs common libraries.
#
#   bash setup.sh            interactive
#   bash setup.sh --yes      accept defaults (core + dev libraries)
#   bash setup.sh --all      install every library group
set -euo pipefail

PY_VERSION="3.13.17"   # used only for the python.org macOS installer
MIN_MINOR=10
VENV_DIR="${PYDEV_HOME:-$HOME/.python-dev}"
LOG_FILE="${TMPDIR:-/tmp}/python-dev-setup.log"
MARKER="# Added by Python Dev setup"

CORE=(numpy pandas matplotlib requests rich pillow python-dotenv tqdm ipython)
DATA=(scipy scikit-learn seaborn jupyterlab openpyxl)
WEB=(flask fastapi "uvicorn[standard]" httpx beautifulsoup4)
DEV=(pytest ruff mypy)
VSCODE_EXTENSIONS=(ms-python.python ms-python.vscode-pylance ms-python.debugpy charliermarsh.ruff)

YES=0
ALL=0
for arg in "$@"; do
  case "$arg" in
    -y|--yes) YES=1 ;;
    -a|--all) ALL=1; YES=1 ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

# ---------- look ----------
if [ -t 1 ]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GREEN=$'\033[32m'
  YELLOW=$'\033[33m'; BLUE=$'\033[34m'; CYAN=$'\033[36m'; RESET=$'\033[0m'
else
  BOLD=; DIM=; RED=; GREEN=; YELLOW=; BLUE=; CYAN=; RESET=
fi
case "${LC_ALL:-}${LC_CTYPE:-}${LANG:-}" in
  *UTF-8*|*utf8*|*UTF8*) FRAMES=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏); OK_MARK="✔"; BAD_MARK="✘"; FULL="█"; EMPTY="░" ;;
  *) FRAMES=('|' '/' '-' '\'); OK_MARK="ok"; BAD_MARK="x"; FULL="#"; EMPTY="-" ;;
esac

STEP=0
TOTAL_STEPS=5

banner() {
  printf "\n${CYAN}${BOLD}"
  printf "  +------------------------------------------+\n"
  printf "  |          Python Dev  -  Setup            |\n"
  printf "  |  Python + PATH + libraries, one command  |\n"
  printf "  +------------------------------------------+${RESET}\n"
  printf "  ${DIM}Log file: %s${RESET}\n" "$LOG_FILE"
}
step() { STEP=$((STEP + 1)); printf "\n${BOLD}${BLUE}[%d/%d]${RESET} ${BOLD}%s${RESET}\n" "$STEP" "$TOTAL_STEPS" "$1"; }
ok()   { printf "  ${GREEN}%s${RESET} %s\n" "$OK_MARK" "$1"; }
bad()  { printf "  ${RED}%s${RESET} %s\n" "$BAD_MARK" "$1"; }
info() { printf "  ${DIM}%s${RESET}\n" "$1"; }
warn() { printf "  ${YELLOW}!${RESET} %s\n" "$1"; }
die()  { bad "$1"; printf "  ${DIM}See the log: %s${RESET}\n" "$LOG_FILE"; exit 1; }

# Run a command in the background with a spinner; output goes to the log.
spin() {
  local msg=$1; shift
  printf "\n\$ %s\n" "$*" >>"$LOG_FILE"
  "$@" >>"$LOG_FILE" 2>&1 &
  local pid=$! i=0
  if [ -t 1 ]; then
    local shown=$msg cols
    cols=$(tput cols 2>/dev/null || echo 80)
    [ "${#shown}" -gt $((cols - 6)) ] && shown="${shown:0:$((cols - 9))}..."
    while kill -0 "$pid" 2>/dev/null; do
      printf "\r  ${CYAN}%s${RESET} %s" "${FRAMES[i % ${#FRAMES[@]}]}" "$shown"
      i=$((i + 1))
      sleep 0.1
    done
    printf "\r\033[K"
  fi
  if wait "$pid"; then ok "$msg"; else bad "$msg"; return 1; fi
}

bar() {
  local cur=$1 total=$2 width=24 out="" n
  n=$((cur * width / total))
  for ((j = 0; j < width; j++)); do
    if [ "$j" -lt "$n" ]; then out+="$FULL"; else out+="$EMPTY"; fi
  done
  printf "%s %2d/%d" "$out" "$cur" "$total"
}

# ask "question" default(y/n)
ask() {
  local q=$1 def=$2 hint ans
  [ "$def" = y ] && hint="Y/n" || hint="y/N"
  if [ "$YES" = 1 ]; then [ "$def" = y ]; return; fi
  printf "  ${BOLD}?${RESET} %s ${DIM}[%s]${RESET} " "$q" "$hint"
  read -r ans </dev/tty || ans=""
  ans=${ans:-$def}
  [[ "$ans" =~ ^[Yy] ]]
}

# ---------- python ----------
PYTHON=""
find_python() {
  local c
  for c in python3.14 python3.13 python3.12 python3.11 python3.10 python3 python; do
    if command -v "$c" >/dev/null 2>&1 &&
      "$c" -c "import sys; sys.exit(0 if sys.version_info >= (3, $MIN_MINOR) else 1)" 2>/dev/null; then
      PYTHON=$(command -v "$c")
      return 0
    fi
  done
  return 1
}

SUDO=""
need_sudo() {
  if [ "$(id -u)" -ne 0 ]; then
    command -v sudo >/dev/null 2>&1 || die "sudo is required to install system packages"
    SUDO="sudo"
    info "Your password may be needed to install system packages."
    sudo -v </dev/tty || die "sudo authentication failed"
  fi
}

install_python_linux() {
  need_sudo
  if command -v apt-get >/dev/null 2>&1; then
    spin "Updating package lists" $SUDO apt-get update
    spin "Installing python3, pip and venv" $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-pip python3-venv
  elif command -v dnf >/dev/null 2>&1; then
    spin "Installing python3 and pip" $SUDO dnf install -y python3 python3-pip
  elif command -v yum >/dev/null 2>&1; then
    spin "Installing python3 and pip" $SUDO yum install -y python3 python3-pip
  elif command -v pacman >/dev/null 2>&1; then
    spin "Installing python and pip" $SUDO pacman -Sy --noconfirm --needed python python-pip
  elif command -v zypper >/dev/null 2>&1; then
    spin "Installing python3 and pip" $SUDO zypper --non-interactive install python3 python3-pip
  elif command -v apk >/dev/null 2>&1; then
    spin "Installing python3 and pip" $SUDO apk add python3 py3-pip
  else
    die "No supported package manager found. Install Python 3.$MIN_MINOR+ manually and re-run."
  fi
}

install_python_macos() {
  if command -v brew >/dev/null 2>&1; then
    spin "Installing Python with Homebrew" brew install python
  else
    local pkg="${TMPDIR:-/tmp}/python-$PY_VERSION.pkg"
    spin "Downloading Python $PY_VERSION from python.org" \
      curl -fL -o "$pkg" "https://www.python.org/ftp/python/$PY_VERSION/python-$PY_VERSION-macos11.pkg"
    need_sudo
    spin "Installing Python $PY_VERSION" $SUDO installer -pkg "$pkg" -target /
    export PATH="/usr/local/bin:/Library/Frameworks/Python.framework/Versions/${PY_VERSION%.*}/bin:$PATH"
  fi
}

# Debian/Ubuntu split venv/ensurepip into a separate package.
ensure_venv_module() {
  "$PYTHON" -c "import ensurepip, venv" >/dev/null 2>&1 && return 0
  if command -v apt-get >/dev/null 2>&1; then
    local ver
    ver=$("$PYTHON" -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")')
    need_sudo
    spin "Installing python$ver-venv" $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y "python$ver-venv" ||
      spin "Installing python3-venv" $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y python3-venv
  else
    die "Python's venv module is missing. Install it with your package manager and re-run."
  fi
}

# ---------- PATH ----------
add_to_path() {
  local bin="$VENV_DIR/bin" rc files=("$HOME/.profile") sh=${SHELL:-}
  sh=${sh##*/}
  [ -f "$HOME/.bashrc" ] || [ "$sh" = bash ] && files+=("$HOME/.bashrc")
  [ -f "$HOME/.bash_profile" ] && files+=("$HOME/.bash_profile")
  [ -f "$HOME/.zshrc" ] || [ "$sh" = zsh ] && files+=("$HOME/.zshrc")
  for rc in "${files[@]}"; do
    if [ -f "$rc" ] && grep -qF "$MARKER" "$rc"; then
      ok "Already in PATH via ${rc/#$HOME/~}"
    else
      printf '\n%s\nexport PATH="%s:$PATH"\n' "$MARKER" "$bin" >>"$rc"
      ok "Added to PATH in ${rc/#$HOME/~}"
    fi
  done
  local fish="$HOME/.config/fish/config.fish"
  if [ -f "$fish" ] && ! grep -qF "$MARKER" "$fish"; then
    printf '\n%s\nfish_add_path -g "%s"\n' "$MARKER" "$bin" >>"$fish"
    ok "Added to PATH in ~/.config/fish/config.fish"
  fi
  export PATH="$bin:$PATH"
}

# ---------- libraries ----------
PACKAGES=()
choose_packages() {
  if [ "$ALL" = 1 ]; then
    PACKAGES=("${CORE[@]}" "${DATA[@]}" "${WEB[@]}" "${DEV[@]}")
    return
  fi
  printf "  ${BOLD}Library groups${RESET}\n"
  printf "    ${CYAN}core${RESET}  %s\n" "${CORE[*]}"
  printf "    ${CYAN}data${RESET}  %s\n" "${DATA[*]}"
  printf "    ${CYAN}web ${RESET}  %s\n" "${WEB[*]}"
  printf "    ${CYAN}dev ${RESET}  %s\n\n" "${DEV[*]}"
  ask "Install core libraries?" y && PACKAGES+=("${CORE[@]}")
  ask "Install data science libraries?" n && PACKAGES+=("${DATA[@]}")
  ask "Install web libraries?" n && PACKAGES+=("${WEB[@]}")
  ask "Install dev tools?" y && PACKAGES+=("${DEV[@]}")
  return 0
}

# ---------- main ----------
: >"$LOG_FILE"
trap 'rc=$?; [ "$rc" -eq 0 ] || printf "\n  ${RED}Setup stopped.${RESET} See the log: %s\n\n" "$LOG_FILE"' EXIT
banner

case "$(uname -s)" in
  Linux) OS=linux ;;
  Darwin) OS=macos ;;
  *) die "Unsupported system. On Windows run setup.bat instead." ;;
esac

step "Checking Python"
if find_python; then
  ok "Found $("$PYTHON" --version 2>&1) at $PYTHON"
else
  warn "Python 3.$MIN_MINOR+ not found, installing it"
  if [ "$OS" = macos ]; then install_python_macos; else install_python_linux; fi
  find_python || die "Python was installed but could not be found. Open a new terminal and re-run."
  ok "Installed $("$PYTHON" --version 2>&1)"
fi

step "Creating the Python Dev environment"
VPY="$VENV_DIR/bin/python"
if [ -x "$VPY" ]; then
  ok "Environment already exists at ${VENV_DIR/#$HOME/~}"
else
  ensure_venv_module
  spin "Creating environment at ${VENV_DIR/#$HOME/~}" "$PYTHON" -m venv "$VENV_DIR" || die "Could not create the environment"
fi
spin "Upgrading pip" "$VPY" -m pip install --upgrade pip || warn "pip upgrade failed, continuing"

step "Adding Python to PATH"
add_to_path

step "Installing libraries"
choose_packages
FAILED=()
if [ "${#PACKAGES[@]}" -eq 0 ]; then
  info "No libraries selected"
else
  n=${#PACKAGES[@]}
  i=0
  for pkg in "${PACKAGES[@]}"; do
    i=$((i + 1))
    spin "$(bar "$i" "$n")  $pkg" "$VPY" -m pip install --upgrade --disable-pip-version-check "$pkg" || FAILED+=("$pkg")
  done
fi

step "VS Code extensions"
if command -v code >/dev/null 2>&1; then
  if ask "Install Python extensions for VS Code?" y; then
    for ext in "${VSCODE_EXTENSIONS[@]}"; do
      spin "$ext" code --install-extension "$ext" --force || warn "Could not install $ext"
    done
  else
    info "Skipped"
  fi
else
  info "VS Code command 'code' not found, skipped"
fi

# ---------- summary ----------
printf "\n${GREEN}${BOLD}  +------------------------------------------+\n"
printf "  |              Setup complete              |\n"
printf "  +------------------------------------------+${RESET}\n"
printf "  Python       %s\n" "$("$VPY" --version 2>&1)"
printf "  Environment  %s\n" "${VENV_DIR/#$HOME/~}"
printf "  Libraries    %d installed\n" "$((${#PACKAGES[@]} - ${#FAILED[@]}))"
if [ "${#FAILED[@]}" -gt 0 ]; then
  printf "  ${RED}Failed${RESET}       %s\n" "${FAILED[*]}"
  printf "  ${DIM}Details in %s${RESET}\n" "$LOG_FILE"
fi
printf "\n  ${BOLD}Next:${RESET} open a new terminal, then try\n"
printf "    ${CYAN}python -c \"import sys; print(sys.executable)\"${RESET}\n\n"
