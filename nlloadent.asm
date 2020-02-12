LoadEnt: ;looks like we could save a ton of cycles loadin in the type first and skipping the rest if it's DNE
  PHP
  PHA
  TYA ;register safety
  PHA
  TXA
  PHA

  LDA ptr_lo ;pointer safety
  PHA
  LDA ptr_hi
  PHA
  LDA ptr_temp_lo
  PHA 
  LDA ptr_temp_hi
  PHA

;reads from cur_ent and populates the other cur_ent_ variables
  LDA cur_ent ;for future reference, cur_ent is in ones, not tens
  ASL A
  ASL A
  ASL A
  ASL A
  TAX
;offset from ent_blob is now in x
  LDA ent_blob + ENT_TYPE, x
  STA cur_ent_type
;right now loading type first, checking for DNE, and skipping if so. may help with the glitch a little,
;will definitely speed the code up in general
  CMP #ENT_TYPE_DNE
  BNE LoadEntDoesExist
  JMP LoadEntDNE
LoadEntDoesExist:
;end new code

  LDA ent_blob + ENT_X, x
  STA cur_ent_x
  LDA ent_blob + ENT_Y, x
  STA cur_ent_y
  LDA ent_blob + ENT_ACTION, x
  STA cur_ent_action
  LDA ent_blob + ENT_DIR, x
  STA cur_ent_dir
  LDA ent_blob + ENT_FRAME, x
  STA cur_ent_cur_frame
  LDA ent_blob + ENT_XFORCE, x
  STA cur_ent_xforce
  LDA ent_blob + ENT_YFORCE, x
  STA cur_ent_yforce
  LDA ent_blob + ENT_INPUT, x
  STA cur_ent_input
  LDA ent_blob + ENT_HP, x
  STA cur_ent_hp
  LDA ent_blob + ENT_STA, x
  STA cur_ent_sta

  LDA ent_blob + ENT_SPRITE_SIZE, x
  STA cur_ent_size
  LDA ent_blob + ENT_MAX_FRAMES, x
  STA cur_ent_max_frames
;figure out the current frame by running through a nested series of tables starting from current action
;start from the ent's master sprite table
  LDA ent_blob + ENT_SPRLO, x
  STA ptr_lo
  LDA ent_blob + ENT_SPRHI, x
  STA ptr_hi ;the base address to the master sprite table should now be in ptr_lo/hi
  LDA ent_blob + ENT_ACTION, x
  ASL A ;loading a 2-byte offset from a 1-byte index
  CLC
  ADC ptr_lo
  STA ptr_lo
  LDA #$00
  ADC ptr_hi 
  STA ptr_hi ;and now a direct offset to the POINTER TO the right action table
;load it into ptr_temp and juggle
  LDY #$00
  LDA [ptr_lo], y
  STA ptr_temp_lo
  INY
  LDA [ptr_lo], y
  STA ptr_temp_hi
  LDA ptr_temp_lo
  STA ptr_lo
  LDA ptr_temp_hi
  STA ptr_hi ;now ptr_lo/hi holds the offset to the action table, which holds pointers to the dirtable
;need an offset against the base action table based on the object's dir
  LDA cur_ent_dir
  ASL A ;for a word
  CLC
  ADC ptr_lo
  STA ptr_lo
  LDA #$00
  ADC ptr_hi
  STA ptr_hi
;ptr at this point should hold the offset of the pointer to the dir table for the right action. 
;so load it into ptr_temp and juggle again
  LDY #$00
  LDA [ptr_lo], y
  STA ptr_temp_lo
  INY
  LDA [ptr_lo], y
  STA ptr_temp_hi
  LDA ptr_temp_lo
  STA ptr_lo
  LDA ptr_temp_hi
  STA ptr_hi ;ptr is now pointing directly at the dir table
;dir tables consist of a byte for max_frames, followed by a list of pointers to the sprite data for each frame.

 
;and from there from the dir table to the metasprite table
;pretty sure max_frames comes from here before the metasprite table offsets, 
;may or may not be able to move it out to the action tables to save a few byes
;don't forget to reset y to point to max frames, right????????????????????????????????
  LDY #$00
  LDA [ptr_lo], y
  STA cur_ent_max_frames
;then the metasprite table offset for the frames for this dir
  INY ;y is pointing at frame 0 in the dir table
  LDA cur_ent_cur_frame
  ASL A ;time two for a word address.
  CLC
  ADC ptr_lo ;
  STA ptr_lo
  LDA #$00
  ADC ptr_hi
  STA ptr_hi
  
  LDA [ptr_lo], y ;y should be 1 here to offset the max_frames byte
  STA ptr_temp_lo
  INY
  LDA [ptr_lo], y ;[RIGHT HERE IS PULLING AN Fx VALUE][pretty sure fixed, was off by one byte]
  STA ptr_temp_hi
  LDA ptr_temp_lo
  STA ptr_lo
  LDA ptr_temp_hi
  STA ptr_hi
;and put those into the cur_ent_sprite variables for further use
  LDA ptr_lo ;original code loads the addresses stored in ptr, which i'm pretty sure is right
;---------experiment in loading the contents of that address instead-------
  ;LDY #00
  ;LDA [ptr_lo], y ;to check this, enable it and see if cur_ent_sprite_lo/hi contains something that looks more like an x and tile number than an offset near db00
;---------to be continued in a sec----------------------------------------
  STA cur_ent_sprite_lo ;CHECK ON WHAT'S GETTING PUT RIGHT HERE!
  LDA ptr_hi ;this was the original too
;--------continuing experimental code-------------------------------------
  ;INY
  ;LDA [ptr_lo], y
;--------end experimental code-------------------------------------------
  STA cur_ent_sprite_hi

LoadEntDNE:
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
