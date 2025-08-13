# Setup scripts for macOS

**Apple Silicon**のmacOSで、最小限のセットアップを行うためのスクリプトです  

## 事前準備
1. このリポジトリの`Use this template`から新規のリポジトリを作成してください  
2. 以下のコマンドで自身の`Brewfile`を作成し、リポジトリ内の`Brewfile`を更新してください  
``` shell
brew bundle dump --global
```

## 利用方法
以下の3つのスクリプトで構成されているので、必要なものを実行してください
1. `bootstrap.sh`:  
  - Command Line Toolsのインストール  
  - Homebrewのインストール  
  - Brewfileのパッケージをインストール  

2. `setup.sh`: 
  - SSH鍵を生成してGitHubへ公開鍵を登録()  
  - macOSのplistを更新  

3. `dotfiles.sh`: 
  - chezmoi の インストールから初期化と反映  

---  

1. 新しい環境のターミナルで`curl`から直接`bootstrap.sh`を実効
> [!TIP]
> 実行中にパスワードの入力を求められます
``` shell
bash <(curl -fsSL https://raw.githubusercontent.com/<OWNER>/setup/<BRANCH>/bootstrap.sh) \
  --owner <OWNER> \
  --branch <BRANCH> \
  --dest "$HOME/setup"
```

2. ホームディレクトリ直下にリポジトリがクローンされているので、以下のコマンドで`setup.sh`を実効  
``` shell
cd ~/setup

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
