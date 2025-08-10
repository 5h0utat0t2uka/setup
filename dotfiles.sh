#!/usr/bin/env bash
set -euo pipefail

REPO=""
BRANCH=""

usage() {
  echo "Usage: $0 --repo <git-url> [--branch <name>]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2;;
    --branch) BRANCH="$2"; shift 2;;
    -h|--help) usage;;
    *) echo "Unknown arg: $1"; usage;;
  esac
done

[[ -z "$REPO" ]] && usage

log()  { printf "\033[1;34m[dotfiles]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[error]\033[0m %s\n" "$*" >&2; }
command_exists() { command -v "$1" >/dev/null 2>&1; }

[[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "arm64" ]] || { err "This script is only for Apple Silicon macOS"; exit 1; }

command_exists brew || { err "Homebrew is required (please run setup.sh / make setup first)"; exit 1; }
command_exists chezmoi || { log "Installing chezmoi..."; brew install chezmoi; }

CHEZ_SRC="$HOME/.local/share/chezmoi"
if [[ -d "$CHEZ_SRC/.git" ]]; then
  log "chezmoi: already initialized -> pulling latest"
  chezmoi git pull -- --rebase || true
  log "Applying dotfiles..."
  chezmoi apply
else
  log "Initializing chezmoi from: $REPO"
  if [[ -n "$BRANCH" ]]; then
    chezmoi init --apply --branch "$BRANCH" "$REPO"
  else
    chezmoi init --apply "$REPO"
  fi
fi

log "Dotfiles applied."
