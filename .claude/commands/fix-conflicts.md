---
description: 指定 URL の PR（単体 or ユーザーの PR 一覧）のうちコンフリクトしているものを、既存の挙動と新規の挙動を両立させる形で解消する
argument-hint: <GitHub PR URL | PR 一覧 URL>
allowed-tools: Read, Edit, Write, Bash, Grep, Glob, AskUserQuestion, Skill
---

# /fix-conflicts

入力: `$ARGUMENTS`

例:
- `/fix-conflicts https://github.com/sorajima-studio/workstation/pulls/kupuma-ru21` → そのユーザーの Open PR 全件が対象
- `/fix-conflicts https://github.com/sorajima-studio/workstation/pull/123` → PR #123 のみが対象

## ゴール

コンフリクトを「どちらかを捨てる」のではなく、**base ブランチ側（既存の挙動）と PR 側（新規の挙動）の両方の意図が成立する形** で解消し、静的チェックを通した上で PR ブランチに push する。

- 解消方法は **rebase** に統一する。**merge commit は作らない**（履歴を直線に保つため）。
- rebase は履歴を書き換えるため、**実行前に必ずバックアップブランチを作る**（失敗時や解消ミスに気づいたときに元の状態へ戻せるようにするため）。

## 手順

### 1. URL を解析して対象 PR を決める

- `$ARGUMENTS` が空なら AskUserQuestion で URL を聞く。
- URL から `owner/repo` を取り出す。
- パスの形で分岐する:
  - `/pull/<number>` → その PR 1 件
  - `/pulls/<user>` → `gh pr list -R <owner>/<repo> --author <user> --state open --json number,title,headRefName,baseRefName,mergeable,mergeStateStatus --limit 100`
  - `/pulls`（ユーザー指定なし）→ `--author @me` として扱う
- `mergeable` が `UNKNOWN` の PR は GitHub 側が未計算なので、数秒おいて `gh pr view <n> --json mergeable,mergeStateStatus` で再取得する（最大 3 回）。
- `mergeable == CONFLICTING`（または `mergeStateStatus == DIRTY`）の PR だけを対象にする。
- 対象 PR の一覧（番号 / タイトル / head → base）を表示する。0 件なら「コンフリクトしている PR はありません」と報告して終了。

### 2. 作業用リポジトリを用意する

- カレントディレクトリの `git remote get-url origin` が `<owner>/<repo>` と一致すれば、そのリポジトリを使う。
- 一致しなければ AskUserQuestion でローカルの clone パスを聞く（選択肢: 「パスを入力する」/「scratchpad に新規 clone する(推奨)」）。
- **ユーザーの作業ツリーを汚さないため**、PR ごとに git worktree を切って作業する:

```bash
git fetch origin <headRefName> <baseRefName>
git worktree add <scratchpad>/fix-conflicts/pr-<number> origin/<headRefName> -B fix-conflicts/pr-<number>
```

- fork からの PR（`isCrossRepository == true`）は push 先が異なるので、AskUserQuestion で対応方針を確認する。

### 3. 両側の「意図」を先に理解する（rebase 前に必ず行う）

コンフリクトマーカーだけを見て機械的に選ばないために、両側の変更目的を把握する。

- **新規側（PR）**: `gh pr view <n> --json title,body,commits` と `git log --oneline origin/<base>...origin/<head>` で PR の目的を把握する。
- **既存側（base）**: コンフリクトしたファイルごとに `git log --oneline <merge-base>..origin/<base> -- <file>` を見て、base に入った変更とその PR（コミットメッセージの `#123` 等）を確認し、何を実現するための変更かを把握する。

### 4. バックアップを取る

rebase の前に、PR ブランチの現在の状態をバックアップブランチとして残す。

```bash
BACKUP=backup/<headRefName>-$(date +%Y%m%d%H%M%S)
git branch "$BACKUP" origin/<headRefName>
git rev-parse "$BACKUP"   # バックアップの SHA を記録し、最終報告に含める
```

- バックアップが作れなかった場合は rebase に進まない。
- 復元が必要になったら `git rebase --abort`（rebase 中）か `git reset --hard "$BACKUP"`（rebase 後）で戻す。

### 5. rebase してコンフリクトを解消する

**merge ではなく rebase を使う。merge commit は禁止**（履歴を直線に保つため）。

```bash
git rebase origin/<baseRefName>
```

- PR ブランチに過去の merge commit が含まれていても `--rebase-merges` は付けない（merge commit を残さないため。通常の rebase で直線化される）。
- rebase はコミットを 1 つずつ適用するので、**コンフリクトしたコミットごとに** 解消 → `git add <file>` → `git rebase --continue` を繰り返す。
  - そのコミットが「何をするためのコミットか」（`git show REBASE_HEAD`）を確認してから解消する。そのコミットの意図以上の変更を混ぜない（後続コミットで余計なコンフリクトを生まないため）。
  - 解消した結果コミットが空になった場合のみ `git rebase --skip` を使う。base に同じ変更がすでに入っていることを確認してから使うこと。
