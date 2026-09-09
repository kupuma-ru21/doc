# Figma Design References

> design.md の File Structure Plan / Components から抽出した「実装対象画面」と Figma ノードの対応表。
> 各エントリは Figma MCP 経由で実装対象に整合するか検証済み。
> 編集する場合は `/kiro-spec-figma {feature}` を再実行して再検証することを推奨。

## Inventory Summary

- **Generated at**: {{GENERATED_AT}}
- **Source design.md revision**: {{DESIGN_REVISION_NOTE}}
- **Total screens**: {{SCREEN_COUNT}}
- **Platforms covered**: {{PLATFORMS}} <!-- e.g. "web, mobile_app" -->

## Screens

<!--
各エントリの構成:
- ID: S1, S2, ... (連番)。tasks.md / 実装者プロンプトから参照されるため変更しないこと。
- Title: 画面・コンポーネントの人間可読名
- URL: 完全な Figma URL (フラグメントの node-id 含む)
- File Key / Node ID: MCP 呼び出し用に URL から抽出した値
- Platform: web | mobile_app
- Implementation target: 主要な実装ファイル / ディレクトリパス
- Related design components: design.md §Components の対応コンポーネント名
- Covers requirements: requirements.md の数値 ID (カンマ区切り)
- Verification: Figma MCP で確認した日時・方法・主観的判断
-->

### S1: {{SCREEN_TITLE_1}}

- **URL**: {{FIGMA_URL_1}}
- **File Key**: {{FILE_KEY_1}}
- **Node ID**: {{NODE_ID_1}}
- **Platform**: {{PLATFORM_1}}
- **Implementation target**: {{IMPL_TARGET_1}}
- **Related design components**: {{COMPONENTS_1}}
- **Covers requirements**: {{REQUIREMENTS_1}}
- **Verification**:
  - Date: {{VERIFIED_AT_1}}
  - Method: {{VERIFICATION_METHOD_1}} <!-- e.g. "figma.get_metadata + get_screenshot" -->
  - Verified node name: {{NODE_NAME_1}}
  - Match assessment: {{MATCH_ASSESSMENT_1}} <!-- 主観的に「対象画面で間違いなさそう」と判断できた要素を 1-3 行で記録 -->
  - User confirmation: {{USER_CONFIRMED_1}} <!-- true / false -->

<!-- Additional screens follow the same pattern (S2, S3, ...) -->

## Skipped Screens (Optional)

<!--
ユーザーが「この画面は Figma 不要」「後続 spec で扱う」等の理由でスキップした場合に記録。
スキップ理由を明示することで、後の `/markup-from-figma` 実行時に「なぜ figma.md にないか」が分かる。
-->

- **{{SKIPPED_SCREEN_NAME}}**: {{SKIP_REASON}}
