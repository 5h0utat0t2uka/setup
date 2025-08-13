#!/usr/bin/env bash
set -euo pipefail

OWNER=""
BRANCH="main"
DEST="${HOME}/setup"
DO_BUNDLE=1

BREW_BIN="/opt/homebrew/bin/brew"
command -v brew >/dev/null 2>&1 && BREW_BIN="$(command -v brew)"

usage() {
  echo "Usage: bash bootstrap.sh --owner <OWNER> [--branch main] [--dest \$HOME/setup] [--no-bundle]" >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner)  OWNER="${2-}"; shift 2 ;;
    --branch) BRANCH="${2-}"; shift 2 ;;
    --dest)   DEST="${2-}";  shift 2 ;;
    --no-bundle) DO_BUNDLE=0; shift ;;
    *) echo "[bootstrap] Unknown arg: $1" >&2; usage ;;
  esac
done
[[ -n "$OWNER" ]] || usage

echo "[bootstrap] Target repo: https://github.com/${OWNER}/setup (branch=${BRANCH})"
echo "[bootstrap] Destination: ${DEST}"

# Command Line Tools
if ! xcode-select -p >/dev/null 2>&1; then
  echo "[bootstrap] Installing Xcode Command Line Tools..."
  xcode-select --install || true
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
fi

until command -v git >/dev/null 2>&1; do sleep 1; done

# git clone
if [[ -d "$DEST/.git" ]]; then
  echo "[bootstrap] Repo already exists at ${DEST} (skip clone)"
elif [[ -e "$DEST" ]]; then
  if [[ -d "$DEST" ]]; then
    if [[ -z "$(ls -A "$DEST" 2>/dev/null)" ]]; then
      echo "[bootstrap] Cloning into existing empty dir: ${DEST}"
      git clone "https://github.com/${OWNER}/setup.git" --branch "$BRANCH" --single-branch --depth=1 "$DEST"
    else
      echo "[bootstrap] ERROR: ${DEST} exists and is not empty." >&2
      exit 1
    fi
  else
    echo "[bootstrap] ERROR: ${DEST} exists but is not a directory." >&2
    exit 1
  fi
else
  echo "[bootstrap] Cloning repo to ${DEST} ..."
  mkdir -p "$(dirname "$DEST")"
  git clone "https://github.com/${OWNER}/setup.git" --branch "$BRANCH" --single-branch --depth=1 "$DEST"
fi

# Homebrew
if ! "$BREW_BIN" -v >/dev/null 2>&1; then
  echo "[bootstrap] Installing Homebrew (will prompt for your password once)..."
  sudo -v  # パスワード入力を先に促す（5分程度キャッシュ）
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

eval "$($BREW_BIN shellenv)"

export HOMEBREW_NO_ENV_HINTS=1 HOMEBREW_NO_AUTO_UPDATE=1
"$BREW_BIN" analytics off || true
"$BREW_BIN" update

# Bundle
if [[ "$DO_BUNDLE" -eq 1 ]]; then
  BREWFILE="${DEST}/Brewfile"
  if [[ -f "$BREWFILE" ]]; then
    echo "[bootstrap] Applying Brewfile at: ${BREWFILE}"
    "$BREW_BIN" tap homebrew/bundle || true
    "$BREW_BIN" bundle --file="$BREWFILE"
  else
    echo "[bootstrap] Brewfile not found at ${BREWFILE} (skip bundle)"
  fi
else
  echo "[bootstrap] Skipping Brewfile (--no-bundle)"
fi

cat <<EOS

✅ Setup repo is ready.

Next steps:

  1) Run setup via Make (SSH鍵生成が不要なら NO_SSH=1):
       cd "$DEST" && make setup
       # or: make setup NO_SSH=1
       #     make setup SSH_KEY_TITLE="github-\$(hostname)-\$(date +%Y%m%d)"

EOS
