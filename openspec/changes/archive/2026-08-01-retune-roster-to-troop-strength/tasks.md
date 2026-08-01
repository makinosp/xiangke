# Tasks: Retune Roster to Troop Strength

## 1. Shields — HP → DEF (40-point transfer)

- [x] 1.1 `dian_wei.tres`: hp 140 → 100, defense 112 → 152
- [x] 1.2 `xu_chu.tres`: hp 140 → 100, defense 105 → 145
- [x] 1.3 `xia_hou_dun.tres`: hp 125 → 85, defense 105 → 145

## 2. Strategists — HP +25 / DEF −25

- [x] 2.1 `zhuge_liang.tres`: hp 85 → 110, defense 60 → 35
- [x] 2.2 `si_ma_yi.tres`: hp 90 → 115, defense 70 → 45
- [x] 2.3 `zhou_yu.tres`: hp 90 → 115, defense 65 → 40
- [x] 2.4 `lu_xun.tres`: hp 100 → 125, defense 90 → 65
- [x] 2.5 `guo_jia.tres`: hp 85 → 110, defense 75 → 50
- [x] 2.6 `xun_yu.tres`: hp 90 → 115, defense 85 → 60
- [x] 2.7 `pang_tong.tres`: hp 90 → 115, defense 80 → 55
- [x] 2.8 `chen_gong.tres`: hp 95 → 120, defense 85 → 60
- [x] 2.9 `zhang_jiao.tres`: hp 95 → 120, defense 85 → 60

## 3. Rulers — HP +5 / DEF −5

- [x] 3.1 `dong_zhuo.tres`: hp 145 → 150, defense 95 → 90
- [x] 3.2 `cao_cao.tres`: hp 130 → 135, defense 85 → 80
- [x] 3.3 `yuan_shao.tres`: hp 120 → 125, defense 90 → 85
- [x] 3.4 `sun_ce.tres`: hp 120 → 125, defense 90 → 85
- [x] 3.5 `liu_bei.tres`: hp 115 → 120, defense 95 → 90
- [x] 3.6 `sun_quan.tres`: hp 110 → 115, defense 85 → 80

## 4. Warriors — targeted adjustments

- [x] 4.1 `lu_bu.tres`: hp 100 → 95, defense 70 → 75 (glass cannon)
- [x] 4.2 `huang_zhong.tres`: hp 85 → 90, defense 70 → 65 (veteran commander)
- [x] 4.3 `lv_meng.tres`: hp 110 → 115, defense 95 → 90 (warrior treatment)

## 5. Non-military — HP −10 / DEF +10

- [x] 5.1 `da_qiao.tres`: hp 85 → 75, defense 80 → 90
- [x] 5.2 `zhen_ji.tres`: hp 90 → 80, defense 80 → 90
- [x] 5.3 `diao_chan.tres`: hp 75 → 65, defense 50 → 60
- [x] 5.4 `huang_yue_ying.tres`: hp 85 → 75, defense 90 → 100
- [x] 5.5 `hua_tuo.tres`: hp 95 → 85, defense 80 → 90

## 6. Verification

- [x] 6.1 Run Python sum/range check: every edited character has unchanged sum
      and stats in [1, 500]
- [x] 6.2 Run GDScript test suite:
      `godot --headless res://tests/test_runner.tscn` → 42/42 pass
- [x] 6.3 Run `openspec validate --all --no-interactive` → all pass
