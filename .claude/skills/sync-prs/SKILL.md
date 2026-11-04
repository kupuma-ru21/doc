---
name: sync-prs
description: 指定 URL の PR（単体 or ユーザーの PR 一覧）すべてに最新の base ブランチを rebase で取り込む。main => XXX => YYY のようなスタック PR は親から順に処理し、XXX に main を取り込んでから YYY に XXX を取り込む。コンフリクトが出た場合は既存の挙動と新規の挙動を両立させる形で解消する。「PR を最新化して」「base を取り込んで」「PR を main に追従させて」「コンフリクト解消して」と言われたときに使う。
argument-hint: <GitHub PR URL | PR 一覧 URL>
allowed-tools: Read, Edit, Write, Bash, Grep, Glob, AskUserQuestion, Skill
---

# /sync-prs

入力: `$ARGUMENTS`

例:
- `/sync-prs https://github.com/sorajima-studio/workstation/pulls/kupuma-ru21` → そのユーザーの Open PR 全件が対象
- `/sync-prs https://github.com/sorajima-studio/workstation/pull/123` → PR #123（と、それが属するスタック）が対象

## ゴール

対象の **全 PR** に最新の base ブランチを取り込み、base に追従した状態にする（コンフリクトしている PR だけではない）。

- スタック PR（`main => XXX => YYY`、つまり YYY の base が XXX の head ブランチ）は **親から順に** 処理する。XXX に main を取り込んでから、更新後の XXX を YYY に取り込む（子を先に処理すると、親の更新後にもう一度やり直しになるため）。
- 取り込み方法は **rebase** に統一する。**merge commit は作らない**（履歴を直線に保つため）。
- rebase は履歴を書き換えるため、**実行前に必ずバックアップブランチを作る**（失敗時や解消ミスに気づいたときに元の状態へ戻せるようにするため）。
- コンフリクトが出た場合は「どちらかを捨てる」のではなく、**base 側（既存の挙動）と PR 側（新規の挙動）の両方の意図が成立する形** で解消する（手順 5）。

## 手順

### 1. URL を解析して対象 PR を決める

- `$ARGUMENTS` が空なら AskUserQuestion で URL を聞く。
- URL から `owner/repo` を取り出す。
- まず、スタック判定のためにリポジトリの Open PR を全件取得する（対象外の PR がスタックの親になっている場合もあるため）:

```bash
gh pr list -R <owner>/<repo> --state open --limit 200 \
  --json number,title,author,headRefName,baseRefName,headRefOid,isCrossRepository,mergeable,mergeStateStatus
```

- パスの形で「起点となる PR」を決める:
  - `/pull/<number>` → その PR 1 件
  - `/pulls/<user>` → `author.login == <user>` の PR
  - `/pulls`（ユーザー指定なし）→ 自分（`gh api user --jq .login`）の PR

### 2. スタック（親子関係）を組み立てて処理順を決める

- PR A の `baseRefName` が、別の Open PR B の `headRefName` と一致する場合、**B が親・A が子** とみなす。
- 起点 PR が属するスタックは **祖先と子孫も対象に含める**:
  - 祖先: 子に親の最新を取り込むには、先に親を最新化する必要があるため。
  - 子孫: 親を rebase するとコミット SHA が変わり、子が古い親コミットを抱えたままになるため。
  - 起点以外の PR（他人の PR など）を含めることになる場合は、その PR を一覧で明示し、AskUserQuestion で含めてよいか確認する（選択肢:「含める(推奨)」/「そのスタックごと対象外にする」）。
- 親が Open PR でない base（`main` 等）を持つ PR をスタックの根とし、**根 → 子 → 孫の順（トポロジカル順）** に並べる。複数のスタックは独立に処理してよいが、同時並行はせず 1 スタックずつ進める。
- 処理順の一覧（スタックごとに `main => #12 XXX => #34 YYY` の形）を表示する。

### 3. 作業用リポジトリを用意する

- カレントディレクトリの `git remote get-url origin` が `<owner>/<repo>` と一致すれば、そのリポジトリを使う。
- 一致しなければ AskUserQuestion でローカルの clone パスを聞く（選択肢:「パスを入力する」/「scratchpad に新規 clone する(推奨)」）。
- **ユーザーの作業ツリーを汚さないため**、PR ごとに git worktree を切って作業する:

