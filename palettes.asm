  LDA #$00
  STA PPUMASK

LoadPalettes:
  LDA PPUSTATUS
  LDA #$3F
  STA PPUADDR
  LDA #$00
  STA PPUADDR
  LDX #$00
LoadPalettesLoop:
  LDA palette, x
  STA PPUDATA
  INX
  CPX #$20
  BNE LoadPalettesLoop

