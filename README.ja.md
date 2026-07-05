# Term-gotchi

Term-gotchi は `zsh` 向けのターミナルコンパニオンです。  
普段のコマンドライン作業を、英語学習の雰囲気を持った軽い育成ゲームに変えます。

## 関連記事

- [Term-gotchi: zshで育てるミニペットアプリ](https://pc-fan.net/term-gotchi-zsh-mini-pet-app/)
- [Term-gotchi 成長記録: shell hook から buddy まで](https://pc-fan.net/term-gotchi-growth-history/)
- [Term-gotchi tg_talk: ターミナルで英語練習](https://pc-fan.net/term-gotchi-tg-talk-english-practice/)
- [Term-gotchi を Git / GitHub で配布する](https://pc-fan.net/term-gotchi-git-github-distribution/)

## コンセプト

- 普段のターミナル作業が成長の入力になる
- コンパニオンは英語コマンドに反応する
- コマンドの種類と継続利用でレベルアップや進化が進む
- ターミナルの実用性は維持し、既存の shell ワークフローを壊さない

## 現在の状態

初期実装はすでに始まっています。  
安全なインストーラ、ランタイムローダー、初期 state、`tg_status`、お世話コマンド、`tg_train`、放置による減衰、通常コマンドからの受動 XP フックが入っています。

## インストール

GitHub から clone した場合:

1. `zsh` と `jq` が使えることを確認する
2. リポジトリのルートで `zsh ./install.zsh` を実行する
3. 新しい shell を開くか、`source ~/.zshrc` を実行する
4. `tg_version` と `tg_status` で確認する

Release パッケージを使う場合:

1. `termgotchi-<version>.tar.gz` または `termgotchi-<version>.zip` をダウンロードして展開する
2. 展開したディレクトリに移動する
3. `zsh ./install.zsh` を実行する
4. 新しい shell を開くか、`source ~/.zshrc` を実行する
5. `tg_version` と `tg_status` で確認する

## アンインストール

1. リポジトリのルートで `zsh ./uninstall.zsh` を実行する
2. 新しい shell を開く

## 安全性に関するメモ

- インストール時の書き込み先は `~/.termgotchi/` 配下と、`~/.zshrc` への保護付き 1 行の追記だけ
- フック登録は対話的な `zsh` でのみ行う
- 受動 XP では `tg_*`、`source`、`.`、`alias`、`autoload`、`history`、`setopt`、`export` などの shell メタコマンドに加え、`command`、`builtin`、`noglob` などのラッパー接頭辞を除外する
- state 書き込みは一時ファイル経由 + `mv` で行う
- インストーラが壊れた `state.json` を見つけた場合は、`~/.termgotchi/backup/` に退避して再生成する
- インストーラの終了コード `24` は、無効な state ファイルを退避したうえで復旧に成功したことを意味する
- `tg_status` は、現在の状態要約より直近イベントの方が有益な場合に `Recent:` 行を表示することがある

## 予定している MVP

- `install.zsh` が `~/.termgotchi/` に必要ファイルを配置する
- `termgotchi.zsh` を `.zshrc` から読み込む
- `tg_status` が現在状態と ASCII アートを表示する
- `tg_feed`、`tg_clean`、`tg_talk`、`tg_train` で直接インタラクションできる
- 通常コマンドが `preexec` / `precmd` 経由で XP を与える
- レベルアップとシンプルな進化:
  - `egg -> sprout`
  - `sprout -> buddy`

## 予定ディレクトリ構成

```text
termgotchi/
  README.md
  README.ja.md
  NEXT.md
  install.zsh
  uninstall.zsh
  termgotchi.zsh
  art/
    egg.txt
    sprout.txt
    buddy.txt
  docs/
    spec.md
    architecture.md
    implementation-plan.md
```

## ドキュメント

- [`README.md`](./README.md): English README
- [`docs/spec.md`](./docs/spec.md): プロダクト仕様と挙動仕様
- [`docs/architecture.md`](./docs/architecture.md): インストールと実行時の構成
- [`docs/implementation-plan.md`](./docs/implementation-plan.md): MVP の段階と実装順
- [`docs/porting-manual.md`](./docs/porting-manual.md): 他の Mac / PC へ移す手順
- [`docs/porting-manual.ja.md`](./docs/porting-manual.ja.md): 移植マニュアル日本語版
- [`docs/notebook-setup-ja.md`](./docs/notebook-setup-ja.md): ノートPC移行メモ
- [`docs/notebook-git-workflow-ja.md`](./docs/notebook-git-workflow-ja.md): ノートPCとの Git 運用手順
- [`NEXT.md`](./NEXT.md): 次回作業再開用メモ

## 配布パッケージ

GitHub Releases に置くためのポータブルパッケージを作成できます。

```sh
zsh ./scripts/package.zsh
```

作成されるもの:

- `dist/termgotchi-<version>/`
- `dist/termgotchi-<version>.tar.gz`
- `dist/termgotchi-<version>.zip`
- `dist/termgotchi-<version>.checksums.txt`

パッケージには、ランタイム、インストーラ、アンインストーラ、ASCII アート、主要ドキュメントが入ります。

## MVP の優先順位

1. 安全なインストールと shell 統合
2. `tg_status` と永続 state
3. お世話コマンド: `tg_feed`、`tg_clean`、`tg_talk`
4. 通常コマンドからの受動的な成長
5. レベルアップと進化
6. 最小限の放置減衰

## MVP でやらないこと

- 複数 shell 対応
- 完全な TUI
- クラウド同期
- 高度な AI 会話
- 複雑な性格分岐
- 単純な形態進化を超える種族分岐

## 設計上の制約

- まずは `zsh` を優先する
- `.zshrc` への変更は最小限にする
- ユーザーの shell function を直接上書きしない
- state 処理が壊れたら安全側に倒す
- データは `~/.termgotchi/` に置く
