ZombieBrains:
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
;zombies will walk around randomly scanning ahead until they see doge
;then either run at him or back off if he's using the torch
;IMPORTANT: doge should always be the first ent in the blob
;basically read in the environment, make some decisions, store in ENT_INPUT the same way a controller state

;need to iterate over the blob and do this for every zombie
  LDX #$00
ZombieBrainsLoop:
  STX cur_ent
  JSR LoadEnt
  LDA cur_ent_type
  CMP #ENT_TYPE_ZOMBIE
  BEQ ZombieBrainsProceed
  JMP ZBNotZombie
ZombieBrainsProceed:
  TXA
  PHA
  ADC clock
  TAX
  LDA $C000, x
  BNE ZBNoDirChange
;reset the input so it can be randomized if the zombie doesn't see anything
  LDA #$00
  STA cur_ent_input
ZBNoDirChange:
  PLA
  TAX
;decide which direction to scan based on cur_ent_dir
  LDA cur_ent_dir
  CMP #$00
  BEQ ZombieScanUp
  CMP #$01
  BEQ ZombieScanRight
  CMP #$02
  BEQ ZombieScanDownBase
  CMP #$03
  JMP ZombieScanLeft ;because this address is just too far away for a branch
ZombieScanDownBase:
  JMP ZombieScanDown
;let's say they can see about a quarter of the way across the screen ahead, so $40 pixels
ZombieScanUp:
;think the scans aren't getting out if doge is behind the zombie, so we'll just check for that first
  LDA ent_blob + ENT_Y ;doge's y will be less than the zombie's y or get out
  SEC
  CMP cur_ent_y
  BCS ZombieScanDoneBase
  ;check if doge's x is within $10 pixels of the zombie's x
  ;like if(abs(doge.x-zombie.x)<$10) continue
  LDA ent_blob + ENT_X ;may need to use indirect y addressing here
  SEC
  SBC cur_ent_x
  ;need to check both positive and negative results. carry flag might help
  BCC ZSUNeg
  ;if we're still here it's positive, so zombie is to the right of doge
  ;is the gap less than $10?
  SEC
  CMP #$10
  ;if so do the y-scan, otherwise jump down to Done
  BCS ZombieScanDoneBase
ZSUNeg:
  ;should only be here if the zombie is to the right of doge
  ;so rolling over, we want a gap greater than $EF
  SEC
  CMP #$EF
  ;get out of it's smaller than that (larger negative number than -10)
  BCC ZombieScanDoneBase
  ;otherwise do the y-scan
  ;check if doge's y is within $80 pixels of the zombie's y
  ;the result of this subtract should always be positive, or doge is behind the zombie and it doesn't count
  LDA cur_ent_y
  SEC
  SBC ent_blob + ENT_Y
  ;we want a number smaller than $80 or get out
  SEC
  CMP #$80
  BCS ZombieScanDoneBase
  ;if he's more or less straight above the zombie, set the zombie's up control
  ;or down control if he's using the torch
  LDA ent_blob + ENT_ACTION
  CMP #DOGE_ACTION_TORCH
  BEQ ZSUTorch
  LDA cur_ent_input 
  ORA #BUTTON_UP
  STA cur_ent_input
  ;fuck yeah.
ZombieScanDoneBase:
  JMP ZombieScanDone
ZSUTorch:
  LDA cur_ent_input
  ORA #BUTTON_DN
  STA cur_ent_input
  JMP ZombieScanDone

ZombieScanRight:
;doge's x should be greater than the zombie's or get out
  LDA ent_blob + ENT_X
  SEC
  CMP cur_ent_x
  BCC ZombieScanDoneBase2
  ;check if doge's y is within $10 pixels of the zombie's y
  ; if(abs(doge.y-zombie.y)<$10) continue
  LDA ent_blob + ENT_Y
  SEC
  SBC cur_ent_y
  ;deal with positive and negative results
  BCC ZSRNeg
  SEC
  CMP #$10
  BCS ZombieScanDoneBase2
ZSRNeg:
  ;zombie is higher than doge
  SEC
  CMP #$EF
  BCC ZombieScanDoneBase2
  ;now the x-scan
  ;check if doge's x is within $80 pixels of the zombie's x
  ;if this subtract is negative, doge is to the left of the zombie and can't be seen
  LDA cur_ent_x
  SEC
  SBC ent_blob + ENT_X
  SEC
  CMP #$80
  BCS ZombieScanDoneBase2
  ;check if doge is using the torch and act accordingly. left if torch, right if safe.
  LDA ent_blob + ENT_ACTION
  CMP #DOGE_ACTION_TORCH
  BEQ ZSRTorch
  LDA cur_ent_input
  ORA #BUTTON_R
  STA cur_ent_input
ZombieScanDoneBase2:
  JMP ZombieScanDone
ZSRTorch:
  LDA cur_ent_input
  ORA #BUTTON_L
  STA cur_ent_input
  JMP ZombieScanDone

