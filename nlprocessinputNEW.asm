ProcessInput: ;the original version of this module needs hardcore restructuring, rewriting it from scratch
  PHA
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
  LDA ctr_lo
  PHA
  LDA ctr_hi
  PHA

;iterates over the ent_blob and checks the input byte of each entry, 
;performs further processing and executes any necessary action
;gonna try to keep this outer loop short and sweet, refer it to subroutines down below
  LDA #$00
  STA cur_ent
PIBigLoop: ;call LoadEnt, do type checking, skip unless cur_ent actually has input-based actions
  JSR LoadEnt
  LDA cur_ent_type
  CMP #ENT_TYPE_DNE
  BEQ PIBigLoopNoAction
;if there's no input, set to a default action and get out
  LDA cur_ent_input
  BNE PIBigLoopButtonPressed
  LDA #DOGE_ACTION_STAND ;pretty sure this action will work on anything and is probably just zero
  STA cur_ent_action
;hopefully physics will handle the forces
  JMP PIBigLoopNoAction
;now i guess check for doge and handle A and B button presses
  CMP #ENT_TYPE_DOGE
  BNE PIBigLoopNotDoge
  JSR PIDogeHandleAB
;then check for doge and zombies and do the D-pad
  LDA cur_ent_type
  CMP #ENT_TYPE_DOGE
  BEQ PIBigLoopDpad
  CMP #ENT_TYPE_ZOMBIE
  BEQ PIBigLoopDpad
;add anything else that needs and action above this line. for now we just get out and iterate the loop
;once any handler for start or select is added it should probably be checked for/called right about here
  JMP PIBigLoopNoAction
PIBigLoopDpad:
  JSR PIHandleDpad

PIBigLoopNoAction: ;get to the next ent, check we're not at the end of the blob, iterate the loop
;don't forget to save this ent back before we move on to the next one
  JSR SaveEnt
  INC cur_ent
  LDA cur_ent
  SEC
  CMP #$10 ;cur_ent - 11 will clear the carry flag, right?
  BCS PIBigLoop

  PLA
  STA ctr_hi
  PLA
  STA ctr_lo
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

;further subroutines will follow
PIDogeHandleAB:
;just trying to keep this all clean and traceable. check for A, call a handler
  LDA cur_ent_input
  AND #BUTTON_A
  BEQ PINoA
  JSR PIDogeHandleA
PINoA:
  LDA cur_ent_input
  AND #BUTTON_B
  BEQ PINoB
  JSR PIDogeHandleB
PINoB:

  RTS

PIHandleDpad: ;right now the D-pad just adds forces as apropriate
;just check for each direction, make a call to a handler for it if pressed, and fall through
  LDA cur_ent_input
  AND #BUTTON_UP
  BEQ PINoUp
  JSR PIHandleUp
PINoUp:
  LDA cur_ent_input
  AND #BUTTON_R
  BEQ PINoR
  JSR PIHandleR
PINoR:
  LDA cur_ent_input
  AND #BUTTON_DN
  BEQ PINoDn
  JSR PIHandleDn
PINoDn:
  LDA cur_ent_input
  AND #BUTTON_L
  BEQ PINoL
  JSR PIHandleL
PINoL:

  RTS

PIDogeHandleA: ;the handlers for A and B presses may get tricky and might do better in separate files
;if doge has a tool, use it, otherwise check for furniture clipping and spawn random pickups
  LDA cur_ent_tool
  BEQ PIDogeHandleANoTool
  JSR DogeUseTool ;these subs will probably go in a separate file
  JMP PIDogeHandleAHasTool
PIDogeHandleANoTool:
  JSR DogeWantPickup
PIDogeHandleAHasTool:
;and actions "consume" the button presses here. doge's top-level input processing should do hold checking as well.
  LDA cur_ent_input
  EOR #BUTTON_A
  STA cur_ent_input
  RTS

PIDogeHandleB:
;if doge has a tool, drop it, otherwise check for a collision with a tool and pick it up
  LDA cur_ent_tool
  BEQ PIDogeHandleBNoTool
  JSR DogeDropTool
  JMP PIDogeHandleBHadTool
PIDogeHandleBNoTool:
  JSR DogeWantTool
PIDogeHandleBHadTool:
  LDA cur_ent_input
  EOR #BUTTON_B ;"consume" the B-button press
  STA cur_ent_input
  RTS

PIHandleUp:
;update forces and set dir
  LDA cur_ent_yforce
  SEC
  SBC #$01
  STA cur_ent_yforce
  LDA #$00
  STA cur_ent_dir
;and set action to walk
  LDA #DOGE_ACTION_WALK ;pretty sure this will work for zombies too
  STA cur_ent_action
  RTS

PIHandleR:
  LDA cur_ent_xforce
  CLC
  ADC #$01
  STA cur_ent_xforce
  LDA #$01
  STA cur_ent_dir
  LDA #DOGE_ACTION_WALK
  STA cur_ent_action
  RTS

PIHandleDN:
  LDA cur_ent_yforce
  CLC
  ADC #$01
  STA cur_ent_yforce
  LDA #$02
  STA cur_ent_dir
  LDA #DOGE_ACTION_WALK
  STA cur_ent_action
  RTS

PIHandleL:
  LDA cur_ent_xforce
  SEC
  SBC #$01
  STA cur_ent_xforce
  LDA #$03
  STA cur_ent_dir
  LDA #DOGE_ACTION_WALK
  STA cur_ent_action
  RTS

;just gonna include the a and b handlers here so we don't have to worry about it in the main source.
  .include "nldogehandleab.asm"
;nice to have a file under 200 lines, innit?