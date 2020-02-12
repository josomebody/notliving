SpawnEnt:
  PHP
  PHA

  TXA
  PHA
  TYA
  PHA
;definitely time to start worrying about pointer safety. watch the stack too
  LDA ptr_lo
  PHA
  LDA ptr_hi
  PHA
  LDA ptr_temp_lo
  PHA
  LDA ptr_temp_hi
  PHA

;will take a type number from calling code and spawn a new ent. 
;may be a good idea to put initial values not in prototypes in here too
;ent types are multiples of $10, constants of format ENT_TYPE_
;just use the type as an offset from [entproto]

;get a pointer to the right prototype, new_ent_type should be set
  LDA #LOW(ent_protos)
  STA ptr_lo
  LDA #HIGH(ent_protos)
  STA ptr_hi
  CLC
  LDA new_ent_type
  ADC ptr_lo
  STA ptr_lo
  LDA #$00
  ADC ptr_hi
  STA ptr_hi

;find a free slot in ent_blob searching for the first one with ENT_TYPE==ENT_TYPE_DNE
  LDA #LOW(ent_blob)
  STA ptr_temp_lo
  LDA #HIGH(ent_blob)
  STA ptr_temp_hi
  LDY #ENT_TYPE
SpawnCheckEntLoop: 
  LDA [ptr_temp_lo], y
  CMP #ENT_TYPE_DNE
  BNE SpawnCheckEntLoopNotIt
  ;if we got one, set its offset in new_ent and get out of the loop
  ;need to subtract ENT_TYPE from y to get a clean offset
  TYA
  SEC
  SBC #ENT_TYPE
  STA new_ent

  JMP SpawnCheckEntLoopDone
SpawnCheckEntLoopNotIt:
  ;continue the loop
  TYA
  CLC
  ADC #$10
  TAY
  BCC SpawnCheckEntLoop ;a should roll over during the add when we're through the loop
  JMP SpawnDone ;if we're here, the ent blob is full, so just get out

SpawnCheckEntLoopDone:
;once an empty slot is found, the blob offset is in new_ent
;ent_blob + $00 should be in ptr_temp, so maybe just add new_ent to it
  LDA ptr_temp_lo
  CLC
  ADC new_ent
  STA ptr_temp_lo
  LDA #$00
  ADC ptr_temp_hi
  STA ptr_temp_hi

;so now the prototype offset is in ptr and the ent_blob offset is in ptr_temp NOT SO FAST, getting pointers mixed up
;just loop over both and load in from ptr to ptr_temp
  LDY #$00
SpawnLoadLoop:
  LDA [ptr_lo], y
  STA [ptr_temp_lo], y
  INY
  CPY #$10 ;we're loading in $10 bytes for one ent slot
  BNE SpawnLoadLoop

;load in any other provided info

SpawnDone:  
;pull the pointers
  PLA
  STA ptr_temp_hi
  PLA
  STA ptr_temp_lo
  PLA
  STA ptr_hi
  PLA
  STA ptr_lo
;then the registers
  PLA
  TAY
  PLA
  TAX

  PLA
  PLP

  RTS