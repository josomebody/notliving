LoadSprites: 
;probably need to do some priority sorting and <strike>implement flicker</strike>

;probably best do do it toward the outside of forever and use the y register here to read from the fully-sorted
;buffer instead of ent_blob directly
;TODO: doesn't look like we're following the chain from master_sprite_offset all the way to actual sprite tables
;check if another function is supposed to do that and have it already in the blob or if we need to do it here.
  PHP
  PHA
  TYA ;register safety
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
  LDA ctr_lo
  PHA
  LDA ctr_hi
  PHA ;pointer safety

;see if we can get away with disabling NMI
;  LDA #%00010000
;  STA PPUCTRL
;looks like we need to clear out sprite ram first of all
  ;LDA #$FE
  ;LDX #$00
;LoadSpritesClearLoop:
  ;STA $0200, x
  ;INX
  ;BNE LoadSpritesClearLoop

;loop over sprites that should be on screen, take current action, direction, and frame, find the right metatile
;offset from those, write to buffer to be dumped in nmi
;fully spec ent blob format to find offsets of these variables and the on-screen coordinates of each sprite
;set constants to implement the spec
;ptr_temp will keep track of the next open byte in SPRITE_RAM ($0200 +) and increment in the internal loop
  LDA #$00 
  STA ptr_temp_lo
  LDA #$02
  STA ptr_temp_hi
;can't really use the actual constant name here in source since it needs to go out of order in two bytes

  LDA #$00
  STA tmp ;tmp is indexing sorted_sprites and will be placed in y in the loop
  LDY #$00
LoadSpriteEntLoop:
;ok, right here. we need the right value from sorted_sprites in cur_ent, which is being incremented in the 
;original code. just swap it out for tmp or something
;also keep y safe
;------
  TYA
  PHA

  LDY tmp
  LDA #LOW(sorted_sprites)
  STA ptr_lo
  LDA #HIGH(sorted_sprites)
  STA ptr_hi
  LDA [ptr_lo], y ;pulling a value out of sorted_sprites, which is in tens. LoadEnt wants indices in ones
                  ;may eventually standardize everything to tens if this gets to be a pain, should save a lot of cycs
  LSR A
  LSR A
  LSR A
  LSR A
  STA cur_ent

  PLA
  TAY
;-------
  JSR LoadEnt
  LDA cur_ent_type
  CMP #ENT_TYPE_DNE ;can probably trim this later now that we have a list of sorted sprites that should all exist
  BEQ LoadSpriteEntDNE
;the right metasprite offset should be in cur_ent_sprite_lo/hi, do boilerplate sprite loading from here
;not totally sure what else y is doing in this big loop, so push it to be safe
  TYA
  PHA

  LDY #$00 ;hopefully we can just keep incrementing y and get the right byte from and to where it should be
  LDX #$00 ;ok, x is keeping track of tiles in the sprite, so actually counting the loop iterations against size
LoadSpriteInternalLoop:
;gotta clean this up. let's see, y is being used as an offset from sprite ram right now, but it looks like the reads
;and writes always line up, so may be able to set it to the right byte every read/write somehow
;the stores are just using a constant after the assembler is done with them
;what we need to do is read each byte from [cur_ent_sprite_lo] + y, where y==[0,3],
;except also for tiles within the sprite, so y needs to go up 4 every time through this internal loop.
;then write that byte to its proper spot in the first available 4-byte slot in the sprite buffer
;so SPRITE_RAM + (open slot) + (y==[0,3])
;guess we could use ptr_temp for that, pretty sure it's not being used right now
  
  LDA [cur_ent_sprite_lo], y ;oh, the address lo byte for the y-coordinate is in a, not the actual coordinate.???
  ;STA ctr_lo ;put it in ctr and read from there if so
  CLC			      
  ADC cur_ent_y ;this is adding the actual y-coordinate to the relative coordinate in the sprite data
  STA [ptr_temp_lo], y
  INY ;now the tile number
  LDA [cur_ent_sprite_lo], y 
  STA [ptr_temp_lo], y
  INY ;now the attribute byte
  LDA [cur_ent_sprite_lo], y
  STA [ptr_temp_lo], y
  INY ;and now the x-coordinate, which also needs adjusted for relative coordinate
  LDA [cur_ent_sprite_lo], y
  CLC
  ADC cur_ent_x
  STA [ptr_temp_lo], y
  INY ;then this should scoot up to the y-coordinate byte of the next slot in both
  INX
  CPX cur_ent_size
  BNE LoadSpriteInternalLoop
;now we need to increment ptr_temp up to the next whole sprite slot in the sprite buffer, so 4 bytes * cur_ent_size
  LDA cur_ent_size
  ASL A
  ASL A
  CLC
  ADC ptr_temp_lo
  STA ptr_temp_lo
  LDA #$00
  ADC ptr_temp_hi
  STA ptr_temp_hi
  ;this was some real tricky shit, hope it works.

;pulling y from right before we entered the internal loop
  PLA
  TAY

LoadSpriteEntDNE:
  INC tmp
  LDA tmp
  CMP #$10
  BNE LoadSpriteEntLoop

;once we run out of ents, we need to blank out the rest of the sprite buffer real quick. tried blanking all of them out, but it looked a little messy when NMI caught up.
;think we still have ptr_temp where we left it in the load loop
LoadSpritesBlankLoop:
  LDA ptr_temp_lo
  CLC
  ADC #$01
  STA ptr_temp_lo
  LDA #$00
  ADC ptr_temp_hi
  STA ptr_temp_hi
  LDY #$00
  LDA #$FE
  STA [ptr_temp_lo], y
  LDA ptr_temp_lo
  CMP #$FF
  BNE LoadSpritesBlankLoop

;re-enable NMI
;  LDA #%10010000
;  STA PPUCTRL
;  LDA #$00
;  STA PPUSCROLL
;  STA PPUSCROLL

  PLA
  STA ctr_hi
  PLA
  STA ctr_lo
  PLA
  STA ptr_temp_hi
  PLA
  STA ptr_temp_lo
  PLA
  STA ptr_hi
  PLA
  STA ptr_lo ;pointer safety

  PLA
  TAX
  PLA
  TAY ;register safety
  PLA
  PLP

  RTS
