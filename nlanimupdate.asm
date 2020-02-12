AnimUpdate:
  PHP
  PHA
  TXA
  PHA

;updates the current frame of a single entity cur_ent, checks against its max frames and loops if necessary
;pretty sure max_frames is high exclusive
;iterate in here
  LDA #$00
  STA cur_ent
AnimUpdateLoop:
  JSR LoadEnt
  LDA cur_ent_type
  CMP #ENT_TYPE_DNE
  BEQ AnimUpdateDNE

  INC cur_ent_cur_frame
  LDA cur_ent_max_frames
  SEC
  CMP cur_ent_cur_frame
  BCC AnimUpdateAllGood
  BNE AnimUpdateAllGood
  LDA #$00
  STA cur_ent_cur_frame
  LDA cur_ent_action
  CMP #DOGE_ACTION_WALK
  BEQ AnimUpdateAllGood
  CMP #DOGE_ACTION_STAND
  BEQ AnimUpdateAllGood
  LDA #DOGE_ACTION_STAND
  STA cur_ent_action
AnimUpdateAllGood:
  JSR SaveEnt

AnimUpdateDNE:
  INC cur_ent
  LDA cur_ent
  CMP #$10
  BNE AnimUpdateLoop

  PLA
  TAX
  PLA
  PLP
  RTS