SortSprites:
  PHP
  PHA
  TYA
  PHA
  TXA
  PHA

  LDX #$00
  LDA #$FF
SortSpritesBlankingLoop:
  STA sprites_that_exist, x
  STA flicker_groups, x
  STA sorted_sprites, x
  INX
  CPX #$10
  BNE SortSpritesBlankingLoop

  LDX #$00
  LDY #$00
FillSpritesThatExistLoop:
  LDA ent_blob + ENT_TYPE, x
  CMP #ENT_TYPE_DNE
  BEQ FillSpritesThatExistDNE
  TXA
  STA sprites_that_exist, y
  INY
FillSpritesThatExistDNE:
  TXA
  ADC #$10
  BNE FillSpritesThatExistLoop

  LDA sprites_that_exist
  TAX
  LDA ent_blob + ENT_X, x
  STA tmp ;the lowest x coordinate found will be in tmp
  LDX #$00
  LDY #$00
FindLowestXLoop:
  TXA
  PHA
  LDA sprites_that_exist, x
  CMP #$FF
  BEQ FindLowestXDone
  CMP #$FE
  BEQ NotLowestX
  TAX
  LDA ent_blob + ENT_X, x
  SEC
  CMP tmp
  BCS NotLowestX
  STA tmp
NotLowestX:
  PLA
  TAX
  INX
  CMP #$10
  BNE FindLowestXLoop

;index from sprites_that_exist for the entry with the lowest x-coordinate should be in X
  LDA sprites_that_exist, x
  STA flicker_groups, y
  LDA #$FE ;blank that entry out now
  STA sprites_that_exist, x
  INY
  JMP FindLowestXLoop

FindLowestXDone: ;should jump down to here once we hit a $FF in sprites_that_exist, just clean the stack up
  PLA
  TAX

;flicker_groups is a list sorted by x-coordinate, and we want an always-shuffling list from there
;so everybody gets a turn if we hit the scanline per-sprite limit
;do this in two phases, make the first four sprites as far apart as possible and alternate them out
;in phase two, just fill in the rest from left to right
  LDX active_flicker_group ;this counts from 0-3 over and over and is updated every NMI
			   ;add four to it every read in phase one of this load
  LDY #$00 ;this will track the index of sorted_sprites and just increment
FillSortedSpritesAFGLoop:
  LDA flicker_groups, x
  CMP #$FF
  BEQ AFGLoopDone ;just quit when we get an empty
  STA sorted_sprites, y
  LDA #$FE ;now blank it out so we can skip it in phase two
  STA flicker_groups, x
  INY
  TXA
  CLC
  ADC #$04
  SEC
  CMP #$10
  BCS FillSortedSpritesAFGLoop

AFGLoopDone:
;now phase two, go through flicker_groups until we hit an $FF or the end and add the rest
  LDX #$00 ;leaving Y where it is, indexing the next available slot in sorted_sprites
FillSortedSpritesTheRestLoop:
  LDA flicker_groups, x
  CMP #$FE
  BEQ FillSortedSpritesTheRestEmptyEntry
  CMP #$FF
  BEQ FillSortedSpritesDone
  STA sorted_sprites, y
  LDA #$FE
  STA flicker_groups, x ;just in case
FillSortedSpritesTheRestEmptyEntry:
  INX
  CPX #$10
  BNE FillSortedSpritesTheRestLoop
FillSortedSpritesDone ;life is easier without unnecessary pointers all over the place
  

  PLA
  TAX
  PLA
  TAY
  PLA
  PLP