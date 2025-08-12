# Makefile
# Targets:
#   make setup:     Brewfile適用 & （既定）SSH鍵生成/登録/remote切替
#   make dotfiles:  chezmoi 等でdotfiles反映（dotfiles.shに委譲）

SHELL := /bin/zsh
.ONESHELL:
.SILENT:
.DEFAULT_GOAL := help

# 可変パラメータ例:
#   make setup SSH_KEY_TITLE="github-$(shell hostname)-$(shell date +%Y%m%d)"
#   make setup NO_SSH=1
#   make dotfiles REPO="git@github.com:you/dotfiles.git" BRANCH="main"

SSH_KEY_TITLE ?=
NO_SSH ?= 0

REPO ?=
BRANCH ?= main

SETUP_SCRIPT    := ./setup.sh
DOTFILES_SCRIPT := ./dotfiles.sh

.PHONY: help setup dotfiles

help:
	echo "Usage:"
	echo "  make setup     [SSH_KEY_TITLE='github-<host>-<YYYYMMDD>'] [NO_SSH=1]"
	echo "  make dotfiles  REPO='git@github.com:you/dotfiles.git' [BRANCH='main']"
	echo
	echo "Notes:"
	echo "  - NO_SSH=1 は ./setup.sh --no-ssh と同義です。"
	echo "  - SSH_KEY_TITLE は NO_SSH=1 の場合は無視されます。"

setup:
	set -euo pipefail
	chmod +x "$(SETUP_SCRIPT)"
	"$(SETUP_SCRIPT)" \
	  $(if $(filter 1,$(NO_SSH)),--no-ssh) \
	  $(if $(SSH_KEY_TITLE),--ssh-key-title "$(SSH_KEY_TITLE)")

dotfiles:
	set -euo pipefail
	if [[ -z "$(REPO)" ]]; then
	  echo "[error] REPO is required (e.g., git@github.com:you/dotfiles.git)"; exit 1; fi
	chmod +x "$(DOTFILES_SCRIPT)"
	"$(DOTFILES_SCRIPT)" \
	  --repo "$(REPO)" \
	  $(if $(BRANCH),--branch "$(BRANCH)")

