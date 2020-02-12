ProcessInput: ;may be a good idea to de-spaghettify this, maybe break it up into jsrs
  PHA ;register safety
  TYA
  PHA
  TXA
  PHA

  LDA ptr_lo ;pointer safety
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


;takes any ent cur_ent and sets all apropriate variables based on cur_ent_input
;blob iteration should probably happen on the inside so we don't muck up the Forever loop
;clean some stuff up, check where we are on register usage for that kind of thing and make it work. [HOPEFULLY DONE]

; ok, so to iterate over the ent blob, we need to zero out cur_ent and call LoadEnt, check for DNE, 
; do all the actual action processing, increment cur_ent and loop back up
  LDA #$00
  STA cur_ent

PIBigLoop: ;here we go, fasten your seatbelts
  JSR LoadEnt
  LDA cur_ent_type
  CMP #ENT_TYPE_DNE
  BEQ PIBigLoopDoneBase ;damn branch limit
  JMP PIBigLoopNotDone
PIBigLoopDoneBase:
  JMP PIBigLoopDone
PIBigLoopNotDone: ;sorry, this really sucks, 
                  ;but it's about the most direct way to deal with simple branching over big blocks

;TODO: add tool drop and pickup once all the collision code is done [DONE]
PICheckA:
  LDA cur_ent_input ;cur_ent_input is a byte in the same fomat as joyx. best way to do this is probably
  AND #BUTTON_A      ;repeatedly load it into A, AND it with each button to get essentially and boolean 
  BNE PIHandleA     ;non-zero/zero value, and bne to a handler for that button
PICheckB:           ;probably wanna deal with button combos, so be sure each branch comes back up to the next button
  LDA cur_ent_input
  AND #BUTTON_B
  BNE PIHandleBBase
PICheckSel:
  LDA cur_ent_input
  AND #BUTTON_SEL
  BNE PIHandleSelBase
PICheckSta:
  LDA cur_ent_input
  AND #BUTTON_STA
  BNE PIHandleStaBase
PICheckUp:
  LDA cur_ent_input
  AND #BUTTON_UP
  BNE PIHandleUpBase
PICheckDn:
  LDA cur_ent_input
  AND #BUTTON_DN
  BNE PIHandleDnBase
PICheckL:
  LDA cur_ent_input
  AND #BUTTON_L
  BNE PIHandleLBase
PICheckR:
  LDA cur_ent_input
  AND #BUTTON_R
  BNE PIHandleRBase

;need a default for no input. hope this is a good place for it
;we're checking all the buttons every time, so need to check for actual joy=$00 first
  LDA cur_ent_input
  BNE PINoDefault
  LDA #DOGE_ACTION_STAND
  STA cur_ent_action ;some actions may last longer than a keypress. revisit this if so.
  LDA #$00
  STA cur_ent_cur_frame ;frame and max_frames should be fixed in load_sprites, but they look pretty janky right now. see if this fixes it.

PINoDefault:

  JMP PIDone    ;fall through if no input and get back to return code

;branch limit jump table
PIHandleBBase:
  JMP PIHandleB
PIHandleSelBase:
  JMP PIHandleSel
PIHandleStaBase:
  JMP PIHandleSta
PIHandleUpBase:
  JMP PIHandleUp
PIHandleDnBase:
  JMP PIHandleDn
PIHandleLBase:
  JMP PIHandleL
PIHandleRBase:
  JMP PIHandleR

PIHandleA:
  ;doge uses a tool, don't think anybody else uses BUTTON_A. if so add an ent_type check
  ;first check oldjoy1 to make sure we're on a press and not a hold
  LDA joy1
  AND oldjoy1
  AND #BUTTON_A
  BEQ PIHAHoldBase
  ;check the current tool and set the action or fall through if no tool
  LDA cur_ent_tool
  CMP #TOOL_HAMMER
  BEQ PIToolHammer
  CMP #TOOL_TORCH
  BEQ PIToolTorch
  CMP #TOOL_RIFLE
  BEQ PIToolRifle
  JMP PIHANoTool


PIToolHammer: ;always check and set sta when tools are used
  LDA cur_ent_sta
  BEQ PIHAHoldBase
  LDA #DOGE_ACTION_HAMMER
  STA cur_ent_action
  DEC cur_ent_sta
  JMP PIHAHold

PIToolTorch:
  LDA cur_ent_sta
  BEQ PIHAHoldBase
  LDA #DOGE_ACTION_TORCH
  STA cur_ent_action
  DEC cur_ent_sta
  JMP PIHAHold

PIToolRifle:
  LDA cur_ent_sta
  BEQ PIHAHoldBase
  LDA #DOGE_ACTION_RIFLE
  STA cur_ent_action
  DEC cur_ent_sta
  JMP PIHAHold

;yet more jump tables
PIHAHoldBase:
  JMP PIHAHold

