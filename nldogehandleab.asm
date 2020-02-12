;these are the input handlers for A and B button presses from doge.
DogeUseTool:
;determine which tool doge has and act accordingly
  LDA cur_ent_tool
  CMP #TOOL_HAMMER
  BNE DogeUseToolNotHammer
  JSR DogeUseHammer
DogeUseToolNotHammer:
  LDA cur_ent_tool
  CMP #TOOL_TORCH
  BNE DogeUseToolNotTorch
  JSR DogeUseTorch
DogeUseToolNotTorch:
  LDA cur_ent_tool
  CMP #TOOL_RIFLE
  BNE DogeUseToolNotRifle ;if we get down to there we have a problem
  JSR DogeUseRifle
DogeUseToolNotRifle:
;could put some error checking here if we need it
  RTS

DogeWantPickup:
;check for clipping with furniture, randomly spawn pickups if so
;put doge into obj_ent, which is what ClipCheck reads from
  LDA cur_ent_x
  STA obj_ent_x
  LDA cur_ent_y
  STA obj_ent_y
  JSR ClipCheck
  LDA clip_flag
  CMP #$02 ;$02 is the clip map code for furniture
  BNE DogeNoGetPickup
  ;get a random number, check it against the drop rate
  LDX clock
  LDA $00, x
  AND #%00011111
  CMP #$01
  BNE DogeNoGetPickup
;if we're in here, doge is a lucky boy and gets a pickup
  ;JSR SpawnPickup ;this is just a stand-in right now. either implement in here or write a really clean sub.
DogeNoGetPickup:
  RTS

DogeDropTool:
;look for a free space around doge, spawn his current tool there and set his tool_type to zero
;make a virtual object with doge's coordinates, scoot it $10 in each direction and do clipping checks til
;we get a zero
  LDA cur_ent_x
  STA obj_ent_x
  LDA cur_ent_y
  SEC
  SBC #$10 ;checking above first
  STA obj_ent_y
  JSR ClipCheck
  LDA clip_flag
  BEQ DogeDropToolHere
  LDA obj_ent_y
  CLC
  ADC #$20 ;probably faster to do it criss-cross than around
  STA obj_ent_y
  JSR ClipCheck
  LDA clip_flag
  BEQ DogeDropToolHere
  LDA cur_ent_y
  STA obj_ent_y
  LDA obj_ent_x
  SEC
  SBC #$10 ;now to the right
  STA obj_ent_x
  JSR ClipCheck
  LDA clip_flag
  BEQ DogeDropToolHere
  LDA obj_ent_x
  CLC
  ADC #$20 ;and to the left
  STA obj_ent_x
  JSR ClipCheck
  LDA clip_flag
  BEQ DogeDropToolHere
;and if there's no free space, just hang onto the tool
  JMP DogeNoDropTool
DogeDropToolHere:
  LDA cur_ent_tool
  STA new_ent_type
  JSR SpawnEnt
  LDX new_ent
  LDA obj_ent_x
  STA ent_blob + ENT_X, x
  LDA obj_ent_y
  STA ent_blob + ENT_Y, x
;set doge's stamina to the tool's hp, like ammo tracking
  LDA cur_ent_sta
  STA ent_blob + ENT_HP, x
;don't think it really matters what doge's stamina is at this point, so just don't worry about it til next tool
;the new tool ent should be spawned and placed now. set doge's tool to zero
  LDA #$00
  STA cur_ent_tool

DogeNoDropTool:
  RTS

DogeWantTool:
;check for collisions with a tool, take the first one we find
;first we gotta loop through ent_blob and check for tool types
  LDX #$10 ;we can at least skip doge and save one iteration
DogeWantToolLoop:
  LDA ent_blob + ENT_TYPE, x
  CMP #ENT_TYPE_HAMMER
  BEQ DogeWantToolCheckTool
  CMP #ENT_TYPE_TORCH
  BEQ DogeWantToolCheckTool
  CMP #ENT_TYPE_RIFLE
  BEQ DogeWantToolCheckTool
  JMP DogeWantToolNotThis
DogeWantToolCheckTool:
  LDA #$14
  STA $80
  ;load the tool into obj_ent and call EntCollision
  STX obj_ent
  JSR EntCollision
  LDA ent_collision
  BEQ DogeWantToolNotThis
  ;if we have a collision, read in the tool's type and hp, set them to doge's tool and stamina
  LDA ent_blob + ENT_TYPE, x
  STA cur_ent_tool
  LDA ent_blob + ENT_HP, x
  STA cur_ent_sta
  ;then destroy the tool from the blob
  LDA #ENT_TYPE_DNE
  STA ent_blob + ENT_TYPE, x
  ;and get out
  JMP DogeGotTool
DogeWantToolNotThis:
  ;iterate the search loop and go to the next ent
  TXA
  CLC
  ADC #$10
  TAX
  BCC DogeWantToolLoop
DogeGotTool:
  RTS



;sub-handlers for some big specific cases. hope the stack can handle these call levels
DogeUseHammer:
;first, set his action
  LDA #DOGE_ACTION_HAMMER
  STA cur_ent_action
;then make a virtual object in front of doge and check it for a collision with wood

;if wood is found, raise its hp

;lower doge's stamina
  RTS

DogeUseTorch:
;set his action
  LDA #DOGE_ACTION_TORCH
  STA cur_ent_action
;torch does damage to wood, so check the same way as with hammer

;if wood is found, lower its hp

;lower doge's stamina

;think the only other thing the torch does is scare off zombies, and that should be handled in ZombieBrains.

  RTS

DogeUseRifle:
;set his action
  LDA #DOGE_ACTION_RIFLE
  STA cur_ent_action
;think we have to handle the actual attack here. cast a ray in front of doge, check for zombies intersecting it,
;lower their hp if they are

;then lower doge's stamina

  RTS