```bash
git fetch origin <関係する全 headRefName と baseRefName>
git worktree add <scratchpad>/sync-prs/pr-<number> origin/<headRefName> -B sync-prs/pr-<number>
```

- fork からの PR（`isCrossRepository == true`）は push 先が異なるので、AskUserQuestion で対応方針を確認する。

### 4. バックアップを取る

rebase の前に、対象の **全 PR** の現在の状態をバックアップブランチとして残す。スタックの子の rebase では、親の **rebase 前の SHA** が必要になるため、ここで記録した値を使う。

```bash
BACKUP=backup/<headRefName>-$(date +%Y%m%d%H%M%S)
git branch "$BACKUP" origin/<headRefName>
git rev-parse "$BACKUP"   # バックアップの SHA（= OLD_SHA）を記録し、最終報告に含める
```

- バックアップが作れなかった場合は rebase に進まない。
- 復元が必要になったら `git rebase --abort`（rebase 中）か `git reset --hard "$BACKUP"`（rebase 後）で戻す。

### 5. 処理順に 1 PR ずつ rebase する

処理順（手順 2）に従い、各 PR で以下を行う。**取り込み先（NEW_BASE）は PR の位置で変わる**:

| PR の位置 | NEW_BASE | rebase コマンド |
| --- | --- | --- |
| スタックの根（base が `main` 等） | `origin/<baseRefName>` | `git rebase origin/<baseRefName>` |
| スタックの子（base が親 PR の head） | 親の **rebase 後の** ローカルブランチ `sync-prs/pr-<親>` | `git rebase --onto sync-prs/pr-<親> $(git merge-base <親の OLD_SHA> HEAD)` |

- 子で `--onto` を使う理由: 子ブランチには親の **古い** コミットが含まれている。素の `git rebase <新しい親>` だと、内容が同じでも SHA の違う親コミットを再適用しようとして不要なコンフリクトが出る。`merge-base(親の OLD_SHA, 子)` 以降の **子自身のコミットだけ** を新しい親の上に載せ替える。
- 子の NEW_BASE を `origin/<親>` ではなくローカルの `sync-prs/pr-<親>` にする理由: push はスタック単位でまとめて行う（手順 7）ため、この時点では親の更新はまだリモートに無い。

#### 5-1. 取り込み不要な PR はスキップする

- `git merge-base --is-ancestor <NEW_BASE> HEAD` が成功する（すでに NEW_BASE を含んでいる）PR は rebase 不要。`SKIPPED (up to date)` として記録し、次の PR に進む。
  - GitHub の `mergeStateStatus == BEHIND` はブランチ保護で「最新化必須」が有効なときしか出ないため、判定には使わない。

#### 5-2. 両側の「意図」を先に理解する（rebase 前に必ず行う）

コンフリクトが出たときにマーカーだけを見て機械的に選ばないために、両側の変更目的を把握する。

- **新規側（PR）**: `gh pr view <n> --json title,body,commits` と `git log --oneline <NEW_BASE>...HEAD` で PR の目的を把握する。
- **既存側（base）**: コンフリクトしたファイルごとに `git log --oneline <merge-base>..<NEW_BASE> -- <file>` を見て、base に入った変更とその PR（コミットメッセージの `#123` 等）を確認し、何を実現するための変更かを把握する。

#### 5-3. rebase を実行し、コンフリクトがあれば解消する

**merge ではなく rebase を使う。merge commit は禁止**（履歴を直線に保つため）。

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

- コンフリクトマーカーが出ていない **自動で適用されたファイル（コンフリクトしなかったもの）も確認する**（例: base で削除された関数を PR 側の別ファイルが呼んでいる、といった「テキストは通るが意味的に壊れる」ケース）。コンフリクトが 1 つも出なかった PR も同様に確認する。
- 各コミットで `git rebase --continue` する前に、`git diff --check` と `grep -rn '^<<<<<<<\|^>>>>>>>\|^=======$'` でマーカーが残っていないことを確認する。
- rebase 完了後に `git log --merges <NEW_BASE>..HEAD` が空であること（merge commit が無いこと）を確認する。
- 解消できずに中断した PR がある場合、**その子孫の PR には進まない**（壊れた親の上に子を載せないため）。子孫は `SKIPPED (parent failed)` として記録する。

### 6. 静的チェックとテストで両立を検証する

