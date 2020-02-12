ReadControllers:
  PHP
  PHA
  TXA
  PHA
;does hardware reads on the controller input, stores boolean button states in joy1 and joy2
;first store the last controller state
  LDA joy1
  STA oldjoy1
  LDA joy2
  STA oldjoy2
;zero out the current controller states
  LDA #$00
  STA joy1
  STA joy2

;strobe the controllers
  LDA #$01
  STA CONTROLLER_W
  LDA #$00
  STA CONTROLLER_W
;then read in the buttons one at a time and shift the bits up each joy variable
  LDX #$08
ControllerReadLoop:
  ASL joy1
  LDA JOYPAD1
  AND #%00000001
  ORA joy1
  STA joy1
  ASL joy2
  LDA JOYPAD2
  AND #%00000001
  ORA joy2
  STA joy2
  DEX
  BNE ControllerReadLoop

  PLA
  TAX
  PLA
  PLP
  RTS
