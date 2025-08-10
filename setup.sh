#!/usr/bin/env bash
set -euo pipefail

GIT_NAME=""
GIT_EMAIL=""
GIT_HOSTNAME="github.com"
SSH_KEY_TITLE=""
SSH_KEY_PATH="${HOME}/.ssh/id_ed25519"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREW="/opt/homebrew/bin/brew"
BREWFILE="${SCRIPT_DIR}/Brewfile"

usage() {
  cat <<USAGE
Usage:
  $0 --git-name "<Your Name>" --git-email "<you@example.com>" [--ssh-key-title <title>]
USAGE
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --git-name) GIT_NAME="$2"; shift 2;;
    --git-email) GIT_EMAIL="$2"; shift 2;;
    --ssh-key-title) SSH_KEY_TITLE="$2"; shift 2;;
    -h|--help) usage;;
    *) echo "Unknown arg: $1"; usage;;
  esac
done

[[ -z "$GIT_NAME" || -z "$GIT_EMAIL" ]] && usage

log()  { printf "\033[1;32m[core]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[error]\033[0m %s\n" "$*" >&2; }
command_exists() { command -v "$1" >/dev/null 2>&1; }

[[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "arm64" ]] || { err "This script is only for Apple Silicon macOS"; exit 1; }
[[ -f "$BREWFILE" ]] || { err "Brewfile is required: $BREWFILE"; exit 1; }

# 1. Command Line Tools
if xcode-select -p >/dev/null 2>&1; then
  log "Command Line Tools: OK"
else
  log "Installing Command Line Tools..."
  xcode-select --install || true
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
  log "Command Line Tools: installed"
fi

# 2. Homebrew
if [[ -x "$BREW" ]]; then
  log "Homebrew: OK"
else
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  log "Homebrew: installed"
fi

eval "$($BREW shellenv)"
brew tap homebrew/bundle >/dev/null 2>&1 || true
log "Applying Brewfile -> brew bundle --file=\"$BREWFILE\" --no-lock"
brew bundle --file="$BREWFILE" --no-lock

# 4. git, gh
git config --global user.name  "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main

if gh auth status --hostname "$GIT_HOSTNAME" >/dev/null 2>&1; then
  log "GitHub auth: OK"
else
  log "Running 'gh auth login'..."
  gh auth login --hostname "$GIT_HOSTNAME"
fi

# 6. SSH key
mkdir -p "${HOME}/.ssh"; chmod 700 "${HOME}/.ssh"
if [[ -f "${SSH_KEY_PATH}" && -f "${SSH_KEY_PATH}.pub" ]]; then
  log "SSH key already exists: ${SSH_KEY_PATH}"
else
  log "Generating SSH key..."
  ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY_PATH" -N ""
  log "SSH key generated."
fi

chmod 600 "${SSH_KEY_PATH}"
chmod 644 "${SSH_KEY_PATH}.pub"

eval "$(ssh-agent -s)" >/dev/null
ssh-add --apple-use-keychain "${SSH_KEY_PATH}" || ssh-add "${SSH_KEY_PATH}"

PUB_KEY_CONTENT="$(cat "${SSH_KEY_PATH}.pub")"

# --ssh-key-title 未指定なら github-<hostname>-<YYYYMMDD>
if [[ -z "$SSH_KEY_TITLE" ]]; then
  HOST_CLEAN="$(hostname | tr -cd '[:alnum:]-')"
  DATE_STR="$(date +%Y%m%d)"
  SSH_KEY_TITLE="github-${HOST_CLEAN}-${DATE_STR}"
fi
TITLE="$SSH_KEY_TITLE"

# 7. GitHub
if gh ssh-key list --json title,key --jq '.[].key' | grep -qxF "$PUB_KEY_CONTENT"; then
  log "GitHub: same public key already registered."
else
  log "Registering public key to GitHub with title: ${TITLE}"
  gh ssh-key add "${SSH_KEY_PATH}.pub" --title "${TITLE}"
  log "GitHub: SSH key registered."
fi

log "Core setup completed."
