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

# Command Line Tools (headless)
if ! xcode-select -p >/dev/null 2>&1; then
  echo "[bootstrap] Installing Xcode Command Line Tools (headless)..."
  sudo -v

  sudo /usr/bin/touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  # 中断/終了時に確実に掃除
  trap 'sudo /bin/rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress' EXIT

  CLT_LABEL="$(
    /usr/sbin/softwareupdate --list 2>/dev/null \
      | awk -F"[*] " '/\* Command Line Tools/ {print $2}' \
      | sed -E 's/^Label: *//; s/^[[:space:]]+|[[:space:]]+$//g' \
      | tail -n1
  )"

  if [[ -z "$CLT_LABEL" ]]; then
    echo "[bootstrap] ERROR: Command Line Tools label not found via softwareupdate." >&2
    echo "          Please retry, or install manually once and rerun." >&2
    exit 1
  fi

  echo "[bootstrap] Installing: $CLT_LABEL"
  # リトライを軽く入れる（ネットワーク混雑対策）
  tries=0
  until sudo /usr/sbin/softwareupdate --install "$CLT_LABEL" --verbose; do
    tries=$((tries+1))
    [[ $tries -ge 3 ]] && { echo "[bootstrap] softwareupdate failed 3 times"; exit 1; }
    echo "[bootstrap] Retrying CLT install ($tries/3)..." && sleep 5
  done

  # 正常終了時も掃除（trapがあるので冪等）
  sudo /bin/rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

  if ! xcode-select -p >/dev/null 2>&1; then
    echo "[bootstrap] ERROR: CLT seems not installed yet." >&2
    exit 1
  fi
fi

# Command Line Tools
# if ! xcode-select -p >/dev/null 2>&1; then
#   echo "[bootstrap] Installing Xcode Command Line Tools..."
#   xcode-select --install || true
#   until xcode-select -p >/dev/null 2>&1; do sleep 5; done
# fi

until command -v git >/dev/null 2>&1; do sleep 1; done

# git clone (public repo)
if [[ -d "$DEST/.git" ]]; then
  echo "[bootstrap] Repo already exists at ${DEST} (skip clone)"
elif [[ -e "$DEST" && ! -d "$DEST" ]]; then
  echo "[bootstrap] ERROR: ${DEST} exists but is not a directory." >&2
  exit 1
else
  mkdir -p "$DEST"
  if [[ -d "$DEST" && -n "$(ls -A "$DEST" 2>/dev/null)" ]]; then
    echo "[bootstrap] ERROR: ${DEST} exists and is not empty." >&2
    exit 1
  fi
  export GIT_TERMINAL_PROMPT=0
  if ! git ls-remote --exit-code --heads "https://github.com/${OWNER}/setup.git" "$BRANCH" >/dev/null 2>&1; then
    echo "[bootstrap] ERROR: Branch '$BRANCH' not found in https://github.com/${OWNER}/setup.git" >&2
    exit 1
  fi

  echo "[bootstrap] Cloning repo to ${DEST} ..."
  tries=0
  until git clone "https://github.com/${OWNER}/setup.git" \
                  --branch "$BRANCH" --single-branch \
                  --depth=1 --filter=blob:none "$DEST"; do
    tries=$((tries+1))
    [[ $tries -ge 3 ]] && break
    echo "[bootstrap] git clone failed (retry $tries/3)..." >&2
    sleep 3
  done

  if [[ ! -d "$DEST/.git" ]]; then
    # 任意：どうしても git がダメな時だけ ZIP フォールバック
    echo "[bootstrap] Falling back to tarball download..."
    rm -rf "$DEST"
    mkdir -p "$DEST"
    curl -fsSL "https://github.com/${OWNER}/setup/archive/${BRANCH}.tar.gz" \
      | tar -xz -C "$DEST" --strip-components=1 \
      || { echo "[bootstrap] ERROR: failed to download tarball"; exit 1; }
  fi
fi

# if [[ -d "$DEST/.git" ]]; then
#   echo "[bootstrap] Repo already exists at ${DEST} (skip clone)"
# elif [[ -e "$DEST" ]]; then
#   if [[ -d "$DEST" ]]; then
#     if [[ -z "$(ls -A "$DEST" 2>/dev/null)" ]]; then
#       echo "[bootstrap] Cloning into existing empty dir: ${DEST}"
#       git clone "https://github.com/${OWNER}/setup.git" --branch "$BRANCH" --single-branch --depth=1 "$DEST"
#     else
#       echo "[bootstrap] ERROR: ${DEST} exists and is not empty." >&2
#       exit 1
#     fi
#   else
#     echo "[bootstrap] ERROR: ${DEST} exists but is not a directory." >&2
#     exit 1
#   fi
# else
#   echo "[bootstrap] Cloning repo to ${DEST} ..."
#   mkdir -p "$(dirname "$DEST")"
#   git clone "https://github.com/${OWNER}/setup.git" --branch "$BRANCH" --single-branch --depth=1 "$DEST"
# fi

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
