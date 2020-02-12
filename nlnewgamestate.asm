NewGameState:
;maybe consult the wave data for a layout here
;this will be an ent map for a new game state, should contain coordinates and dirs for doge and the tools
;only need one unless there's gonna be a prestige mode or something, so we'll skip the pointer tables for now
;and looks like Waves just lists entry points, so that's useless for our purposes here
;so i guess something like
;type, x, y, dir. make type first so we can call SpawnEnt and then load in the other data
;and doge should always, always be ent_blob + $00
  .db ENT_TYPE_DOGE, $80, $80, $02
  .db ENT_TYPE_HAMMER, $40, $40, $00
  .db ENT_TYPE_TORCH, $40, $B0, $00
  .db ENT_TYPE_RIFLE, $C0, $40, $00
;pretty sure there should always be exactly four entries here, 
;and that should be reflected in the outer loop of InitGame