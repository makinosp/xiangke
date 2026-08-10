## Context

`power == 0` の技は「ステータス強化 / 回復 / 状態異常」の3系統に分かれる。現状
`action.rs::calculate_damage()`
は回復（`healing`）と状態異常（`effect`）のみを処理し、`stat_mod_stat` /
`stat_mod_stage` はパースされるが実行時に参照されない。さらに `build_damage_log`
は `power > 0` ブロック内でのみ呼ばれるため、非ダメージ技の `log_message`
は空になる。

データモデルに「対象」を表すフィールドが存在せず、`earth_barrier`
のような自己強化技と、相手弱体化技を区別できない。ステータスは `Stat`
enum（Attack=0..Spirit=4）で表現され、`BattleParticipant::apply_stat_stage(stat, delta)`
は既に実装済みだが呼び出し元がない。ブリッジは `part_dict` で `stat_stages`
をGDScriptへ往復させるため、Rust側で stage を変更すれば UI に反映される。

## Goals / Non-Goals

**Goals:**

- `MoveData` に `stat_mod_target`（対象指定）を追加し、`SELF` / `TARGET`
  を表現できるようにする。
- `calculate_damage` がステータス強化を実行時に適用し、`stat_stages`
  を更新する。
- 非ダメージ技にも `log_message`
  を生成し、バトルログに効果が表示されるようにする。
- 全レイヤ（コア→バトル→ブリッジ→GDScript→データ検証・エクスポート）を一貫して更新する。
- テストを追加して仕様との整合を検証する。

**Non-Goals:**

- AI 戦略（`BasicAi` /
  `_select_best_move`）の変更。非ダメージ技の使用判断は今回の対象外。
- `StatusEffectData.stat_mod_multiplier`（Charm
  等の状態異常由来ステータス変更）の実行時反映。別変更として扱う。
- `stat_mod_stage` の範囲仕様（spec の `[-6,+6]` とバリデータの `[-3,+3]`
  の食い違い）の是正。既存挙動を維持し、spec
  と実装の整合は別課題として記録する。

## Decisions

### 1. `stat_mod_target` の enum 値は `SELF = 0` / `TARGET = 1`

Rust と GDScript の両方で同じ数値表現を使う（既存の `Stat` / `TypeElement`
と同じ方針）。

```rust
#[repr(u8)]
pub enum StatModTarget {
    Self_ = 0,   // 攻撃者自身に適用
    Target = 1,  // 防御者に適用
}
```

- **GDScript** `scripts/type_enums.gd` に `enum StatModTarget { SELF, TARGET }`
  を追加。
- `move_data.gd` に
  `@export var stat_mod_target: int = TypeEnums.StatModTarget.SELF`
  を追加（デフォルト SELF = 後方互換）。
- **代替案**: bool `stat_mod_target_self`
  を検討したが、将来の拡張（味方全体等）を考え enum を採用。

### 2. `calculate_damage` での適用順序とログ生成

`calculate_damage` の冒頭（accuracy 判定後、`power > 0`
ブロックの前）にステータス強化処理を追加する。

```
1. accuracy 判定（miss なら終了）
2. if mv.has_stat_mod():
     target = if SELF { attacker } else { defender }
     target.apply_stat_stage(mv.stat_mod_stat, mv.stat_mod_stage)
     log_message += "{name}'s {stat} {rose|fell}!"
   （stage > 0 なら "rose"，< 0 なら "fell"，2段以上は "sharply" を付ける）
3. if mv.power > 0: 従来のダメージ処理（build_damage_log）
4. if mv.healing > 0: 回復処理
5. apply_status_effect
```

- `mv.has_stat_mod()`（既存メソッド）は
  `stat_mod_stat.is_some() && stat_mod_stage != 0`。
- `apply_stat_stage` は clamp 済みなので、既に上限に達している場合は stage
  が変わらない。ログは「試行」を記録する（既存の実効 stage
  を事前に読んで比較し、変化があればログを出す方式）。
- **ログ文言**: 既存の `build_damage_log` と同様に英語の Poké
  式文言を使う。`"{name}'s Defense rose sharply!"` 等。多言語対応は将来課題。
- **代替案**: ステータス技を別関数 `apply_stat_move()`
  に分離する案を検討したが、`calculate_damage` 内の既存フロー（accuracy →
  効果適用）と一貫させるため、同関数内に組み込む。

### 3. 非ダメージ技の `log_message` 保証

`power == 0`
の技でも、ステータス強化・状態異常・回復のいずれかが発生した場合は必ず
`log_message` を設定する。

- 現状、回復（`healing > 0`）と状態異常は既に処理されるが、ログが空のままのケースがある（`war_cry`
  等）。
- `ActionResult::log_message` が最終的に空の場合、フォールバックとして
  `"{name} used {move}!"` を設定する。これにより UI の `status_label`
  が空にならない。
- **代替案**: GDScript 側でフォールバックする案も検討したが、ログの真実源は Rust
  側なので Rust 側で完結させる。

### 4. データ検証・エクスポートの整合

- `validator.rs` の MR-4 に `stat_mod_target` の enum 妥当性チェック（`Self_=0`
  / `Target=1`）を追加。
- `systems/data/data_validator.gd` の MR-4 も同様に拡張。
- `tools/data_export.gd` に `stat_mod_target` をエクスポート。
- `xiangke_checker` の `MOVE_KEYS` を 14 → 15 に変更。
- `earth_barrier.tres` に `stat_mod_target = 0`（SELF）を設定。

### 5. テスト戦略

| レイヤ                                    | テスト内容                                                                                                                                                          |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Rust 単体（`action.rs`）                  | `power=0 + SELF + Defense+2` → 攻撃者 stage=2、ログに "rose"；`power=0 + TARGET + Attack-1` → 防御者 stage=-1、ログに "fell"；ゼロパワー技でも `log_message` が非空 |
| Rust 統合（`integration.rs`）             | 自己バフ技を含むバトルで `stat_stages` が更新される                                                                                                                 |
| GDScript（`test_battle_flow_service.gd`） | ブリッジ経由で自己バフ技を実行 → `get_front_participant(...).stat_stages` に反映される                                                                              |

## Risks / Trade-offs

- **ログ文言の英語固定** → UI
  が英語表記になる。将来のローカライズ課題として残す（現状の `build_damage_log`
  も英語）。
- **`stat_mod_target` デフォルト SELF** →
  既存データ（`earth_barrier`）は明示設定するため実害なし。未設定のデータが自己強化と解釈されるが、現状ステータス強化は全く動いていなかったので後方互換性は損なわれない。
- **Charm 由来の攻撃低下は未実装のまま** → `war_cry`
  の説明（「魅了して攻撃を下げる」）は部分的な実装になる。ただしこれは既存の
  `StatusEffectData.stat_mod_multiplier`
  の実行時反映という別課題であり、今回のスコープ外と明記する。
- **spec とバリデータの stage 範囲の食い違い** → 今回変更しない。`design.md`
  の非目標に記録し、別変更で仕様を整理する。
