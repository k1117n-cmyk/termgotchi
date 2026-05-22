# Term-gotchi ノートPCセットアップ

ノートPC側で `termgotchi` を使うための最小手順です。

## 初回セットアップ

1. リポジトリのルートで installer を実行する

```sh
zsh ./install.zsh
```

2. shell 設定を読み直す

```sh
source ~/.zshrc
```

3. runtime が入ったことを確認する

```sh
tg_version
tg_status
```

`tg_version` で runtime version と state schema version を確認できる。

## デスクトップから state を持ってくる

同じ個体を引き継ぐ場合は、デスクトップ側の `~/.termgotchi/state.json` を AirDrop で送り、ノート側の同じ場所に置き換える。

詳細手順は [airdrop-operation-ja.md](./airdrop-operation-ja.md) を参照。

## リポジトリ更新後

リポジトリ内の `termgotchi.zsh` を更新しただけでは、shell が読む `~/.termgotchi/termgotchi.zsh` は更新されない。

コマンド追加や修正を取り込むには、ノートPC側でも再度 installer を実行する:

```sh
zsh ./install.zsh
source ~/.zshrc
tg_version
```

## 運用ルール

- 普段はデスクトップを正本にする
- ノートで使う前に必要なら最新 `state.json` を受け取る
- 2台で同時に育成しない
- `tg_version` が想定どおりか確認してから使う
