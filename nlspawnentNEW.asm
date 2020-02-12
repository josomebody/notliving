SpawnEnt:
  PHP

  PHA

  TXA
  PHA

  TYA
  PHA

  LDA ptr_lo
  PHA

  LDA ptr_hi
  PHA

  LDA ptr_temp_lo
  PHA

  LDA ptr_temp_hi
  PHA

;takes an ent type on new_ent_type, copies a prototype into the first DNE slot in ent_blob, 
;returns with an offset to it from ent_blob on new_ent

  LDX #$00
SpawnEntFindEmptySlotLoop: ;search through ent_blob for the first DNE
  LDA ent_blob + ENT_TYPE, x
  CMP #ENT_TYPE_DNE
  BEQ SpawnEntFoundEmptySlot
  TXA
  CLC
  ADC #$10
  TAX
  BCC SpawnEntFindEmptySlotLoop
  JMP SpawnEntNoEmptySlots

SpawnEntFoundEmptySlot: ;once we find a DNE, return its offset on new_ent from x, copy a prototype into it
  STX new_ent
  ;guess we actually need pointers here
  LDA #LOW(ent_protos)
  STA ptr_lo
  LDA #HIGH(ent_protos)
  STA ptr_hi
  LDA ptr_lo
  CLC
  ADC new_ent_type
  STA ptr_lo
  LDA #$00
  ADC ptr_hi
  STA ptr_hi ;should have a pointer to the right prototype in ptr
  
  LDA #LOW(ent_blob)
  STA ptr_temp_lo
  LDA #HIGH(ent_blob)
  STA ptr_temp_hi
  LDA new_ent
  CLC
  ADC ptr_temp_lo
  STA ptr_temp_lo
  LDA #$00
  ADC ptr_temp_hi
  STA ptr_temp_hi ;and one to the blob slot in ptr_temp

  LDY #$00
SpawnEntLoadProtoLoop:
  LDA [ptr_lo], y
  STA [ptr_temp_lo], y
  INY
  CPY #$10
  BNE SpawnEntLoadProtoLoop
  

SpawnEntNoEmptySlots:
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