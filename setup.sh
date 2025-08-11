#!/usr/bin/env bash
set -euo pipefail

GIT_HOSTNAME="github.com"
SSH_KEY_TITLE=""
SSH_KEY_PATH="${HOME}/.ssh/id_ed25519"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREW="/opt/homebrew/bin/brew"
BREWFILE="${SCRIPT_DIR}/Brewfile"

log()  { printf "\033[1;32m[setup]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[error]\033[0m %s\n" "$*" >&2; }

started_agent_pid=""
cleanup_agent() {
  if [[ -n "$started_agent_pid" ]]; then
    log "ssh-agent: stopping (pid=$started_agent_pid)"
    ssh-agent -k >/dev/null 2>&1 || true
  fi
}
trap 'code=$?; cleanup_agent; err "Failed at line $LINENO: $BASH_COMMAND (exit $code)"; exit $code' ERR
trap 'cleanup_agent' EXIT

# OSの判定とBrewfileの存在確認
[[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "arm64" ]] || { err "This script is only for Apple Silicon macOS"; exit 1; }
[[ -f "$BREWFILE" ]] || { err "Brewfile is required: $BREWFILE"; exit 1; }

# 1. Command Line Toolsの確認とインストール
if xcode-select -p >/dev/null 2>&1; then
  log "Command Line Tools: OK"
else
  log "Installing Command Line Tools..."
  xcode-select --install || true
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
  log "Command Line Tools: installed"
fi

# 2. Homebrewの確認とインストール
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

# 3. GitHubの認証
if gh auth status --hostname "$GIT_HOSTNAME" >/dev/null 2>&1; then
  log "GitHub auth: OK"
else
  log "Running 'gh auth login'..."
  gh auth login --hostname "$GIT_HOSTNAME"
fi

# 4. SSH keyの生成と登録
mkdir -p "${HOME}/.ssh"; chmod 700 "${HOME}/.ssh"
if [[ -z "$SSH_KEY_TITLE" ]]; then
  HOST_CLEAN="$(hostname | tr -cd '[:alnum:]-')"
  DATE_STR="$(date +%Y%m%d)"
  SSH_KEY_TITLE="github-${HOST_CLEAN}-${DATE_STR}"
fi
if [[ -f "${SSH_KEY_PATH}" && -f "${SSH_KEY_PATH}.pub" ]]; then
  log "SSH key already exists: ${SSH_KEY_PATH}"
else
  log "Generating SSH key (comment='${SSH_KEY_TITLE}')..."
  ssh-keygen -t ed25519 -C "$SSH_KEY_TITLE" -f "$SSH_KEY_PATH" -N ""
  log "SSH key generated."
fi

chmod 600 "${SSH_KEY_PATH}"
chmod 644 "${SSH_KEY_PATH}.pub"

if [[ -n "${SSH_AUTH_SOCK:-}" ]] && ssh-add -l >/dev/null 2>&1; then
  log "ssh-agent: using existing agent"
else
  log "ssh-agent: starting new agent"
  eval "$(ssh-agent -s)" >/dev/null
  started_agent_pid="$SSH_AGENT_PID"
fi

if ssh-add -l 2>/dev/null | grep -q "$(ssh-keygen -lf "${SSH_KEY_PATH}" | awk '{print $2}')"; then
  log "ssh-agent: key already loaded"
else
  log "ssh-agent: adding key to agent"
  ssh-add --apple-use-keychain "${SSH_KEY_PATH}" || ssh-add "${SSH_KEY_PATH}"
fi

# 5. GitHubに公開鍵を登録
PUB_KEY_CONTENT="$(cat "${SSH_KEY_PATH}.pub")"
if gh ssh-key list --json key --jq '.[].key' | grep -qxF "$PUB_KEY_CONTENT"; then
  log "GitHub: same public key already registered."
else
  log "Registering public key to GitHub with title: ${SSH_KEY_TITLE}"
  gh ssh-key add "${SSH_KEY_PATH}.pub" --title "${SSH_KEY_TITLE}"
  log "GitHub: SSH key registered."
fi

# 6. macOSの初期設定を変更
log "Applying macOS preferences..."
defaults write NSGlobalDomain AppleShowAllExtensions -bool true # 拡張子を常に表示
defaults write com.apple.finder AppleShowAllFiles -bool true    # 隠しファイルを表示
killall Finder >/dev/null 2>&1 || true
log "macOS preferences applied."

log "Setup completed."
