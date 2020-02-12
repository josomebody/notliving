SortSprites:
  PHP
  PHA
  TYA
  PHA
  TXA
  PHA
  LDA tmp
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
  CLC
  ADC #$10
  TAX
  BNE FillSpritesThatExistLoop

  LDY #$00
FindHighestYBigLoop: ;need to iterate until the whole list is empty
  LDA #$00
  STA tmp ;the highest y coordinate found will be in tmp. when the whole list is empty tmp will be $00
  LDX #$00
FindHighestYLoop: ;this loop finds the lowest x left in the current version of sprites_that_exist
  TXA
  PHA
  LDA sprites_that_exist, x
  CMP #$FF
  BEQ FindHighestYDone
  CMP #$FE
  BEQ NotHighestY
  TAX
  LDA ent_blob + ENT_Y, x
  SEC
  CMP tmp
  BCC NotHighestY
  STA tmp
NotHighestY:
  PLA
  TAX
  INX
  CMP #$10
  BNE FindHighestYLoop

FindHighestYDone: ;should jump down to here once we hit a $FF in sprites_that_exist
;now gotta find that entry with the x-coordinate matching tmp
  LDX #$00
GrabHighestYLoop:
  TXA
  PHA

  LDA sprites_that_exist, x
  CMP #$FE
  BEQ GrabHighestYNotIt
  TAX
  LDA ent_blob + ENT_Y, x
  CMP tmp
  BNE GrabHighestYNotIt
  PLA
  TAX
  LDA sprites_that_exist, x
  STA flicker_groups, y
  LDA #$FE ;blank that entry out now
  STA sprites_that_exist, x
  INY
  JMP GrabbedHighestY
GrabHighestYNotIt:
  PLA
  TAX
  INX
  CPX #$10
  BNE GrabHighestYLoop
GrabbedHighestY:
  PLA
  TAX ;pretty sure this is just to prevent minor stack corruption. NO STACK CORRUPTION IS MINOR!	

;then iterate the big loop
  LDA #$00
  CMP tmp
  BNE FindHighestYBigLoop

;flicker_groups is a list sorted by x-coordinate, and we want an always-shuffling list from there
;so everybody gets a turn if we hit the scanline per-sprite limit
;do this in two phases, make the first four sprites as far apart as possible and alternate them out
;in phase two, just fill in the rest from left to right

;debug
  LDA #$FF
  STA $F0
;/debug

  LDX active_flicker_group ;this counts from 0-3 over and over and is updated every NMI
			   ;add four to it every read in phase one of this load
  LDY #$00 ;this will track the index of sorted_sprites and just increment
FillSortedSpritesFGLoop: ;then do the next group by priority

FillSortedSpritesAFGLoop:
  LDA flicker_groups, x
  CMP #$FF
  BEQ AFGLoopDone ;just quit when we get an empty
  CMP #$FE
  BEQ FGLoopDone
  STA sorted_sprites, y
  LDA #$FE ;now blank it out so we can skip it in phase two
  STA flicker_groups, x
  INY
  TXA
  CLC
  ADC #$04
  TAX
  SEC
  CMP #$10
  BCC FillSortedSpritesAFGLoop
AFGLoopDone: ;x should be $10+active_flicker_group+how many times we've gone through here
  INX
  SEC
  CPX #$10
  BCS FGLoopDone
  TXA
  AND #%00000011
  TAX
  JMP FillSortedSpritesFGLoop
FGLoopDone:

  JMP FillSortedSpritesDone ;can just get rid of this whole block if FGLoop works
;now phase two, go through flicker_groups until we hit an $FF or the end and add the rest
  LDX #$00 ;leaving Y where it is, indexing the next available slot in sorted_sprites
FillSortedSpritesTheRestLoop:
  LDA flicker_groups, x
  CMP #$FE
  BEQ FillSortedSpritesTheRestEmptyEntry
  CMP #$FF
  BEQ FillSortedSpritesDone
  STA sorted_sprites, y
  INY
  LDA #$FE
  STA flicker_groups, x ;just in case
FillSortedSpritesTheRestEmptyEntry:
  INX
  CPX #$10
  BNE FillSortedSpritesTheRestLoop
FillSortedSpritesDone: ;life is easier without unnecessary pointers all over the place

  
  PLA
  STA tmp
  PLA
  TAX
  PLA
  TAY
  PLA
  PLP