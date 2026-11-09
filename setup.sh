#!/usr/bin/env bash

# ============================================================
#   ████████╗███████╗██████╗ ███╗   ███╗██╗   ██╗██╗  ██╗
#   ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║   ██║╚██╗██╔╝
#      ██║   █████╗  ██████╔╝██╔████╔██║██║   ██║ ╚███╔╝
#      ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║   ██║ ██╔██╗
#      ██║   ███████╗██║  ██║██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗
#      ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝
#
#   Smart Setup & Runner  •  Everything in ~/glory
# ============================================================

set -euo pipefail

# ---------- Colors ----------
R="\033[0m"; B="\033[1m"; D="\033[2m"
RED="\033[0;31m"; GRN="\033[0;32m"; YEL="\033[0;33m"
BLU="\033[0;34m"; MAG="\033[0;35m"; CYN="\033[0;36m"; WHT="\033[0;37m"
BG_G="\033[42m"

# ---------- Helpers ----------
ok()    { echo -e "  ${GRN}${B}✔${R} ${GRN}$1${R}"; }
skip()  { echo -e "  ${MAG}${B}↷${R} ${MAG}$1${R}"; }
warn()  { echo -e "  ${YEL}${B}⚠${R} ${YEL}$1${R}"; }
fail()  { echo -e "  ${RED}${B}✘${R} ${RED}$1${R}"; }
info()  { echo -e "  ${CYN}${B}ℹ${R} ${WHT}$1${R}"; }
step()  {
    echo -e "\n${BLU}${B}▶ $1${R}"
    echo -e "${D}────────────────────────────────────────────────────${R}"
}

# ---------- Banner ----------
banner() {
    clear
    echo -e "${CYN}${B}"
    cat <<'EOF'
  ╔══════════════════════════════════════════════════╗
  ║                                                  ║
  ║        🚀  TERMUX AUTO SETUP & RUNNER  🚀        ║
  ║                                                  ║
  ║     Python • Modules • Git • Execute             ║
  ║                                                  ║
  ╚══════════════════════════════════════════════════╝
EOF
    echo -e "${R}"
}

banner

# ---------- Workspace Folder ----------
# All files (requirements.txt + cloned repo) live inside ~/glory
WORKSPACE="$HOME/glory"

step "[0/5] Preparing Workspace Folder"

if [ -d "$WORKSPACE" ]; then
    skip "Workspace already exists — $WORKSPACE"
else
    mkdir -p "$WORKSPACE"
    ok "Workspace created — $WORKSPACE"
fi

cd "$WORKSPACE"
info "Working directory: $(pwd)"

# ---------- [1/5] Storage Permission ----------
step "[1/5] Storage Permission"

if [ -d "$HOME/storage" ]; then
    skip "Storage already configured — skipping"
else
    info "Requesting storage permission..."
    termux-setup-storage
    sleep 2
    ok "Storage permission granted"
fi

# ---------- [2/5] Python Check / Install ----------
step "[2/5] Python Environment"

if command -v python >/dev/null 2>&1; then
    skip "Python already installed — $(python --version 2>&1)"
else
    info "Installing Python & Git..."
    pkg update -y >/dev/null 2>&1
    pkg install -y python git >/dev/null 2>&1
    ok "Python installed — $(python --version 2>&1)"
fi

if ! command -v git >/dev/null 2>&1; then
    info "Installing Git..."
    pkg install -y git >/dev/null 2>&1
    ok "Git installed"
else
    skip "Git already installed"
fi

python -m pip install --upgrade pip >/dev/null 2>&1 || true
ok "pip is up to date"

# ---------- [3/5] Python Modules ----------
step "[3/5] Python Modules"

MODULES=(
    "httpx"
    "aiohttp"
    "requests"
    "pycryptodome"
    "protobuf>=6.30.0"
    "protobuf-decoder"
    "google-play-scraper"
)

declare -A IMPORT_NAME=(
    ["httpx"]="httpx"
    ["aiohttp"]="aiohttp"
    ["requests"]="requests"
    ["pycryptodome"]="Crypto"
    ["protobuf>=6.30.0"]="google.protobuf"
    ["protobuf-decoder"]="protobuf_decoder"
    ["google-play-scraper"]="google_play_scraper"
)

for pkg in "${MODULES[@]}"; do
    imp="${IMPORT_NAME[$pkg]}"
    if python -c "import $imp" >/dev/null 2>&1; then
        skip "$pkg already installed"
    else
        info "Installing $pkg ..."
        if python -m pip install "$pkg" >/dev/null 2>&1; then
            ok "$pkg installed"
        else
            warn "$pkg failed to install (continuing)"
        fi
    fi
done

# ---------- [4/5] Clone Repository ----------
step "[4/5] GitHub Repository"

# ⬇⬇⬇  PUT YOUR GITHUB REPOSITORY URL HERE  ⬇⬇⬇
REPO_URL="https://github.com/mdariyan47484-ship-it/Glory.git"
# ⬆⬆⬆  PUT YOUR GITHUB REPOSITORY URL HERE  ⬆⬆⬆

REPO_DIR="$WORKSPACE/$(basename "$REPO_URL" .git)"

if [ -d "$REPO_DIR" ]; then
    info "Existing copy found — removing old one..."
    rm -rf "$REPO_DIR"
    skip "Old repository wiped"
fi

info "Cloning fresh copy into $WORKSPACE ..."
if git clone "$REPO_URL" "$REPO_DIR" >/dev/null 2>&1; then
    ok "Repository cloned — $REPO_DIR"
else
    fail "Failed to clone repository"
    exit 1
fi

# ---------- [5/5] Run main.py ----------
step "[5/5] Executing main.py"

cd "$REPO_DIR"

if [ ! -f "main.py" ]; then
    fail "main.py not found inside '$REPO_DIR'"
    exit 1
fi

echo -e "\n${BG_G}${B}${WHT}  ▶  STARTING APPLICATION  ${R}\n"
echo -e "${CYN}${B}════════════════════════════════════════════════════${R}\n"

python main.py

echo -e "\n${CYN}${B}════════════════════════════════════════════════════${R}"
echo -e "${GRN}${B}  ✔  Execution finished successfully${R}\n"