PIHANoTool:
  ;if doge isn't holding a tool, check for clipping with chests and sofas, randomly spawn pickups if so
  ;guess clipping with furniture will return a 2. make sure ClipCheck can do that.
  LDA cur_ent_x
  STA obj_ent_x ;don't forget that ClipCheck operates on obj_ent
  LDA cur_ent_y
  STA obj_ent_y
  JSR ClipCheck
  LDA clip_flag
  CMP #$02
  BNE PIHAHoldBase2
  ;get a random number, guess let's set a hard-coded drop-rate to 1/$10 for now, so mask it to %00011111
  LDX clock
  LDA $00, x
  AND #%00011111
  CMP #$01
  BNE PIHANoPickupBase
  ;spawn a pickup here
  ;probably the best way to do it will be to set it to doge's coordinates, then move it a few tiles in any direction
  ;that won't clip it into something
  LDA cur_ent_x
  STA obj_ent_x
  LDA cur_ent_y
  STA obj_ent_y
  ;try up first
  LDA obj_ent_y
  SEC
  SBC #$10
  STA obj_ent_y
  JSR ClipCheck
  BEQ PIHASpawnPickup
  ;then to the right
  LDA obj_ent_y
  CLC
  ADC #$10 ;walk it back down
  STA obj_ent_y
  LDA obj_ent_x
  CLC
  ADC #$10
  STA obj_ent_x
  JSR ClipCheck
  BEQ PIHASpawnPickup
  ;below
  LDA obj_ent_x
  SEC
  SBC #$10 ;walk it back to the left
  STA obj_ent_x
  LDA obj_ent_y
  CLC
  ADC #$10
  STA obj_ent_y
  JSR ClipCheck
  BEQ PIHASpawnPickup
  ;and finally to the left
  LDA obj_ent_y
  CLC
  ADC #$10
  STA obj_ent_y
  LDA obj_ent_x
  SEC
  SBC #$10
  STA obj_ent_x
  JSR ClipCheck ;if no luck here, we're sol, so don't bother
  BEQ PIHASpawnPickup
  JMP PIHANoPickupBase ;gtfo

;yet more jump tables
PIHAHoldBase2:
  JMP PIHAHold
PIHANoPickupBase:
  JMP PIHANoPickup

PIHASpawnPickup:
  ;we've got an x and y, think all else we need is a pickup type
  ;should put the bandaid in here too. so four types, guess pick one at random
  LDA clock ;clock's probably the same since last time, so get more random
  TAX
  LDA $00, x
  TAX
  LDA $00, x
  ;and mask it for 0-3
  AND #%00000011
  CMP #$00 ;bandaid
  BNE PIHASpawnWood ;just jump down to the next case til we're donne
  LDA #ENT_TYPE_BANDAID
  STA new_ent_type
  JMP PIHASpawnPickupDone
PIHASpawnWood:
  CMP #$01 ;wood_pu
  BNE PIHASpawnCloth
  LDA #ENT_TYPE_WOOD_PU
  STA new_ent_type
  JMP PIHASpawnPickupDone
PIHASpawnCloth:
  CMP #$02 ;cloth_pu
  BNE PIHASpawnAmmo
  LDA #ENT_TYPE_CLOTH_PU
  STA new_ent_type
  JMP PIHASpawnPickupDone
PIHASpawnAmmo:
  CMP #$03 ;ammo_pu
  BNE PIHASpawnPickupDone ;should never happen, but just in case
  LDA #ENT_TYPE_AMMO_PU
  STA new_ent_type
  JMP PIHASpawnPickupDone
PIHASpawnPickupDone:
  ;now we've got an x, a y, and a type. should be enough to work with
  JSR SpawnEnt
  ;SpawnEnt returns a blob index in 1s on new_ent. gotta multiply it by $10 for direct access to set the coordinates
  LDA new_ent
  ASL a
  ASL a
  ASL a
  ASL a
;using x-addressing
  TAX
  ;TAY
  ;LDA #LOW(ent_blob)
  ;STA ptr_lo
  ;LDA #HIGH(ent_blob)
  ;STA ptr_hi
  LDA obj_ent_x
;using x-addressing
  STA ent_blob + ENT_X, x
  ;STA [ptr_lo + ENT_X], y ;oh god more of this
  LDA obj_ent_y
  STA ent_blob + ENT_Y, x
  ;STA [ptr_lo + ENT_Y], y ;leaving this here as an example of how to NOT acess a big data structure with a pointer.
  ;[pointer + CONST], y reads a value out of CONST bytes ahead of the address of (not in) pointer, 
  ;then accesses the address
  ;in that value + y. it will NOT do what you want it to do if you only have one pointer at address "pointer".
  ;this kind of thing might work for like a struct of all pointers, but we're not doing that here
  ;i did this all over the rough draft of the code, and am now taking a couple of weekends to re-do it the right way
  ;one solution is to just use the base address of the structure array and x-indexing on the array cells (*cell size)
  ;with a constant for the struct element you're looking at in that cell
  ;another is to set your pointer to the right cell in the first place, by adding a cell index to it, 
  ;then set y to the element
  ;the latter is probably the only way to access structs outside of zeropage and/or bigger than $FF bytes

