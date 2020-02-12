LoadWave:
  PHP
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

;loads waves at specified times
  ;LDA clock
  ;BEQ YesLoadWave
  ;JMP NoLoadWave
YesLoadWave:
  LDX #$00
WaveCheckLoop:
  LDA Waves, x
  CMP bigclock ;first entry in each wave is a time value for bigclock when it should be deployed
  BEQ SelectWave ;at the beginning of SelectWave, x will be pointing at the bigclock value for the right wave.
  INX
  INX
  INX
  CPX #$12 ;there are apparently $12 waves altogether
  BNE WaveCheckLoop
  JMP NoLoadWave ;gone all the way through the wave list and no matches to bigclock

SelectWave:
  CMP oldbigclockforwaves
  BEQ NoLoadWave
  STA oldbigclockforwaves ;gotta make sure we don't load the same wave twice
  INX ;now pointing at the low byte of the address for the right wave
  LDA Waves, x
  STA ptr_lo
  INX ;and the high byte
  LDA Waves, x
  STA ptr_hi
;each wave entry has a count as the first byte for how many zhands to spawn, 
;and then a list of indices to EntryPoints, which has coordinates and dirs
  LDY #$00
  LDA [ptr_lo], y
  TAX ;now we have a counter. iterate til it hits zero (dex)
WaveLoadLoop:
  INY ;[ptr_lo], y should be pointing at the current entry in wave_x
  LDA [ptr_lo], y ;now A has a raw entry number. EntryPoints has three bytes per entry, so we need a q&d *3.
  STA tmp
  ASL A
  CLC
  ADC tmp ;now A has an offset from EntryPoints. 
  STA tmp ;we need to load in three bytes and store them as x,y,dir for the new zhands.
  CLC
  ADC #LOW(EntryPoints)
  STA ptr_temp_lo
  LDA #$00
  ADC #HIGH(EntryPoints)
  STA ptr_temp_hi
;gonna borrow Y for a sec
  TYA
  PHA
  LDY #$00
  LDA [ptr_temp_lo], y
  STA obj_ent_x
  INY
  LDA [ptr_temp_lo], y
  STA obj_ent_y
  INY
  LDA [ptr_temp_lo], y
  STA obj_ent_dir
;gonna set some defaults and just save the new zhands down while we're in here
  LDA #ENT_TYPE_ZHANDS
  STA new_ent_type
  JSR SpawnEnt
;gonna borrow X for a sec too
  TXA
  PHA
  LDX new_ent
  LDA obj_ent_x
  STA ent_blob + ENT_X, x
  LDA obj_ent_y
  STA ent_blob + ENT_Y, x
  LDA obj_ent_dir
  STA ent_blob + ENT_DIR, x
  LDA #$01
  STA ent_blob + ENT_MAX_FRAMES, x
  LDA #$00
  STA ent_blob + ENT_ACTION, x
  STA ent_blob + ENT_FRAME, x
;done with x
  PLA
  TAX
;should be done with y
  PLA
  TAY
;now iterate the loop over the list of entry points
  DEX
  BNE WaveLoadLoop
;pretty sure that's all we need out of this
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
  PLP
  RTS  