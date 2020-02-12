LoadBackground:
  TYA
  PHA
  TXA
  PHA
;loads the nametable at bg_lo/bg_hi and attribute table at attr_lo/hi into PPU

;set up pointers and counters for the nametable
  LDA bg_lo
  STA ptr_lo
  LDA bg_hi
  STA ptr_hi
  LDA #$00
  STA ctr_lo
  STA ctr_hi

;then probably disable rendering/NMI
  LDA $00
  STA PPUCTRL
  STA PPUMASK

;read in the nametable
  ;the base of the right nametable is in bg_lo/hi
  ;basically loop over it and read in each byte and write it to PPUDATA
  ;first, set the base address for PPUDATA to $2000
  ;reset the latch
  LDA PPUSTATUS
  ;write the base address in, high byte first
  LDA #$20
  STA PPUADDR
  LDA #$00
  STA PPUADDR
;now loop over the 32x30-byte nametable and send each byte to PPUDATA
  LDY #$00
LoadNametableLoop:
  LDA [ptr_lo], y
  STA PPUDATA
  LDA ptr_lo
  CLC
  ADC #$01
  STA ptr_lo
  LDA #$00
  ADC ptr_hi
  STA ptr_hi
  ;increment ctr to keep track of the loop
  LDA ctr_lo
  CLC
  ADC #$01
  STA ctr_lo
  LDA #$00
  ADC ctr_hi
  STA ctr_hi
  LDA ctr_lo ;ctr should be $03C0 when we're done
  CMP #$C0
  BNE LoadNametableLoop
  LDA ctr_hi
  CMP #$03
  BNE LoadNametableLoop
  
;read in the attribute table
  ;set up pointers and counters
  LDA attr_lo
  STA ptr_lo
  LDA attr_hi
  STA ptr_hi
  LDA #$00
;don't need ctr because the table is small enough to just use y
;set the PPUADDR to $23C0 for attribute table
  LDA PPUSTATUS
  LDA #$23
  STA PPUADDR
  LDA #$C0
  STA PPUADDR
;now loop over the attribute table, which should be 64 bytes ($40)
  LDY #$00
LoadAttributeLoop:
  LDA [ptr_lo], y
  STA PPUDATA
  INY
  CPY #$40
  BNE LoadAttributeLoop

;enable rendering/NMI
  LDA #%10000000
  STA PPUCTRL
  LDA #%00011110
  STA PPUMASK

  PLA
  TAX
  PLA
  TAY
  RTS