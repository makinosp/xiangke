## Safe label helpers for domain enum indices.
## These never crash on out-of-range values; they return "?" instead.
import constants

proc moveTypeLabel*(typeIdx: int): string =
  ## Label for an element type index; "?" when out of range.
  if typeIdx >= 0 and typeIdx < TYPE_LABELS.len:
    return TYPE_LABELS[typeIdx]
  return "?"

proc categoryLabel*(catIdx: int): string =
  ## Label for a damage category index; "?" when out of range.
  if catIdx >= 0 and catIdx < CATEGORY_LABELS.len:
    return CATEGORY_LABELS[catIdx]
  return "?"

proc effectTypeLabel*(effectIdx: int): string =
  ## Label for an effect type index; "?" when out of range.
  if effectIdx >= 0 and effectIdx < EFFECT_LABELS.len:
    return EFFECT_LABELS[effectIdx]
  return "?"
