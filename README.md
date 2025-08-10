# Setup scripts for Apple Silicon macOS

**Apple Silicon macOS** 向けの最小限の初期セットアップのスクリプト  
- `setup.sh`: Command Line Tools / Homebrew, Brewfile / git, gh / GitHub認証 / SSH鍵生成から登録  
- `dotfiles.sh`: chezmoi の インストールから初期化と反映  

---

## リポジトリをクローンして実行する場合
``` shell
cd ~
git clone https://github.com/<your-name>/setup.git  
cd setup
```

### セットアップ
``` shell
make setup \
  GIT_NAME="Your Name" \
  GIT_EMAIL="you@example.com" \
  SSH_KEY_TITLE="github-$(hostname)-$(date +%Y%m%d)"
```

### ドットファイル
``` shell
make dotfiles \
  REPO="git@github.com:you/dotfiles.git" \
  BRANCH="main"
```

## 直接実行する場合
> [!CAUTION]
> スクリプト内容を確認してから実行してください

### セットアップ
``` shell
bash <(curl -fsSL https://raw.githubusercontent.com/<your-name>/setup/main/setup.sh) \
  --git-name "Your Name" \
  --git-email "you@example.com" \
  --ssh-key-title "github-$(hostname)-$(date +%Y%m%d)"
```

### ドットファイル
``` shell
bash <(curl -fsSL https://raw.githubusercontent.com/<your-name>/setup/main/dotfiles.sh) \
  --repo "git@github.com:you/dotfiles.git" \
  --branch "main"
```
