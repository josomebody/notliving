InitGame:
;sets up all ent placement present at game start. does not include waves. does include doge, tools
;first thing to do is clear out ent_blob just to be safe.
;it's 256 bytes, so just loop all the way over a register and check it for zero as an exit condition
;set up a pointer
  LDA #LOW(ent_blob)
  STA ptr_lo
  LDA #HIGH(ent_blob)
  STA ptr_hi
;guess really we can just use indirect-y addressing and just count with y
  LDY #$00
;and a will always be zero for clearing, don't think we need to read anything, so just set it outside the loop too
  LDA #$00
InitGameClearBlobLoop:
  STA [ptr_lo], y
  INY
  CPY #$00
  BNE InitGameClearBlobLoop
;oh, need to set all the ent types to DNE, might as well do that in a second loop for simplicity
  LDY #ENT_TYPE ;see how many of these failed const offsets can be fixed this way
  LDA #ENT_TYPE_DNE
InitGameAllDNELoop:
;and dammit, been trying to load things with a constant offset i thought the assembler could handle
;gotta change all these [ptr_lo + CONST] to actually do adds, and clean up the mess after that
  STA [ptr_lo], y
;need to borrow a for a minute, but it always goes back to ENT_TYPE_DNE, so give the stack a break
  TYA
  CLC
  ADC #$10
  TAY
  LDA #ENT_TYPE_DNE
  BCC InitGameAllDNELoop ;pretty sure the carry flag should be preserved from the add still

;really hope clearing the blob makes SpawnEnt find slot-0 on the first call
;start reading data in from NewGameState and loading it into the blob
;read in four bytes per ent. they will be in the order type, x, y, dir
;this loop should iterate four times
;ptr is still pointing at the blob, need ptr_temp to point at NewGameState
  LDA #LOW(NewGameState)
  STA ptr_temp_lo
  LDA #HIGH(NewGameState)
  STA ptr_temp_hi
;probably gonna increment y internally. have an adult help you at home. this can get buggy in more complex loops
  LDY #$00
InitGameLoadLoop:
  LDA [ptr_temp_lo], y
  STA new_ent_type
  JSR SpawnEnt
  ;actually y's going all over the place because of the various structure sizes we're reading and writing
  ;gonna think about this a minute. . .
  ;SpawnEnt returns with a blob offset in new_ent
  ;probably read in from NewGameState, push y, load new_ent into it, write to the blob, pull y
  ;and do it three times, using constants for the offsets inside each blob slot
  INY ;[ptr_temp_lo], y now points at the current ent's x byte
  LDA [ptr_temp_lo], y
  ;need a to do the pushes and pulls, so temporarily store all this stuff in obj_ent_*
  STA obj_ent_x
  INY ;and if we're gonna do that, might as well read in a whole ent at once
  LDA [ptr_temp_lo], y
  STA obj_ent_y
  
  INY
  LDA [ptr_temp_lo], y
  STA obj_ent_dir

;ok, now load it into the blob, being very careful with y and the stack
  TYA
  PHA

  
  LDA #ENT_X
  CLC
  ADC new_ent
  TAY ;getting [ptr_lo], y to point at the ent slot's x byte
  LDA obj_ent_x
  STA [ptr_lo], y ;remember ptr should point to ent_blob, and the slot offset is in y
  LDA #ENT_Y
  CLC
  ADC new_ent
  TAY ;and now [ptr_lo], y should point to the new ent's y byte in the blob
  LDA obj_ent_y
  STA [ptr_lo], y
  LDA #ENT_DIR
  CLC
  ADC new_ent
  TAY ;and now same thing for dir
  LDA obj_ent_dir
  STA [ptr_lo], y

  PLA
  TAY

;now iterate the loop. it's done when y==$10
  INY
  CPY #$10
  BNE InitGameLoadLoop

;probably a good idea to reset the clock so the waves don't start too early if you hang at the start screen for too long
  LDA #$00
  STA clock
  STA bigclock

  RTS