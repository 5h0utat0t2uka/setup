# Setup scripts for macOS

**Apple Silicon** のmacOSで、同OSの別端末への移行と、クリーンインストールを行う場合を想定した最小限のセットアップを行うためのスクリプトです  

## 事前準備
1. このリポジトリの`Use this template`から、**自身の公開リポジトリ**として新しく用意してください  
2. 以下のコマンドで現在の`Brewfile`を作成し、リポジトリ内の`Brewfile`を更新してください  
``` shell
brew bundle dump --global
```

## 利用方法
以下の3つのスクリプトで構成されているので、必要なものを調整して実行してください  
少なくとも(1)は全ての環境で共通になるものです
1. `bootstrap.sh`:  
   - Command Line Toolsのインストール  
   - Homebrewのインストール  
   - `Brewfile`のパッケージをインストール  

2. `setup.sh`: 
   - SSH鍵を生成してGitHubへ公開鍵を登録  
   - macOSのplist関連を更新  

3. `dotfiles.sh`: 
   - `chezmoi`のインストールから初期化と反映  

---  

1. 新しい環境のターミナルで`curl`から直接`bootstrap.sh`を実行  
``` shell
bash <(curl -fsSL https://raw.githubusercontent.com/<OWNER>/setup/<BRANCH>/bootstrap.sh) \
  --owner <OWNER> \
  --branch <BRANCH> \
  --dest "$HOME/setup"
```
> [!NOTE]
> 実行中にOSからダウンロードの確認を求められます
> 実行中にパスワードの入力を求められます

2. ホームディレクトリ直下にリポジトリがクローンされているので、以下のコマンドで`setup.sh`を実行  
``` shell
cd ~/setup

# SSH鍵の生成が必要な場合
make setup
# SSH鍵の生成が不要な場合
make setup NO_SSH=1
```

3. 以下のコマンドで`dotfiles.sh`を実行  
``` shell
make dotfiles
```

> [!IMPORTANT]
> スクリプト内容を確認してから実行してください

## License
This project is licensed under the [MIT License](./LICENSE).
