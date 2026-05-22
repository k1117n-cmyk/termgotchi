# 移植マニュアル

## 目的

この文書は、Term-gotchi を別の Mac や PC に安全に移植するための手順をまとめたものです。

## 対応環境

対応:

- `zsh` が使える macOS
- `zsh` が使える Linux
- `zsh` と `jq` が使える WSL 上の Windows

そのままでは非対応:

- Windows `cmd.exe`
- `zsh` 環境のない PowerShell

## コピーするもの

基本的には、リポジトリ全体をコピーしてください。対象は次の通りです。

- `install.zsh`
- `uninstall.zsh`
- `termgotchi.zsh`
- `art/`
- `docs/`

現在のペット状態を引き継がない場合は、`~/.termgotchi/` をコピーする必要はありません。

## 移植先マシンの前提条件

必須:

- `zsh`
- `jq`

確認コマンド:

```sh
zsh --version
jq --version
```

インストール後の推奨確認:

```sh
tg_version
tg_status
```

## 別マシンへの新規インストール

1. リポジトリを移植先マシンにコピーする
2. `zsh` を開く
3. リポジトリのルートディレクトリへ移動する
4. 次を実行する

```sh
zsh ./install.zsh
```

5. 新しいシェルを開くか、次を実行する

```sh
source ~/.zshrc
```

6. 次で確認する

```sh
tg_status
```

## 既存のペット状態を引き継ぐ

同じ companion state を新しいマシンでも使いたい場合:

1. 先に移植先マシンで Term-gotchi をインストールする
2. 旧マシンの `~/.termgotchi/state.json` を新マシンの `~/.termgotchi/state.json` にコピーする
3. ASCII アートも揃えたい場合は `~/.termgotchi/art/` もコピーする
4. 新しいシェルを開き、次を実行する

```sh
tg_status
```

推奨順序:

- 先に `zsh ./install.zsh` を実行する
- その後で `state.json` だけを置き換える

この順序にすると、新マシン側の runtime ファイルが現在のリポジトリ内容と揃います。

## 安全な移植チェックリスト

- 移植先に `zsh` がある
- 移植先に `jq` がある
- 古い state をコピーする前に repository から install している
- `~/.zshrc` に Term-gotchi の source 行が 1 つだけ入っている
- `tg_status` が動く
- `tg_feed` が動く
- `tg_train` が動く

## installer が変更するもの

installer が行う変更は次の範囲だけです。

- `~/.termgotchi/` を作成する
- runtime ファイルを `~/.termgotchi/` 配下にコピーする
- `state.json` が無ければ初期化する
- `.zshrc` に guarded source line を 1 行だけ追記する

追記される source 行:

```zsh
[[ -f "$HOME/.termgotchi/termgotchi.zsh" ]] && source "$HOME/.termgotchi/termgotchi.zsh" # termgotchi
```

## 壊れた state の復旧動作

移植先に不正な `~/.termgotchi/state.json` がすでにある場合:

- installer はそのファイルを `~/.termgotchi/backup/` に退避する
- 新しい state file を再作成する
- installer は終了コード `24` で終了する

これは「復旧付きで成功した」ことを意味し、単純な失敗ではありません。

## 移植先でのアンインストール

次を実行します。

```sh
zsh ./uninstall.zsh
```

その後、新しいシェルを開いてください。

削除されるもの:

- `~/.zshrc` の guarded Term-gotchi source 行
- `~/.termgotchi/`

## バージョン整合性の注意

マシン間で移動するときは次を推奨します。

- できるだけ同じ repository 内容を両方のマシンで使う
- 大きく変更された runtime code と古い `state.json` を混在させる場合は、移行直後に `tg_status` を必ず確認する
- 挙動が怪しい場合は `state.json` をバックアップし、再インストール後に再度コピーし直す

## トラブルシュート

`jq: command not found`

- `jq` をインストールする
- `zsh ./install.zsh` を再実行する

`tg_status: command not found`

- `~/.zshrc` に Term-gotchi の guarded source 行が入っているか確認する
- 新しいシェルを開くか `source ~/.zshrc` を実行する

移植後にシェル起動エラーが出る

- `~/.zshrc` に Term-gotchi の source 行が 1 つだけあるか確認する
- 必要なら `zsh -n ~/.zshrc` を実行する
- いったん Term-gotchi の source 行を外して再確認する

state が移行されない

- コピー先が正しく `~/.termgotchi/state.json` になっているか確認する
- `jq empty ~/.termgotchi/state.json` を実行する
- `tg_status` を再実行する
