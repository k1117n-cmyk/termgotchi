# Term-gotchi ノートPC Git運用

ノートPC側で `termgotchi` のコードを安全に管理するための手順です。

この文書はコード同期だけを対象にします。ペットの状態は `~/.termgotchi/state.json` にあり、Git では管理しません。

## 現在の構成

- ノートPC側の作業リポジトリ: この `termgotchi` ディレクトリ
- `origin`: `~/Library/Mobile Documents/com~apple~CloudDocs/git-remotes/termgotchi.git`
- 同期対象: リポジトリ内のコードとドキュメント
- 同期対象外: `~/.termgotchi/state.json`

## 最初に確認すること

リポジトリのルートで次を実行する:

```sh
git status
git remote -v
```

期待する状態:

- `git status` が `nothing to commit, working tree clean`
- `git remote -v` に `origin` として iCloud Drive 上の bare repository が出る

## ノートPCで日常的に作業する手順

1. 作業前に状態確認

```sh
git status
git pull
```

2. 必要なファイルを編集する

3. `termgotchi.zsh` や `install.zsh` を変えた場合は runtime を入れ直す

```sh
zsh ./install.zsh
source ~/.zshrc
tg_version
```

4. 動作確認する

```sh
tg_status
```

5. 変更を記録する

```sh
git status
git add .
git commit -m "Describe the change"
git push
```

## 別マシンと併用するときのルール

- 同時に 2 台でコード変更しない
- 作業を始める前に `git pull` する
- 作業を終えたら `git push` する
- iCloud の同期が落ち着く前に別マシンで `git pull` しない

## `state.json` を分けている理由

`state.json` はコードではなく実行中データなので、Git に入れると競合しやすい。

特に次の値は 2 台で使うとすぐずれる:

- `xp`
- `command_count`
- `last_active_at`
- `updated_at`

そのため、コードは Git で同期し、個体状態は必要な時だけ手動コピーする。

## 個体状態を引き継ぎたいとき

コード同期とは別に、必要な時だけ `~/.termgotchi/state.json` を手動コピーする。

推奨順序:

1. ノートPC側で `git pull`
2. 必要なら `zsh ./install.zsh`
3. デスクトップ側の `state.json` をノートPC側へコピー
4. `tg_status` で確認

## よく使うコマンド

```sh
git status
git diff
git pull
git add .
git commit -m "Message"
git push
git remote -v
```

## トラブルシュート

`git pull` で衝突した

- 片方のマシンで未 push の変更がないか確認する
- `git status` と `git diff` を見て、何が変わっているか確認する
- 急いで上書きせず、差分を整理してから commit する

`git push` が失敗した

- 先に別マシンから push されていないか確認する
- iCloud Drive の同期待ちが必要でないか確認する
- まず `git pull` を試す

`tg_status` の結果がおかしい

- `git pull` 後に `zsh ./install.zsh` を再実行する
- `source ~/.zshrc` を実行する
- 必要なら `state.json` を入れ直す