ZombieScanDown:
;doge's y has to be greater than the zombie's y or get out
  LDA ent_blob + ENT_Y
  SEC
  CMP cur_ent_y
  BCC ZombieScanDoneBase2
  ;same x-scan as ZombieScanUp
  ;check if doge's x is within $10 pixels of the zombie's x
  ;like if(abs(doge.x-zombie.x)<$10) continue
  LDA ent_blob + ENT_X
  SEC
  SBC cur_ent_x
  ;need to check both positive and negative results. carry flag might help
  BCC ZSDNeg
  ;if we're still here it's positive, so zombie is to the right of doge
  ;is the gap less than $10?
  SEC
  CMP #$10
  ;if so do the y-scan, otherwise jump down to Done
  BCS ZombieScanDone
ZSDNeg:
  ;should only be here if the zombie is to the left of doge
  ;so rolling over, we want a gap greater than $EF
  SEC
  CMP #$EF
  ;get out of it's smaller than that (larger negative number than -10)
  BCC ZombieScanDone
  ;otherwise do the y-scan
  ;now to get a positive subtract result, doge should be below the zombie, with a higher y
  LDA ent_blob + ENT_Y
  SEC
  SBC cur_ent_y
  ;if it's negative, doge is actually above, and therefore behind the zombie, so the zombie can see him if it's <$80
  SEC
  CMP #$80
  BCS ZombieScanDone
  ;torch check
  LDA ent_blob + ENT_ACTION
  CMP #DOGE_ACTION_TORCH
  BEQ ZSDTorch
  ;brrrraaaaaaaiiiiiiinz
  LDA cur_ent_input
  ORA #BUTTON_DN
  STA cur_ent_input
  JMP ZombieScanDone
ZSDTorch:
  ;fire bad
  LDA cur_ent_input
  ORA #BUTTON_UP
  STA cur_ent_input

  JMP ZombieScanDone

ZombieScanLeft:
;doge's x has to be less than the zombie's x or get out
  LDA ent_blob + ENT_X
  SEC
  CMP cur_ent_x
  BCS ZombieScanDone
  ;same y-scan as ZombieScanRight
  ;check if doge's y is within $10 pixels of the zombie's y
  ; if(abs(doge.y-zombie.y)<$10) continue
  LDA ent_blob + ENT_Y
  SEC
  SBC cur_ent_y
  ;deal with positive and negative results
  BCC ZSLNeg
  SEC
  CMP #$10
  BCS ZombieScanDone
ZSLNeg:
  ;zombie is higher than doge
  SEC
  CMP #$EF
  BCC ZombieScanDone
  ;now the x-scan
  ;if the zombie's facing left, it'll only get a good scan if its x is higher than doge's
  LDA cur_ent_x
  SEC
  SBC ent_blob + ENT_X
  SEC
  CMP #$80
  BCS ZombieScanDone
  ;torch
  LDA ent_blob + ENT_ACTION
  CMP #DOGE_ACTION_TORCH
  BEQ ZSLTorch
  LDA cur_ent_input
  ORA #BUTTON_L
  STA cur_ent_input
  JMP ZombieScanDone
ZSLTorch:
  LDA cur_ent_input
  ORA #BUTTON_R
  STA cur_ent_input

  JMP ZombieScanDone

ZombieScanDone:
;do whatever else zombies do here. maybe check if the input is empty and randomize it if so, i dunno
  LDA cur_ent_input
  BNE ZombieMoreBrains 
  TXA
  PHA

  ;get a couple of random bits from somewhere
  LDA bigclock
  EOR clock
  TAX
  LDA $C000, x
  AND #%00000011
  TAX
  ;shift $01 up by that many and put it into input for a random direction
  LDA #$01
ZBRandomDirLoop:
  DEX
  CPX #$FF
  BEQ ZBRandomDirLoopDone
  ASL A
  JMP ZBRandomDirLoop
ZBRandomDirLoopDone:
  STA cur_ent_input
  PLA
  TAX

ZombieMoreBrains:
;how bout checking if the zombie is running into a wall and turning if so?
  LDA cur_ent_x
  STA obj_ent_x
  LDA cur_ent_y
  STA obj_ent_y
  JSR ClipCheck
  LDA clip_flag
  BEQ ZBNoClip
  ;load in the current input and rotate the dpad press up one, not sure if it can be zero here, may have to deal with that
  LDA cur_ent_input
  ASL A
  ;if the shift made it greater than 8, set it to one
  CMP #$10
  BNE ZBClipAllGood
  LDA #$01
ZBClipAllGood:
  STA cur_ent_input  
ZBNoClip:
;probably a good idea to dump cur_ent back into the blob when we're done
  JSR SaveEnt
ZBNotZombie:
;iterate the big outer loop
  INX
  CPX #$11 ;x is counting in ones, $10 entries in the blob
  BEQ ZBDone
  JMP ZombieBrainsLoop
ZBDone:

  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