- rebase した PR ごとに、リポジトリの設定ファイル（`Makefile`, `package.json`, `go.mod`, `pubspec.yaml` 等）を確認し、該当する lint / typecheck / build / test を実行する。
  - 変更があったディレクトリに絞って実行してよい（例: `web/` のみなら `cd web && yarn check-all`）。
  - 複数 PR のチェックを並列で走らせない（Mac の発熱対策。1 PR ずつ順番に実行する）。
- **エラーが 0 になるまで修正を繰り返す**。修正時も「既存の挙動」「新規の挙動」のどちらかを削って通すことはしない。
- base 側・PR 側それぞれのテストが両方通ることをもって「両立できた」と判断する。
- 静的チェックを通すための修正は、原因になったコミットに `git commit --fixup <sha>` してから `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <NEW_BASE>` で取り込む。末尾に修正コミットを足してもよいが、merge commit は作らない。
  - 親 PR に修正を入れた場合は親の HEAD が変わるので、**その子孫を手順 5 からやり直す**（子の `--onto` 先が古い親になってしまうため）。
- 意図しない変更が混ざっていないか、`git range-diff <merge-base(OLD_SHA, 旧 base)>.."$BACKUP" <NEW_BASE>..HEAD`（根の PR は `git range-diff origin/<baseRefName> "$BACKUP" HEAD` でよい）で rebase 前後のコミットを比較する。

### 7. スタック単位で force push する

- push は外部に影響するため、**スタックごとに** 各 PR の `range-diff` の要約・解消内容・チェック結果を提示し、AskUserQuestion で確認してから実行する（選択肢:「force push する(推奨)」/「push せずローカルに残す」）。
  - スタック単位にする理由: 親だけ push して子を放置すると、子の PR 差分に親の古いコミットが混ざって見える中途半端な状態になるため。
- rebase で履歴が変わるので、`--force-with-lease` に各 PR の OLD_SHA を指定し、`--atomic` でスタック内をまとめて push する（バックアップ取得後に他の人が push していた場合に上書きしないため / 一部だけ push される状態を避けるため）:

```bash
git push --atomic origin \
  --force-with-lease=<XXX headRefName>:<XXX の OLD_SHA> sync-prs/pr-<XXX>:<XXX headRefName> \
  --force-with-lease=<YYY headRefName>:<YYY の OLD_SHA> sync-prs/pr-<YYY>:<YYY headRefName>
```

- スキップした（取り込み不要だった）PR は push しない。
- `--force-with-lease` が拒否されたら、リモートに新しいコミットがあるということ。上書きせずユーザーに報告する。
- push 後に `gh pr view <n> --json mergeable,mergeStateStatus` で `CONFLICTING` / `DIRTY` でないことを確認する。
- 完了した worktree は `git worktree remove` で片付ける。バックアップブランチは **削除せず残す**（ユーザーが確認して不要と判断してから消すため）。

### 8. 結果を報告する

スタックごとに処理順（`main => #12 => #34`）を示し、PR ごとに以下をまとめて報告する:

- `STATUS`: `UPDATED`（rebase して push）/ `UP TO DATE`（取り込み不要）/ `LOCAL ONLY`（push せず）/ `FAILED`
- `BACKUP`: バックアップブランチ名と SHA、復元コマンド（`git reset --hard <backup>` → `git push --force-with-lease`）
- `RESOLVED`: コンフリクトしたコミット / ファイルと、それぞれ既存 / 新規の挙動をどう両立させたか（1 行ずつ。コンフリクトが無ければ「なし」）
- `ASKED`: ユーザーに判断を仰いだ点とその結論
- `VERIFICATION`: 実行した静的チェック / テストと結果
- `SKIPPED`: 対象外・未 push の PR とその理由（`parent failed` 等）

## やってはいけないこと

- merge commit を作る（`git merge`、`git pull`（rebase なし）、`--rebase-merges` を含む）
- スタックの子を親より先に処理する / 親を更新したのに子を古い親の上に残す
- スタックの子を `--onto` なしで新しい親に rebase する（古い親コミットが二重に適用される）
- バックアップを取らずに rebase する
- `--force-with-lease` を付けずに `git push --force` する
- `git checkout --ours` / `--theirs` でファイル単位に片側を丸ごと採用する（lockfile・生成物を除く）
- 両立できない箇所を推測で解消する
- 静的チェックが失敗したまま push する
