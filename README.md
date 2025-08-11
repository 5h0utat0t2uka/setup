# Setup scripts for macOS

**Apple Silicon** のmacOSで、最小限のセットアップを行うためのスクリプトです  
`Use this template`からカスタマイズして利用してください  
- `setup.sh`: 
  1. Command Line Toolsのインストール  
  2. Homebrew, Brewfileのパッケージをインストール  
  3. SSH鍵を生成してGitHubへ公開鍵を登録  

- `dotfiles.sh`: 
  1. chezmoi の インストールから初期化と反映  

---

## リポジトリをクローンして実行する場合
``` shell
cd ~
git clone https://github.com/<your-name>/setup.git  
cd setup
```

### セットアップ
``` shell
# SSH_KEY_TITLEは省略出来ます
make setup SSH_KEY_TITLE="github-$(hostname)-$(date +%Y%m%d)"
```

### ドットファイル
``` shell
make dotfiles REPO="git@github.com:you/dotfiles.git" BRANCH="main"
```

## 直接実行する場合
### セットアップ
``` shell
bash <(curl -fsSL https://raw.githubusercontent.com/<your-name>/setup/main/setup.sh) \
  --ssh-key-title "github-$(hostname)-$(date +%Y%m%d)"
```

### ドットファイル
``` shell
bash <(curl -fsSL https://raw.githubusercontent.com/<your-name>/setup/main/dotfiles.sh) \
  --repo "git@github.com:you/dotfiles.git" \
  --branch "main"
```

> [!CAUTION]
> スクリプト内容を確認してから実行してください

## License
This project is licensed under the [MIT License](./LICENSE).
