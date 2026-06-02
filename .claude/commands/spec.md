# /spec コマンド

`$ARGUMENTS` を判定して以下を実行してください：

## 引数が `.md` で終わる場合（既存ファイルの読み込み）
以下のBashコマンドを実行してファイルを読み込む：
```bash
cat {引数のパス}
```

- @~/.claude/skills/task-design/SKILL.md を読み込んで実行する

## 引数が2つの場合（新規ファイル作成）
- 1番目: ディレクトリの作成先パス
- 2番目: タイムスタンプ付きディレクトリ名のベース
```bash
DIR={1番目の引数}
NAME={2番目の引数}
TIMESTAMP=$(date +%Y%m%d%H%M%S)
mkdir -p "${DIR}/${TIMESTAMP}_${NAME}"
touch "${DIR}/${TIMESTAMP}_${NAME}/spec.md"
echo "✅ ${DIR}/${TIMESTAMP}_${NAME}/spec.md を作成しました"
```
```

新規ファイル作成したら「skills/task-design/SKILL.md」を読み込み、実行する

使い分け：
```
/spec dir test            → dir/20250313143022_test/spec.md を作成
/spec XXXX/spec.md        → ファイルを読み込んで仕様理解フェーズ開始

# /frontend コマンド

1. 仕様書のディレクトリの入力を求める
2. 該当の仕様書を読み込む
3. 「skills/frontend-design/SKILL.md」を読み込み、実行する

---

# /backend コマンド

1. 仕様書のディレクトリの入力を求める
2. 該当の仕様書を読み込む
3. 「skills/backend-design/SKILL.md」を読み込み、実行する

