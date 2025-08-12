# Setup scripts for macOS

**Apple Silicon**のmacOSで、最小限のセットアップを行うためのスクリプトです  
`Use this template`からカスタマイズして利用してください  

## 事前準備
古い環境のHomebrewのパッケージをまとめてインストールする場合は、以下を実行して`Brewfile`を作成して利用してください
``` shell
brew bundle dump --global
```

## 利用方法
以下の3つのスクリプトで構成されているので、必要なものを実行してください
1. `bootstrap.sh`:  
  - Command Line Toolsのインストール  
  - Homebrewのインストール  

2. `setup.sh`: 
  - Brewfileのパッケージをインストール  
  - SSH鍵を生成してGitHubへ公開鍵を登録  

3. `dotfiles.sh`: 
  - chezmoi の インストールから初期化と反映  

---  

1. 新しい環境のターミナルで`curl`から直接`bootstrap.sh`を実効
> [!TIP]
> 実行中にパスワードの入力を求められます
``` shell
bash <(curl -fsSL https://raw.githubusercontent.com/<OWNER>/setup/<BRANCH>/bootstrap.sh) --owner <OWNER> --branch <BRANCH>
```

2. ホームディレクトリ直下にこのリポジトリがクローンされているので、その中にある`Brewfile`を編集
``` shell
cd ~/setup
vi Brewfile
```

その後以下のコマンドで`setup.sh`を実効  
``` shell
# SSH鍵の生成が必要な場合
make setup
# SSH鍵の生成が不要な場合
make setup NO_SSH=1
```

3. 以下のコマンドで`dotfiles.sh`を実効
``` shell
make dotfiles
```

> [!IMPORTANT]
> スクリプト内容を確認してから実行してください

## License
This project is licensed under the [MIT License](./LICENSE).