PIHANoPickup: ;here in case we need it for more stuff
PIHAHold: ;ProcessInputHandleAHold for clarity
;might be a good idea to clear button bits out of the input byte as they're used, at least the ones that don't
;need to know if they're being held down
  LDA cur_ent_input
  EOR #BUTTON_A
  STA cur_ent_input
  JMP PICheckB

PIHandleB:
  ;pickup/drop tool. this is gonna be a fun chunk of code.

  ;NOTE: pickups will not use this, and just go by collisions instead. 
  ;also, the pickup will only apply to the current tool, and just disappear if the wrong type.
  ;that'll really piss them off.

  ;first check if we do in fact have a tool
  LDA cur_ent_tool
  BEQ PITPickupBase ;if tool type is zero, look for a tool and pick it up
;otherwise, find an open space around doge, drop the tool and set cur_ent_tool to zero
;guess run a check on the collision map tiles to each direction of doge, drop it on the first one that returns zero
  ;make a pretend obj_ent for the ClipCheck and fall through if it's clear, or adjust the coordinates and try again
  LDA cur_ent_x
  STA obj_ent_x ;check above first
  LDA cur_ent_y
  SEC
  SBC #$10
  STA obj_ent_y
  JSR ClipCheck
  LDA clip_flag
  BEQ DropTool
  LDA cur_ent_x ;now to the right
  CLC
  ADC #$10
  STA obj_ent_x
  LDA cur_ent_y
  STA obj_ent_y
  JSR ClipCheck
  LDA clip_flag
  BEQ DropTool
  LDA cur_ent_x ;below
  STA obj_ent_x
  LDA cur_ent_y
  CLC
  ADC #$10
  STA obj_ent_y
  JSR ClipCheck
  LDA clip_flag
  BEQ DropTool
  LDA cur_ent_x ;to the left
  SEC
  SBC #$10
  STA obj_ent_x
  LDA cur_ent_y
  STA obj_ent_y
  JSR ClipCheck
  LDA clip_flag
  BEQ DropTool
;if for whatever reason there's nowhere to drop it, just don't
  JMP PIHBDone

;jump table
PITPickupBase:
  JMP PITPickup

DropTool:
 ;just spawn a new ent for the tool
  LDA cur_ent_tool
;make sure there really is a tool
  CMP #TOOL_HAMMER
  BEQ YesReallyHasTool
  CMP #TOOL_TORCH
  BEQ YesReallyHasTool
  CMP #TOOL_RIFLE
  BEQ YesReallyHasTool
  JMP PIHBDone
YesReallyHasTool:
  ;really hope tool types are the same as ent types
  STA new_ent_type
  JSR SpawnEnt
  ;and set the coordinates. ent indexes are in 1's. need to multiply by $10 to get an offset
  LDA new_ent
  ASL a
  ASL a
  ASL a
  ASL a
;using x-addressing
  TAX ;offset from ent_blob is in x
  ;TAY ;offset from ent_blob is in y
  ;LDA #LOW(ent_blob)
  ;STA ptr_lo
  ;LDA #HIGH(ent_blob)
  ;STA ptr_hi
  LDA obj_ent_x
;using x-addressing
  STA ent_blob + ENT_X, x
  ;STA [ptr_lo + ENT_X], y
  LDA obj_ent_y
;using x-addressing
  STA ent_blob + ENT_Y, x
  ;STA [ptr_lo + ENT_Y], y
  ;and set its hp to doge's sta. kind of an 'ammo'-tracking system for each tool
  LDA cur_ent_sta
;using x-addressing
  STA ent_blob + ENT_HP, x
  ;STA [ptr_lo + ENT_HP], y

;don't forget to set his tool back to zero
  LDA #$00
  STA cur_ent_tool

;then check that it doesn't collide with another tool, and scoot it away if it does or there will be hell to pay
;new juggling problem. don't really wanna mess with cur_ent, but need it for collision detection. wat do?
;probably just let routine collision detection in the main loop deal with it
;and if we need to drop some code down the line, just spawn the new tool with doge's coordinates. not like we're
;using autopickup
  JMP PIHBDone

