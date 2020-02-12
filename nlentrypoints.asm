EntryPoints:
;coordinates for all the entry points and direction for spawning
;since each entry is exactly three bytes, try to do single-phase single-poiner lookup
;need x,y in pixels for the top left corner of each door and window metatile, then a direction 0-3, 0=up, clockwise
;entrypoints themselves are indexed clockwise from the top left corner
;NOTE: go back and make sure anything else involving entrypoints is zero-indexed
;top row, dir will always be $02, looking for tile $2A (for the window. there are no doors.) y will always be $20
;and it'll be the tile position x 8 for pixels
;     x   y   dir
  .db $48,$18,$02
  .db $78,$18,$02
  .db $A8,$18,$02
;right edge, dir will always be $03, looking for tiles $05(window) and $0B(door). x will always be $E8
  .db $E8,$40,$03
  .db $E8,$70,$03
  .db $E8,$90,$03
;bottom row, don't forget to list from right to left
;looking for tiles $41(window) and $25(door), dir will always be $00, y will always be $D0
  .db $B0,$D0,$00
  .db $78,$D0,$00
  .db $40,$D0,$00
;left row, listed from the bottom up
;looking for tiles $27(window) and no doors. should hopefully be exactly two. 
;dir will always be $01, x will always be $10
  .db $10,$88,$01
  .db $10,$48,$01
;all done