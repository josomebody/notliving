EntCollision: ;this probably needs to be rewritten. it's behaving really weird.
  PHP
  PHA
  TYA
  PHA
  TXA
  PHA

  LDA ptr_lo
  PHA
  LDA ptr_hi
  PHA
  LDA ptr_temp_lo
  PHA
  LDA ptr_temp_hi
  PHA

;debug
  LDA #$88 ;weirdest thing ever, this fixes a bug in AnimUpdate. no idea why.
  STA $80 ;the a-register's getting messed up somewhere is why, still can't really make any sense of it.
;reads cur_ent, takes an index in the blob for an object, 
;puts a 0 on ent_collision if no collision, 1 if yes collision
;since ents can be pretty much any size, probably best to check edges instead of corners
;or check centers for distance < a.width/2 + b.width/2, a.height/2 + b.height/2
;may need some extra vars to keep tack of it all without juggling registers
;first find all the widths and heights. this is gonna be tricky. need to read out of sprite tables, find the
;highest coordinate values in there, and add 8 for the other end of the tile
  LDA cur_ent_sprite_lo ;good chunk of the work is already done for cur_ent. probably gonna have to chain
  STA ptr_lo            ;some pointer->lookup table functions for looking in the blob, or just run LoadEnt on it
  LDA cur_ent_sprite_hi
  STA ptr_hi
  LDX cur_ent_size ;now we can loop through all the tile entries in the metasprite and check coordinate values
  LDY #$00
  TYA ; so we have a starting value (zero) to compare coordinates with
  STA cur_ent_width
  STA cur_ent_height
ECCurCheckCornersLoop:
  ;load in the coordinates of each tile in the metasprite, if the new one is bigger than cur_ent_width/height,
  ;replace it
  ;x
;ok, just fix this by adding the constants to ptr and subtracting them back after the read
  LDA ptr_lo
  CLC
  ADC #SPRITE_X
  STA ptr_lo
  LDA #$00
  ADC ptr_hi
  STA ptr_hi
  LDA [ptr_lo], y ;doing major repairs. watch out for any changes to ptr_lo in the old code
  			      ;right now it's at cur_ent_sprite_lo
			      ;new loads probably don't need y, but do need x, 
			      ;which is iterating over tiles in the sprite
;best solution may be to load cur_ent_sprite into ptr and the constant into y
  CMP cur_ent_width
  BMI ECCurCheckCornersXSkip
  STA cur_ent_width

ECCurCheckCornersXSkip:
;now subtract the constant back
  LDA ptr_lo
  SEC
  SBC #SPRITE_X
  STA ptr_lo
  LDA #$00
  SBC ptr_hi
  STA ptr_hi

  LDA ptr_lo
  CLC
  ADC #SPRITE_Y
  STA ptr_lo
  LDA #$00
  ADC ptr_hi
  STA ptr_hi
  LDA [ptr_lo], y
  CMP cur_ent_height
  BMI ECCurCheckCornersYSkip
  STA cur_ent_height

ECCurCheckCornersYSkip:
  LDA ptr_lo
  SEC
  SBC #SPRITE_Y
  STA ptr_lo
  LDA #$00
  SBC ptr_hi
  STA ptr_hi

  INY ;scoot up to the next tile, 4 bytes
  INY ;nope looks like we are in fact using y. shit.
  INY
  INY
  DEX
  CPX #$00
  BNE ECCurCheckCornersLoop ;really hope the highest coordinate values are in cur_ent_width/height now, just add 8
  LDA cur_ent_width
  CLC
  ADC #$08
  STA cur_ent_width
  LDA cur_ent_height
  CLC
  ADC #$08
  STA cur_ent_height
;now do the same thing to the object somehow 

;guess the fastest way to do it would be to copy the applicable code from LoadEnt over here, maybe replace it with
;a couple of jsrs if code segment size gets too big
;first find the current sprite frame for the object ent. 
;this code is similar to that in nlloadent.asm and is documented there.
;should have and index against the blob in obj_ent
;not sure this addressing mode will work with ent_blob. may need to use the [], y one. have been everywhere else. 
;just make sure to be careful with pointers, maybe make some more
  LDX obj_ent
  LDA ent_blob + ENT_SPRLO, x
  STA ptr_lo
  LDA ent_blob + ENT_SPRHI, x
  STA ptr_hi
