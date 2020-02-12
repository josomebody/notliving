ClipCheck:
;lot of adjustments to make. change all references to player_ to obj_ent, probably switch some hardcoded addresses
;to variables, particularly the clip map, ent dimensions might be a good idea to write a new function to find an 
;ent's height and width since this is the second time we need it now
;as-is, this checks assuming a 2x2 tile ent, probably good enough for our purposes right now.
;double check that all these variables are reserved in the game's variable module
;almost tempted to convert clipping tables into something resembling a sprite tile table format or 
;even a binary tile map
;BUT WAIT, THERE'S MORE--this should be able to put out values higher than 1 to identify furniture. check the logic
;to see if it does really tight bit-flipping or can work as-is
   LDA #$00
   STA clip_flag
   STA clip_offset_lo
   STA clip_offset_hi
   ;check the bottom 2x2 tiles of the sprite against the 1-byte values in the clipping map
   ;will return with clip_flag set to $01 if map clipping occured, $00 otherwise
   ;screen is approximately $ffx$ff, clipping map is $20x$20
   ;convert player_y into a row offset by adding 8 for the extra tile row, dividing that by $08,
   ;then multiplying that by $20
   ;convert player_x by simply dividing it by 8, add to the row offset to get the full table offset
   ;then check the values at (+1, 0), (0, +1), and (+1, +1)<--adjust this to handle any metasprite size
   ;when the game expands beyond one screen, will need a moving base offset for the right clipping table
   ;the base should only need to move $00-$FF
   LDA obj_ent_y
   ;CLC
   ;ADC #$08 ;player's y-coordinate adjusted for hood is now in A
   STA clip_offset_lo ;and now in the offset pointer
   CLC
   ASL clip_offset_lo ;x$10
   LDA #$00
   ADC clip_offset_hi
   STA clip_offset_hi;need to roll carry flags into clip_offset_hi
   ASL clip_offset_hi
   CLC
   ASL clip_offset_lo ;x$20?
   LDA #$00 ;maybe redundant?
   ADC clip_offset_hi
   STA clip_offset_hi
   LDA clip_offset_lo
   AND #$E0 ;wtf is this?
   STA clip_offset_lo
   ;should hopefully have the first column of the right row in clip_offset now, should always be a multiple of $20
   LDA obj_ent_x
   ;column will never be over $20, so just divide and round off the remainders
   LSR A
   LSR A
   LSR A
   CLC
   ADC clip_offset_lo
   STA clip_offset_lo
   LDA #$00
   ADC clip_offset_hi
   STA clip_offset_hi
   ;should hopefully have the full table offset for the top left corner in clip_offset now
   ;now add in the base address
   LDA #LOW(clipmap) ;s/#LOW(clipmap)/clippingtable_lo/ when maps are implemented
   CLC
   ADC clip_offset_lo
   STA clip_offset_lo
   LDA #HIGH(clipmap) ;s/#HIGH(clipmap)/clippingtable_hi/
   ADC clip_offset_hi
   STA clip_offset_hi
   ;now start checking
   LDY #$00
   LDA [clip_offset_lo], y
   ORA clip_flag
   STA clip_flag
   INY
   LDA [clip_offset_lo], y
   ORA clip_flag
   STA clip_flag
   ;add $20 to jump down a row
   LDY #$20
   LDA [clip_offset_lo], y
   ORA clip_flag
   STA clip_flag
   INY
   LDA [clip_offset_lo], y
   ORA clip_flag
   STA clip_flag
   ;wow, think we're done here
   RTS