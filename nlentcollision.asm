EntCollision:
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

;takes cur_ent (loaded), and obj_ent (just the blob index in tens is fine), 
;returns ent_collision=0 for no collision, 1 for collision

;first find the centers and dimensions of the ents
  LDA cur_ent_sprite_lo
  STA ptr_lo
  LDA cur_ent_sprite_hi
  STA ptr_hi
  LDY #SPRITE_X ;reading the offset in a sprite entry for the x-coordinate first
  LDA #$00 ;setting cur_ent_width/height to zero for a starting point
  STA cur_ent_width
  LDX cur_ent_size ;the amount of tiles in the sprite we're looking at
ECRightEdgeLoop: ;load in each tile x-coordinate, if it's bigger than cur_ent_width, store it in there.
  LDA [ptr_lo], y
  SEC
  CMP cur_ent_width ;if this x-coordinate is higher than cur_ent_width, the carry flag will clear
  BCS ECRightEdgeNotBiggest
  STA cur_ent_width
ECRightEdgeNotBiggest:
;moving on to the next tile by adding 4 to ptr, using x to keep track of the tile count
  LDA ptr_lo
  CLC
  ADC #$04
  STA ptr_lo
  LDA #$00
  ADC ptr_hi
  STA ptr_hi
  DEX
  BNE ECRightEdgeLoop

;now do the same thing for the bottom edge
  LDA cur_ent_sprite_lo
  STA ptr_lo
  LDA cur_ent_sprite_hi
  STA ptr_hi
  LDY #SPRITE_Y
  LDA #$00
  STA cur_ent_height
  LDX cur_ent_size
ECBottomEdgeLoop:
  LDA [ptr_lo], y
  SEC
  CMP cur_ent_height
  BCS ECBottomEdgeNotBiggest
  STA cur_ent_height
ECBottomEdgeNotBiggest:
  LDA ptr_lo
  CLC
  ADC #$04
  STA ptr_lo
  LDA #$00
  ADC ptr_hi
  STA ptr_hi
  DEX
  BNE ECBottomEdgeLoop

;now we need to add 8 to each for the 8 pixels of the last tile each way
  LDA cur_ent_width
  CLC
  ADC #$08
  STA cur_ent_width

  LDA cur_ent_height
  CLC
  ADC #$08
  STA cur_ent_height

;and to set the centers just divide by two and then add the real ent's coordinates
  LDA cur_ent_width
  LSR A
  ADC cur_ent_x
  STA cur_ent_center_x

  LDA cur_ent_height
  LSR A
  ADC cur_ent_y
  STA cur_ent_center_y

;ideally we want the true center of obj_ent the same way, but for now just assuming it's one tile big.
;can copypasta old code in to improve it if necessary later.
  LDX obj_ent ;getting a blob index
  LDA ent_blob + ENT_X, x
  ADC #$04
  STA obj_ent_center_x
  LDA ent_blob + ENT_Y, x
  ADC #$04
  STA obj_ent_center_y
  LDA #$08
  STA obj_ent_width
  STA obj_ent_height
  

;then calculate the distance between the centers
  LDA cur_ent_center_x
  SEC
  SBC obj_ent_center_x ;if cur_ent is to the left, we'll get a negative result and need to handle that
  BCC ECDistXNeg
  STA dist_x
  JMP ECDistXSet
ECDistXNeg:
  ;just switch operands
  LDA obj_ent_center_x
  SEC
  SBC cur_ent_center_x
  STA dist_x
ECDistXSet:

  LDA cur_ent_center_y
  SEC
  SBC obj_ent_center_y
  BCC ECDistYNeg
  STA dist_y
  JMP ECDistYSet
ECDistYNeg:
  LDA obj_ent_center_y
  SEC
  SBC cur_ent_center_y
  STA dist_y
ECDistYSet:

;then compare that distance to the average of the ents' dimensions
  ;get the average width
  LDA cur_ent_width
  CLC
  ADC obj_ent_width
  LSR A
  ;do the comparison
  SEC
  CMP dist_x ;if dist_x is smaller, the carry flag will be set and we have the x portion of a collision
  BCC ECNoCollision

  LDA cur_ent_height
  CLC
  ADC obj_ent_height
  LSR A
  SEC
  CMP dist_y
  BCC ECNoCollision
;if we're here, there was a collision
  LDA #$01
  STA ent_collision
  JMP EntCollisionDone
ECNoCollision:
  LDA #$00
  STA ent_collision

EntCollisionDone:

;return 0 if the distance is larger, 1 if less than or equal

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