;now we've got the master sprite table in ptr_lo/hi. 
  LDA ent_blob + ENT_ACTION, x
  ASL a
  CLC
  ADC ptr_lo
  STA ptr_lo
  LDA #$00
  ADC ptr_hi
  STA ptr_hi

  LDY #$00
  LDA [ptr_lo], y
  STA ptr_temp_lo
  INY
  LDA [ptr_lo], y
  STA ptr_temp_hi
  LDA ptr_temp_lo
  STA ptr_lo
  LDA ptr_temp_hi
  STA ptr_hi

  LDA ent_blob + ENT_DIR, x
  CLC
  ADC ptr_lo
  STA ptr_lo
  LDA #$00
  ADC ptr_hi
  STA ptr_hi
  LDY #$00
  LDA [ptr_lo], y
  STA ptr_temp_lo
  INY
  LDA [ptr_lo], y
  STA ptr_temp_hi
  LDA ptr_temp_lo
  STA ptr_lo
  LDA ptr_temp_hi
  STA ptr_hi
  
  INY
  LDA ent_blob + ENT_FRAME, x
  CLC
  ADC ptr_lo
  STA ptr_lo
  LDA #$00
  ADC ptr_hi
  STA ptr_hi
  LDY #$00
  LDA [ptr_lo], y
  STA ptr_temp_lo
  INY
  LDA [ptr_lo], y
  STA ptr_temp_hi
  LDA ptr_temp_lo
  STA ptr_lo
  LDA ptr_temp_hi
  STA ptr_hi
;got a frame to work from in ptr_lo/hi, now to get obj_ent_center_x/y and obj_ent_width/height
;second verse same as the first with different lables and code space worse
;---------------snip----------------------

  LDX ent_blob + ENT_SPRITE_SIZE
  LDY #$00
  TYA ; so we have a starting value (zero) to compare coordinates with
  STA obj_ent_width
  STA obj_ent_height
OCCurCheckCornersLoop:
  ;load in the coordinates of each tile in the metasprite, if the new one is bigger than cur_ent_width/height,
  ;replace it
  ;x
  LDA ptr_lo
  CLC
  ADC #SPRITE_X
  STA ptr_lo
  LDA #$00
  ADC ptr_hi
  STA ptr_hi
  LDA [ptr_lo], y
  CMP obj_ent_width
  BMI OCCurCheckCornersXSkip
  STA obj_ent_width

OCCurCheckCornersXSkip:
  LDA ptr_lo
  SEC
  SBC #SPRITE_X
  STA ptr_lo
  LDA #$00
  SBC ptr_hi
  STA ptr_hi

  LDA ptr_lo
  CLC
  ADC #SPRITE_Y
  STA ptr_lo
  LDA #$00
  ADC ptr_hi
  STA ptr_hi
  LDA [ptr_lo], y
  CMP obj_ent_height
  BMI OCCurCheckCornersYSkip
  STA obj_ent_height

OCCurCheckCornersYSkip:
  LDA ptr_lo
  SEC
  SBC #SPRITE_Y
  STA ptr_lo
  LDA #$00
  SBC ptr_hi
  STA ptr_hi

  INY ;scoot up to the next tile, 4 bytes
  INY
  INY
  INY
  DEX
  CPX #$00
  BNE OCCurCheckCornersLoop ;really hope the highest coordinate values are in cur_ent_width/height now, just add 8
  LDA obj_ent_width
  CLC
  ADC #$08
  STA obj_ent_width
  LDA obj_ent_height
  CLC
  ADC #$08
  STA obj_ent_height
;---------------snip----------------------
;then find centers from that. just divide by 2 and then add the master coordinates. much easier
  LDA cur_ent_width
  LSR a
  CLC
  ADC cur_ent_x
  STA cur_ent_center_x

  LDA cur_ent_height
  LSR a
  CLC
  ADC cur_ent_y
  STA cur_ent_center_y

  LDX obj_ent
  LDA obj_ent_width
  LSR a
  CLC
  ADC ent_blob + ENT_X, x
  STA obj_ent_center_x

  LDA obj_ent_height
  CLC
  ADC ent_blob + ENT_Y, x
  STA obj_ent_center_y 
  
;calculate the distance on each action by subtraction
  LDA cur_ent_center_x
  SEC
  SBC obj_ent_center_x
;handle a negative result
  BCC ECDXNegative
  STA dist_x
  JMP ECDXDone
ECDXNegative: ;just do it backwards
  LDA obj_ent_center_x
  SEC
  SBC cur_ent_center_x
  STA dist_x
ECDXDone:
;find dist_y now
  LDA cur_ent_center_y
  SEC
  SBC obj_ent_center_y
  BCC ECDYNegative
  STA dist_y
  JMP ECDYDone
ECDYNegative:
  LDA obj_ent_center_y
  SEC
  SBC cur_ent_center_y
  STA dist_y
ECDYDone:
;now the important part, average the width and height, compare them to dist_x and dist_y respectively, 
;set ent_collision=1 if the averages are smaller, 0 if bigger, and gtfo
  LDA #$00
  STA ent_collision
;A for average
  LDA cur_ent_width
  CLC
  ADC obj_ent_width
  LSR a
  SEC
  CMP dist_x
  BCC NoCollision
;still here? check y
  LDA cur_ent_height
  CLC
  ADC obj_ent_height
  LSR a
  SEC
  CMP dist_y
  BCC NoCollision
;still here? then there was a collision
  LDA #$01
  STA ent_collision
NoCollision: ;gtfo
;this function is over 200 instructions. use sparingly.
  PLA
  STA ptr_temp_hi
  PLA
  STA ptr_temp_lo
  PLA
  STA ptr_hi
  PLA
  STA ptr_lo

  PLA
  TAX
  PLA
  TAY
  PLA
  PLP

  RTS