PITPickup: ;check for collisions with a tool, destroy it and set cur_ent_tool to ENT_TYPE_x
;getting about time to write some collision code for ents, need to decide whether a set of obj_ent vars is necessary
;or just loop through the blob and do type checking. the latter would probably be a little more efficient.
  LDA #$00
  STA ent_collision
  TAX ;this is gonna be fun to restructure. maybe use y as a loop counter and x as an index
  ;TAY ;see what we were trying to do first of all. see if there's any reason x was set in the old version.
  ;LDA #LOW(ent_blob)
  ;STA ptr_lo
  ;LDA #HIGH(ent_blob)
  ;STA ptr_hi
;loop through the blob looking for tools
PITPFindToolLoop:
  LDA ent_blob + ENT_TYPE, x
  ;LDA [ptr_lo + ENT_TYPE], y
  CMP #ENT_TYPE_HAMMER ;have to check against each tool type. and that's a good thing
  BEQ PITPCheckTool ;if we have one, jump down to check for collisions
  CMP #ENT_TYPE_TORCH
  BEQ PITPCheckTool
  CMP #ENT_TYPE_RIFLE
  BEQ PITPCheckTool
  JMP PITPNextTool ;otherwise, skip collision check and jump down to index increment and loop back up
;when one is found, set it to obj_ent and check collisions
PITPCheckTool:
  TXA
  ;TYA
  STA obj_ent ;pretty sure EntCollision assumes this will be a direct offset, i.e. in $10s. 
              ;should probably standardize that
  JSR EntCollision  ;check this module for register safety
;if ent_collision is set, we're good, otherwise keep looking
  LDA ent_collision
  BNE PITPCanHazTool
PITPNextTool:
  TXA
  ;TYA
  CLC
  ADC #$10 ;jumping down a whole ent entry
  TAX
  ;TAY
  ;yeah fall out if we've already looped over the whole blob
  CPX #$00
  ;CPY #$00 ;might set the zero or carry flag, not sure, doing this to be safe for now
  BNE PITPFindToolLoop ;looks like this whole loop just uses y right now, easy enough
  ;and get out otherwise
  JMP PIHBDone
PITPCanHazTool: ;alright, we found a tool, give it to doge
  LDA ent_blob + ENT_TYPE, x
  STA cur_ent_tool
  ;set doge's sta to the tool's hp, 'ammo'-tracking
  LDA ent_blob + ENT_HP, x
  STA cur_ent_sta
  LDA #ENT_TYPE_DNE ;and take it out of the game
  STA ent_blob + ENT_TYPE, x
PIHBDone:
;clearing the B bit from cur_ent_input
  LDA cur_ent_input
  EOR #BUTTON_B
  STA cur_ent_input
  JMP PICheckSel

PIHandleSel:
;don't think select does anything right now

  JMP PICheckSta

PIHandleSta:
;probably set a pause bit somewhere
  JMP PICheckUp

PIHandleUp:
;fun and easy stuff, set motion forces
;may do variable agility later, using literal constants right now
  LDA cur_ent_yforce
  SEC
  SBC #$01 ;change this if agility ends up being variable
  STA cur_ent_yforce
;also set dirs here
  LDA #$00
  STA cur_ent_dir
;and set action to walk so animation works
  LDA #DOGE_ACTION_WALK ;double check that this action number is universal and applies to at least zombies too
  STA cur_ent_action
  JMP PICheckDn

PIHandleDn:
  LDA cur_ent_yforce
  CLC
  ADC #$01 ;change this if agility ends up being variable
  STA cur_ent_yforce

  LDA #$02
  STA cur_ent_dir

  LDA #DOGE_ACTION_WALK
  STA cur_ent_action
  JMP PICheckL

PIHandleL:
  LDA cur_ent_xforce
  SEC
  SBC #$01 ; change this if agility ends up being variable
  STA cur_ent_xforce

  LDA #$03
  STA cur_ent_dir

  LDA #DOGE_ACTION_WALK
  STA cur_ent_action
  JMP PICheckR

PIHandleR:
  LDA cur_ent_xforce
  CLC
  ADC #$01 ;change this if agilit ends up being variable
  STA cur_ent_xforce

  LDA #$01
  STA cur_ent_dir

  LDA #DOGE_ACTION_WALK
  STA cur_ent_action

;BUTTON_R is the last button to check, so just fall through
PIDone:
;pretty sure we should save cur_ent back into the blob.
  JSR SaveEnt
;make sure this is how it works

PIBigLoopDone: ;old ent is saved back into the blob, so just increment cur_ent, 
;check it's less than 10 (make sure it should be in ones, otherwise it should just check for rollover)
;and branch back up to PIBigLoop
  INC cur_ent
  LDA cur_ent
  SEC ;i no longer trust bmi/bpl for like anything at all, so check the carry flag
  CMP #$10
  BCS PIBigLoopBase
  JMP PIBigLoopReallyDone
PIBigLoopBase:
  JMP PIBigLoop
PIBigLoopReallyDone:

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
  STA ptr_lo ;pointer safety

  PLA
  TAX
  PLA
  TAY
  PLA ;register safety

  RTS
