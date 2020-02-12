LoadWave:
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

;checks wave staging time against the clocks, loads a wave
;wavestaging should be a standalone variable with the number of the next wave, points to
;a big data structure with the amount and locations/directions of new zombies and the time to deploy them
;probably via a pointer table
;may just use an indexed list of windows and doors for simplicity in the data structure and figure everthing
;else (x, y, dir) out from there
;needs to be called in NMI for precise clock values, so keep it slim, 
;maybe load up an array to spawn outside of it if necessary
  LDA clock
  BEQ YesLoadWave
  JMP NoLoadWave
YesLoadWave: ;branch limit is getting to be a pain
  LDA #LOW(Waves) ;ok, tricky part. the wave master table has entries of 3 bytes. 
  STA ptr_lo      ;need to compare against byte 0 in each
  LDA #HIGH(Waves)
  STA ptr_hi
  LDY #$00
WaveCheckLoop:
  LDA [ptr_lo], y
  CMP bigclock
  BEQ SelectWave ;hopefully at this label, [ptr_lo], y + 1 will have the low byte for the right wave entry
  INY
  INY
  INY ;to get up to the next entry in the master table
  CPY #$12 ;should be where the master table falls off
  BNE WaveCheckLoop 
  JMP NoLoadWave ;not time for a wave

SelectWave:
  INY ;should be the low address for the right wave out of the master table here
  LDA [ptr_lo], y
  STA ptr_temp_lo
  INY ;and the high address
  LDA [ptr_lo], y
  STA ptr_temp_hi
;now to do the actual loading. if this is too slow for NMI, just set a flag or something and put it in a separate
;function to call in forever
  LDY #$00
  LDA [ptr_temp_lo], y
  TAX ;the amount of zombies in the wave
WaveLoadLoop:
  INY
  LDA [ptr_temp_lo], y ;got the index for the right entry point in A. now to figure out what to do with it
;eventually have an x and y coordinate and a dir, and spawn a zhands
;maybe read from a table of entry points? guess ptr_lo/hi is free up from here
;k, got a table of 3x11 bytes, so mutiply a by 3, get the table address into ptr_lo/hi an a into 7
;not necessarily in that order
;quick and dirty *3
  STA tmp
  ASL A
  CLC
  ADC tmp
  TAY
;get the base address
  LDA #LOW(EntryPoints)
  STA ptr_lo
  LDA #HIGH(EntryPoints)
  STA ptr_hi
;read in the data and store it in obj_ent and call spawnent, then dump the data into the blob from there
  LDA [ptr_lo], y
  STA obj_ent_x
  INY
  LDA [ptr_lo], y
  STA obj_ent_y
  LDA [ptr_lo], y
  STA obj_ent_dir
  LDA #ENT_TYPE_ZHANDS ;oh man, need to go through all the code 
                       ;and make sure the constants are literals when they need to be
  STA new_ent_type
  JSR SpawnEnt
  ;SpawnEnt returns with a row index (offset/$10) of the new ent in ent_blob, stored in new_ent
  TXA
  PHA

  LDA new_ent
  ;ASL A
  ;ASL A
  ;ASL A
  ;ASL A
  ;TAY ;so the actual offset is now in y. get ent_blob + $00 into ptr_lo/hi
  TAX
  ;LDA #LOW(ent_blob) ;well there's your problem
  ;STA ptr_lo
  ;LDA #HIGH(ent_blob)
  ;STA ptr_hi
  ;then dump in x, y, and dir from obj_ent_
  LDA obj_ent_x
  ;STA [ptr_lo + ENT_X], y
  STA ent_blob + ENT_X, x
  LDA obj_ent_y
  ;STA [ptr_lo + ENT_Y], y
  STA ent_blob + ENT_Y, x
  LDA obj_ent_dir
  ;STA [ptr_lo + ENT_DIR], y
  STA ent_blob + ENT_DIR, x
;then set some defaults
  LDA #$01
  STA ent_blob + ENT_MAX_FRAMES, x
  LDA #$00
  STA ent_blob + ENT_FRAME, x
  STA ent_blob + ENT_ACTION, x

  PLA
  TAX
;think that should do the trick, repeat for every zombie in the wave
  DEX
  BNE WaveLoadLoop
NoLoadWave: 
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
  RTS