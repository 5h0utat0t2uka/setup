#!/usr/bin/env bash
set -euo pipefail

# 引数:
#   --owner <GitHub owner>  (必須)  例: --owner yourname
#   --branch <branch>       (任意)  例: --branch main (既定: main)
#   --dest <dir>            (任意)  例: --dest "$HOME/setup" (既定)
OWNER=""
BRANCH="main"
DEST="${HOME}/setup"

usage() {
  echo "Usage: bash bootstrap.sh --owner <OWNER> [--branch main] [--dest \$HOME/setup]" >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner)  OWNER="${2-}"; shift 2 ;;
    --branch) BRANCH="${2-}"; shift 2 ;;
    --dest)   DEST="${2-}";  shift 2 ;;
    *) echo "[bootstrap] Unknown arg: $1" >&2; usage ;;
  esac
done
[[ -n "$OWNER" ]] || usage

echo "[bootstrap] Target repo: https://github.com/${OWNER}/setup (branch=${BRANCH})"
echo "[bootstrap] Destination: ${DEST}"

# 1) Command Line Tools（CLT）
if ! xcode-select -p >/dev/null 2>&1; then
  echo "[bootstrap] Installing Xcode Command Line Tools..."
  xcode-select --install || true
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
fi

# 2) Homebrew（ここだけが Homebrew インストール元）
if ! /opt/homebrew/bin/brew -v >/dev/null 2>&1; then
  echo "[bootstrap] Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"
brew analytics off || true
brew update

# 3) 公開リポを HTTPS で clone（存在すればスキップ）
if [[ ! -d "$DEST/.git" ]]; then
  echo "[bootstrap] Cloning repo to ${DEST} ..."
  git clone "https://github.com/${OWNER}/setup.git" --branch "$BRANCH" --single-branch "$DEST"
else
  echo "[bootstrap] Repo already exists at ${DEST} (skip clone)"
fi

cat <<'EOS'

✅ Setup repo is ready.

Next steps:
  1) Review/modify Brewfile if needed:
       cd "$HOME/setup" && $EDITOR Brewfile

  2) Run setup via Make (SSH鍵生成が不要なら NO_SSH=1):
       cd "$HOME/setup" && make setup
       # or: make setup NO_SSH=1
       #     make setup SSH_KEY_TITLE="github-$(hostname)-$(date +%Y%m%d)"

EOS