- rebase 中の ours / theirs は merge と逆になる点に注意する（`ours` = base 側（既存）、`theirs` = PR のコミット（新規））。

- `resolve-conflicts` skill が使える環境なら読み込み、Pattern Catalog に該当するパターン（例: atlas migration の out-of-order）を優先的に適用する。
- 各コンフリクトハンクを以下の方針で解消する:

| 状況 | 解消方針 |
| --- | --- |
| 両側が別々の要素を追加（import / 関数 / フィールド / 設定キー / テストケース等） | **両方残す**。順序に意味がある場合は base の並びを維持しつつ PR 側を追加 |
| base 側でリネーム・シグネチャ変更・移動、PR 側で旧名を使った追加 | **base の新しい形に合わせて PR 側のコードを書き換える**（PR の機能は維持） |
| 同じ関数の中で base はバグ修正 / 条件追加、PR は機能追加 | **両方のロジックを合成する**（base の修正を落とさない） |
| base 側でファイル / 関数を削除、PR 側で同じ箇所を変更 | 削除理由を確認し、移行先があればそちらに PR の変更を移植。判断不能なら AskUserQuestion |
| lockfile・生成物（`*.lock`, `generated/`, `gen/` 等） | 手編集しない。base 側を採用した上で、ソースから再生成する |
| 両側の仕様が真っ向から矛盾し、両立できない | **推測でどちらかを選ばない**。AskUserQuestion で両案を提示して判断を仰ぐ |

- コンフリクトマーカーが出ていない **自動で適用されたファイル（コンフリクトしなかったもの）も確認する**（例: base で削除された関数を PR 側の別ファイルが呼んでいる、といった「テキストは通るが意味的に壊れる」ケース）。
- 各コミットで `git rebase --continue` する前に、`git diff --check` と `grep -rn '^<<<<<<<\|^>>>>>>>\|^=======$'` でマーカーが残っていないことを確認する。
- rebase 完了後に `git log --merges origin/<baseRefName>..HEAD` が空であること（merge commit が無いこと）を確認する。

### 6. 静的チェックとテストで両立を検証する

- リポジトリの設定ファイル（`Makefile`, `package.json`, `go.mod`, `pubspec.yaml` 等）を確認し、該当する lint / typecheck / build / test を実行する。
  - 変更があったディレクトリに絞って実行してよい（例: `web/` のみなら `cd web && yarn check-all`）。
- **エラーが 0 になるまで修正を繰り返す**。修正時も「既存の挙動」「新規の挙動」のどちらかを削って通すことはしない。
- base 側・PR 側それぞれのテストが両方通ることをもって「両立できた」と判断する。
- 静的チェックを通すための修正は、原因になったコミットに `git commit --fixup <sha>` してから `git rebase -i --autosquash` 相当（`GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash origin/<baseRefName>`）で取り込む。末尾に修正コミットを足してもよいが、merge commit は作らない。
- 意図しない変更が混ざっていないか、`git range-diff origin/<baseRefName> "$BACKUP" HEAD` で rebase 前後のコミットを比較する。

### 7. force push する

- rebase で履歴が変わるので、push は `--force-with-lease` を使う（バックアップ取得後に他の人が push していた場合に上書きしないため）:

```bash
git push --force-with-lease=<headRefName>:$(git rev-parse "$BACKUP") origin HEAD:<headRefName>
```

- push は外部に影響するため、**PR ごとに `range-diff` の要約と解消内容を提示し、AskUserQuestion で確認してから** 実行する（選択肢: 「force push する(推奨)」/「push せずローカルに残す」）。
- `--force-with-lease` が拒否されたら、リモートに新しいコミットがあるということ。上書きせずユーザーに報告する。
- push 後に `gh pr view <n> --json mergeable,mergeStateStatus` で `MERGEABLE` になったことを確認する。
- 完了した worktree は `git worktree remove` で片付ける。バックアップブランチは **削除せず残す**（ユーザーが確認して不要と判断してから消すため）。

### 8. 結果を報告する

PR ごとに以下をまとめて報告する:

- `BACKUP`: バックアップブランチ名と SHA、復元コマンド（`git reset --hard <backup>` → `git push --force-with-lease`）
- `RESOLVED`: コンフリクトしたコミット / ファイルと、それぞれ既存 / 新規の挙動をどう両立させたか（1 行ずつ）
- `ASKED`: ユーザーに判断を仰いだ点とその結論
- `VERIFICATION`: 実行した静的チェック / テストと結果
- `SKIPPED`: 対象外・未 push の PR とその理由

## やってはいけないこと

- merge commit を作る（`git merge`、`git pull`（rebase なし）、`--rebase-merges` を含む）
- バックアップを取らずに rebase する
- `--force-with-lease` を付けずに `git push --force` する
- `git checkout --ours` / `--theirs` でファイル単位に片側を丸ごと採用する（lockfile・生成物を除く）
- 両立できない箇所を推測で解消する
- 静的チェックが失敗したまま push する
