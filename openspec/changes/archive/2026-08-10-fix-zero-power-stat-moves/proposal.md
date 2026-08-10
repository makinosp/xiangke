## Why

`power = 0` の技（ステータス強化・回復・状態異常技）のうち、`earth_barrier`
のような **ステータス強化技が発動しても何も効果が発生しない**
バグがある。`action.rs::calculate_damage()` が `stat_mod_stat` /
`stat_mod_stage` を一切参照しておらず、仕様（`domain`
spec）で約束された「stat_mod_stat
が設定されていれば参加者のステータスが変更される」が実装されていないため。加えて、非ダメージ技は
`build_damage_log` が `power > 0` ブロック内でのみ呼ばれるため `log_message`
が空になり、**技が発動していないように見える**。

## What Changes

- `MoveData` に **`stat_mod_target`**（`SELF` = 自分 / `TARGET` =
  相手）フィールドを追加し、ステータス強化の適用対象を指定できるようにする（現状、対象を表現する手段がなく
  `earth_barrier` のような自己強化技を実装できない）。
- `action.rs::calculate_damage()` にステータス強化の適用ロジックを追加する：
  - `SELF` → 攻撃者に `apply_stat_stage(stat, stage)` を適用
  - `TARGET` → 防御者に `apply_stat_stage(stat, stage)` を適用
- 非ダメージ技（`power == 0`）にも **ログメッセージを生成**
  し、バトルログに技の効果（バフ/デバフ/回復/状態異常）が表示されるようにする。
- ステータス強化の適用を検証するテストを追加する（Rust 単体・統合、GDScript
  ブリッジ）。
- 既存の `earth_barrier.tres` に `stat_mod_target = SELF` を設定する。

**BREAKING**: なし（既存フィールドの変更ではなく、フィールド追加のみ）。

## Capabilities

### New Capabilities

- なし（既存能力の修正のみ。新たな能力の導入は行わない）。

### Modified Capabilities

- `domain`: Move Data に `stat_mod_target`
  要件を追加し、「ステータス強化技が実行時に適用される」シナリオを追加する。Stat
  Stage Multipliers 要件の実行時適用を明確化する。
- `rust-bridge`: `dict_move` のデータ変換が `stat_mod_target`
  をパース/直列化することを追加する。
- `front-line-battle`:
  自己対象（SELF）のステータス技が相手フロントを対象としない例外であることを明文化する。

## Impact

- **Rust コア**: `extensions/core/src/types.rs`（`StatModTarget` enum
  追加）、`extensions/core/src/moves.rs`（`MoveData.stat_mod_target`
  追加）、`extensions/core/src/validator.rs`（MR-4 に target
  妥当性チェック追加）
- **Rust バトル**: `extensions/battle/src/action.rs`（`calculate_damage` に
  stat_mod 適用 + 非ダメージ技ログ生成）
- **Rust ブリッジ**: `extensions/godot_bridge/src/lib.rs`（`dict_move` に
  `stat_mod_target` パース追加）
- **GDScript**: `scripts/type_enums.gd`（`StatModTarget` enum
  追加）、`scripts/move_data.gd`（`stat_mod_target`
  エクスポート追加）、`resources/moves/earth_barrier.tres`（`stat_mod_target = 0`
  設定）
- **データ検証**: `systems/data/data_validator.gd`（MR-4
  拡張）、`tools/data_export.gd`（エクスポートJSON に `stat_mod_target`
  追加）、`extensions/tools/xiangke_checker`（`MOVE_KEYS` 14→15）
- **テスト**:
  `extensions/battle/src/action.rs`（単体）、`extensions/battle/tests/integration.rs`（統合）、`tests/unit/test_battle_flow_service.gd`（ブリッジ）
- **対象外**: AI 戦略（`BasicAi` /
  `_select_best_move`）は非ダメージ技を使い続けない（変更しない）
