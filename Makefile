# Makefile
# Targets:
#   make setup:    Command Line Toolsのインストール / Homebrew, Brewfileのパッケージをインストール / SSH鍵を生成してGitHubへ公開鍵を登録
#   make dotfiles: chezmoi の初期化と反映

SHELL := /bin/zsh
.ONESHELL:
.SILENT:
.DEFAULT_GOAL := help

# 可変パラメータ
# 例:
# make setup SSH_KEY_TITLE="github-$(shell hostname)-$(shell date +%Y%m%d)"
# make dotfiles REPO="git@github.com:you/dotfiles.git" BRANCH="main"

SSH_KEY_TITLE ?=
REPO          ?=
BRANCH        ?=

SETUP_SCRIPT    := ./setup.sh
DOTFILES_SCRIPT := ./dotfiles.sh

.PHONY: setup dotfiles help

help:
	echo "Usage:"
	echo "  make setup     [SSH_KEY_TITLE='github-<host>-<YYYYMMDD>']"
	echo "  make dotfiles  REPO='git@github.com:you/dotfiles.git' [BRANCH='main']"

setup:
	set -euo pipefail
	chmod +x "$(SETUP_SCRIPT)"
	"$(SETUP_SCRIPT)" \
	  $(if $(SSH_KEY_TITLE),--ssh-key-title "$(SSH_KEY_TITLE)")

dotfiles:
	set -euo pipefail
	if [[ -z "$(REPO)" ]]; then
	  echo "[error] REPO is required (e.g., git@github.com:you/dotfiles.git)"; exit 1; fi
	chmod +x "$(DOTFILES_SCRIPT)"
	"$(DOTFILES_SCRIPT)" \
	  --repo   "$(REPO)" \
	  $(if $(BRANCH),--branch "$(BRANCH)")
