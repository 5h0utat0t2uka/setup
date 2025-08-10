# Makefile
# Targets:
#   make setup     … Command Line Tools / Homebrew / git, gh / GitHub認証 / SSH鍵生成から登録
#   make dotfiles  … chezmoiの初期化と反映

SHELL := /bin/zsh
.ONESHELL:
.SILENT:

GIT_NAME      ?=
GIT_EMAIL     ?=
SSH_KEY_TITLE ?=
REPO          ?=
BRANCH        ?=

SETUP_SCRIPT    := ./setup.sh
DOTFILES_SCRIPT := ./dotfiles.sh

.PHONY: setup dotfiles help

help:
	echo "Usage:"
	echo "  make setup     GIT_NAME='Your Name' GIT_EMAIL='you@example.com' [SSH_KEY_TITLE='github-<host>-<YYYYMMDD>']"
	echo "  make dotfiles  REPO='git@github.com:you/dotfiles.git' [BRANCH='main']"

setup:
	if [[ -z "$(GIT_NAME)" || -z "$(GIT_EMAIL)" ]]; then
	  echo "[error] GIT_NAME and GIT_EMAIL are required"; exit 1; fi
	chmod +x "$(SETUP_SCRIPT)"
	"$(SETUP_SCRIPT)" \
	  --git-name  "$(GIT_NAME)" \
	  --git-email "$(GIT_EMAIL)" \
	  $(if $(SSH_KEY_TITLE),--ssh-key-title "$(SSH_KEY_TITLE)")

dotfiles:
	if [[ -z "$(REPO)" ]]; then
	  echo "[error] Invalid REPO"; exit 1; fi
	chmod +x "$(DOTFILES_SCRIPT)"
	"$(DOTFILES_SCRIPT)" \
	  --repo   "$(REPO)" \
	  $(if $(BRANCH),--branch "$(BRANCH)")
