# Setup scripts for macOS

**Apple Silicon**のmacOSで、最小限のセットアップを行うためのスクリプトです  
`Use this template`からカスタマイズして利用してください  
- `bootstrap.sh`:  
  - Command Line Toolsのインストール  
  - Homebrewのインストール  
  - リポジトリのクローン  

- `setup.sh`: 
  - Brewfileのパッケージをインストール  
  - SSH鍵を生成してGitHubへ公開鍵を登録  

- `dotfiles.sh`: 
  - chezmoi の インストールから初期化と反映  

---

## 事前準備
古い環境のHomebrewのパッケージをまとめてインストールする場合は、以下を実行して`Brewfile`を作成して利用してください
``` shell
brew bundle dump --global
```

## 利用方法
1. 新しい環境のターミナルで`curl`から直接`bootstrap.sh`を実効
``` shell
curl -fsSL https://raw.githubusercontent.com/<OWNER>/setup/<BRANCH>/bootstrap.sh | bash -s -- --owner <OWNER> --branch <BRANCH>
```

2. ホームディレクトリ直下に`setup`がクローンされるので、その中にある`Brewfile`を編集
``` shell
cd ~/setup
vi Brewfile
```

3. 以下のコマンドで`setup.sh`を実効
``` shell
# SSH鍵の生成が必要な場合
make setup
# SSH鍵の生成が不要な場合
make setup NO_SSH=1
```

> [!CAUTION]
> スクリプト内容を確認してから実行してください

## License
This project is licensed under the [MIT License](./LICENSE).
