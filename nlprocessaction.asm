ProcessAction:
  PHP
  PHA

  TYA
  PHA
  TXA
  PHA

;action handlers that deal with everything not in the input modules, physics models, animation module, etc.
;doublecheck everything you put in here.
;should probably be called inside the input handler for BUTTON_A presses
;can access everything from cur_ent that way and not bother with more looping
;except for checks for interaction with other ents
;guess we should iterate the cur_ent
  LDA #$00
  STA cur_ent
ProcessActionBigLoop:
  JSR LoadEnt
  LDA cur_ent_type ;only doge has BUTTON_A actions right now, so get out for everybody else
  CMP #ENT_TYPE_DOGE
  BNE PANotDogeBase
  LDA cur_ent_action
  CMP #DOGE_ACTION_HAMMER
  BEQ PAHammer
  CMP #DOGE_ACTION_TORCH
  BEQ PATorchBase
  CMP #DOGE_ACTION_RIFLE
  BEQ PARifleBase
PANotDogeBase:
  JMP PANotDoge ;just get out if there's no useful action. no need to handle walk or stand
PATorchBase: ;the real addresses for these are too far away for branching
  JMP PATorch
PARifleBase:
  JMP PARifle

PAHammer:

;need to look one tile ahead of doge based on his direction, if there's wood there upgrade its hp to some max
;also check if we're adjacent to an entry point with no wood, and spawn wood if so
;thankfully we have entry point coordinates starting at offset-zero of EntryPoints, every third byte
;just check the appropriate ones for each direction at the end of its loop, maybe use a flag to keep track
;so to load each one, x will be [EntryPoints + 0],y, then y will be [EntryPoints + 1], y
;dir will be [EntryPoints + 2], y, but check for the opposite of doge's dir (2 for 0, 3 for 1, etc)
;increment y-register by 3 to loop through
  LDA #$00
  STA wood_found

  LDA cur_ent_dir
  CMP #$00
  BEQ PAHUp
  CMP #$01
  BEQ PAHRight
  CMP #$02
  BEQ PAHDownBase
  CMP #$03
  BEQ PAHLeftBase
  JMP PANotDoge ;should only happen if something gets corrupted, but handle it gracefully
PAHDownBase: ;too far away to branch
  JMP PAHDown
PAHLeftBase:
  JMP PAHLeft

PAHUp:
;look for wood objects with x within 16px of doge and y less than, but no more than 8px less than doge
;first rule out everything that's not wood
  LDX #$00
PAHUpBlobLoop:
  LDA ent_blob + ENT_TYPE, x
  CMP #ENT_TYPE_WOOD
  BNE PAHUNotWood
  ;k, now do the position checks. x will be the big one for up and down, gotta check positive and negative difference
  ;just need to check a small range for y, try to order the sbc to make sure it's positive in each case
  LDA ent_blob + ENT_X, x
  SEC
  SBC cur_ent_x
  BCC PAHUXNeg 
  SEC
  CMP #$10
  ;BPL PAHUNotWood ;go on to the next one if it's too far to the right
  BCS PAHUNotWood
  JMP PAHUYCheck ;just write the y-check once per dir to save some code space
PAHUXNeg:
  SEC
  CMP #$EF
  ;BMI PAHUNotWood ;go on to the next one if it's too far to the left
  BCC PAHUNotWood
  ;JMP PAHUYCheck
PAHUYCheck:
  ;blob y should be less than doge y, and the difference should be less than or equal to 8
  ;may need to fine tune the range depending on how collisions behave. up to $10 or so would be acceptable
  LDA cur_ent_y
  SEC
  SBC ent_blob + ENT_Y, x
  SEC
  CMP #$10
  ;BPL PAHUNotWood ;thanks to the rollover, a negative result (wood below doge) would look very high here
  BCS PAHUNotWood
  ;so he's using the hammer with wood in a good position. fix that wood.
  LDA ent_blob + ENT_HP, x
  CMP #$FF
  BEQ PAHUWoodFull
  CLC
  ADC #$01 ;the amount to raise the wood's hp, tweak as needed
  STA ent_blob + ENT_HP, x
PAHUWoodFull:
  LDA #$01
  STA wood_found ;set the flag so we don't spawn wood

PAHUNotWood:
  TXA
  CLC
  ADC #$10
  TAX
  BCC PAHUpBlobLoop ;hope the carry flag survives the TAY. pretty sure it should
  
  ;JMP PANotDoge
  JMP PAHSpawnWood
PAHRight:
  ;now just do the same thing three more times with the checks shuffled around, then the same for the torch w/ -hp
  LDX #$00
PAHRBlobLoop:
  LDA ent_blob + ENT_TYPE, x
  CMP #ENT_TYPE_WOOD
  BNE PAHRNotWood
  ;check y first. the difference should be within #$10
  LDA ent_blob + ENT_Y, x
  SEC
  SBC cur_ent_y
  BCC PAHRYNeg
  SEC
  CMP #$10
  ;BPL PAHRNotWood
  BCS PAHRNotWood
  JMP PAHRXCheck
PAHRYNeg:
  SEC
  CMP #$EF
  ;BMI PAHRNotWood
  BCC PAHRNotWood
  JMP PAHRXCheck
PAHRXCheck:
  ;load x out of the blob for the subtraction so we always get a positive result if it's to the right
  LDA ent_blob + ENT_X, x
  SEC
  SBC cur_ent_x
  SEC
  CMP #$20 
  ;BPL PAHRNotWood
  BCS PAHRNotWood
;if we're still here, we're fixing a wood
  LDA ent_blob + ENT_HP, x
  CMP #$FF
  BEQ PAHRWoodFull
  CLC
  ADC #$01
  STA ent_blob + ENT_HP, x
PAHRWoodFull:
  LDA #$01
  STA wood_found

;looks right
PAHRNotWood:
  TXA
  CLC
  ADC #$10
  TAX
  BCC PAHRBlobLoop

  ;JMP PANotDoge
  JMP PAHSpawnWood
PAHDown:
;same x check as for up, reverse the operands for the subtract in the y check
  LDX #$00
PAHDBlobLoop:
  LDA ent_blob + ENT_TYPE, x
  CMP #ENT_TYPE_WOOD
  BNE PAHDNotWood

  LDA ent_blob + ENT_X, x
  SEC
  SBC cur_ent_x
  BCC PAHDXNeg
  SEC
  CMP #$10
  ;BPL PAHDNotWood
  BCS PAHDNotWood
  JMP PAHDYCheck
PAHDXNeg:
  SEC
  CMP #$EF
  ;BMI PAHDNotWood
  BCC PAHDNotWood
  ;JMP PAHDYCheck
PAHDYCheck:
;we want the blob y to be greater and within $18
  LDA ent_blob + ENT_Y, x
  SEC
  SBC cur_ent_y
  SEC
  CMP #$20
  ;BPL PAHDNotWood
  BCS PAHDNotWood
  LDA ent_blob + ENT_HP, x
  CMP #$FF
  BEQ PAHDWoodFull
  CLC
  ADC #$01
  STA ent_blob + ENT_HP, x
PAHDWoodFull:
  LDA #$01
  STA wood_found

PAHDNotWood:
  TXA
  CLC
  ADC #$10
  TAX
  BCC PAHDBlobLoop

  ;JMP PANotDoge
  JMP PAHSpawnWood
PAHLeft: ;one more. these are fairly straightforward, but laborious first thing in the morning.
;same y check as right, x check wants doge x greater than blob x
  LDX #$00
PAHLBlobLoop:
  LDA ent_blob + ENT_TYPE, x
  CMP #ENT_TYPE_WOOD
  BNE PAHLNotWood

  LDA ent_blob + ENT_Y, x
  SEC
  SBC cur_ent_y
  BCC PAHLYNeg
  SEC
  CMP #$10
  ;BPL PAHLNotWood
  BCS PAHLNotWood
  JMP PAHLXCheck

PAHLYNeg:
  SEC
  CMP #$EF
  ;BMI PAHLNotWood
  BCC PAHLNotWood
  ;JMP PAHLXCheck

PAHLXCheck:
  ;we want doge x greater than blob x, within $10
  LDA cur_ent_x
  SEC
  SBC ent_blob + ENT_X, x
  SEC
  CMP #$10
  ;BPL PAHLNotWood
  BCS PAHLNotWood
  LDA ent_blob + ENT_HP, x
  CMP #$FF
  BEQ PAHLWoodFull
  CLC
  ADC #$01
  STA ent_blob + ENT_HP, x
PAHLWoodFull:
  LDA #$01
  STA wood_found

PAHLNotWood:
  TXA
  CLC
  ADC #$10
  TAX
  BCC PAHLBlobLoop

  ;JMP PANotDoge
  
;oh yeah, we also wanna spawn wood if we're at an entry point and there's no wood there
PAHSpawnWood:

  LDA wood_found
  BNE PANotDogeBase2
;this only needs to happen once a runthru of the animation.
  LDA cur_ent_cur_frame
  CMP #$01
  BNE PANotDogeBase2

  ;spawn wood here. first check that doge is facing an entryway, then copy the x, y, dir of that entryway into
  ;the wood ent and call SpawnEnt
  LDA cur_ent_dir
  CMP #$00
  BEQ PAHSpawnWoodUp
  CMP #$01
  BEQ PAHSpawnWoodRBase
  CMP #$02
  BEQ PAHSpawnWoodDnBase
  CMP #$03
  BEQ PAHSpawnWoodLBase
PANotDogeBase2:
  JMP PANotDoge
PAHSpawnWoodRBase:
  JMP PAHSpawnWoodR
PAHSpawnWoodDnBase:
  JMP PAHSpawnWoodDn
PAHSpawnWoodLBase:
  JMP PAHSpawnWoodL
PAHSpawnWoodUp:
;loop through EntryPoints, check that dir (offset + 2) is opposite doge's, then do x and y checks against it as above
;spawn wood if everything checks out
  LDX #$00
PAHSpawnWoodUpLoop:
  ;check entries for dir=$02
  LDA EntryPoints + 2, x
  CMP #$02
  BNE PAHSWULNotIt
  ;then do a +/- x check and a 1-tile range "above doge" y check
  LDA EntryPoints, x
  SEC
  SBC cur_ent_x
  BCC PAHSWULXNeg ;these labels are getting ridiculous, hope i'm not running up against some length limit
  SEC
  CMP #$10
  ;BPL PAHSWULNotIt
  BCS PAHSWULNotIt
  JMP PAHSWULYCheck
PAHSWULXNeg:
  SEC
  CMP #$EF
  ;BMI PAHSWULNotIt
  BCC PAHSWULNotIt
  ;JMP PAHSWULYCheck
PAHSWULYCheck:
  LDA cur_ent_y ;doge's y should be greater or the difference should roll over
  SEC
;the entry point's y has a 1-byte offset
  SBC EntryPoints + 1, x
  SEC
  CMP #$10
  ;BPL PAHSWULNotIt ;think this label and ...NoMatch will probably be the same address
  BCS PAHSWULNotIt
;stamina check
  LDA ent_blob + ENT_STA
  BEQ PAHSWLTooTired
  ;now we spawn wood
  LDA #ENT_TYPE_WOOD
  STA new_ent_type
  JSR SpawnEnt
  DEC ent_blob + ENT_STA
  ;and copy x, y, and dir from the entry point. guess we can use obj_ent for a holding area
  LDA EntryPoints, x
  STA obj_ent_x
  LDA EntryPoints + 1, x
  STA obj_ent_y
  LDA EntryPoints + 2, x
  ;doors only have dir=0,1, so we need to mask off the entrypoint's dir
  AND #%00000001
  STA obj_ent_dir
  TXA
  PHA

  LDX new_ent
  
  LDA obj_ent_x
  STA ent_blob + ENT_X, x
  LDA obj_ent_y
  STA ent_blob + ENT_Y, x
  LDA obj_ent_dir
  STA ent_blob + ENT_DIR, x
  PLA
  TAX
;should probably get out of here now
PAHSWLTooTired:
  JMP PANotDoge

PAHSWULNotIt:

  TXA
  CLC
  ADC #$03
  TAX
  SEC
  CMP #$21 ;eleven entries times three bytes
  ;BMI PAHSpawnWoodUpLoop
  BCC PAHSpawnWoodUpLoop

  JMP PANotDoge

PAHSpawnWoodR:
;need a bigger view port to copy the whole block down from above with all the right vars changed
  LDX #$00
PAHSpawnWoodRLoop:
;check entries for dir=$03
  LDA EntryPoints + 2, x
  CMP #$03
  BNE PAHSWRLNotIt
;then check +/- y for within $10 of doge
  LDA EntryPoints + 1, x
  SEC
  SBC cur_ent_y
  BCC PAHSWRLYNeg
  SEC
  CMP #$10
  ;BPL PAHSWRLNotIt
  BCS PAHSWRLNotIt
  JMP PAHSWRLXCheck
PAHSWRLYNeg:
  SEC
  CMP #$EF
  ;BMI PAHSWRLNotIt
  BCC PAHSWRLNotIt
  JMP PAHSWRLXCheck
PAHSWRLXCheck:
;the entry point's x should be higher than doge's and within $18
  LDA EntryPoints, x
  SEC
  SBC cur_ent_x
  SEC
  CMP #$20
  ;BPL PAHSWRLNotIt
  BCS PAHSWRLNotIt
;sta check
  LDA ent_blob + ENT_STA
  BEQ PAHSWRTooTired
;spawn wood here
  LDA #ENT_TYPE_WOOD
  STA new_ent_type
  JSR SpawnEnt
  DEC ent_blob + ENT_STA
  ;and copy x, y, and dir from the entry point. guess we can use obj_ent for a holding area
  LDA EntryPoints, x
  STA obj_ent_x
  LDA EntryPoints + 1, x
  STA obj_ent_y
  LDA EntryPoints + 2, x
  AND #%00000001
  STA obj_ent_dir

  TXA
  PHA

  LDX new_ent
  
  LDA obj_ent_x

  STA ent_blob + ENT_X, x
  LDA obj_ent_y
  STA ent_blob + ENT_Y, x
  LDA obj_ent_dir
  STA ent_blob + ENT_DIR, x
  PLA
  TAX
PAHSWRTooTired:
  JMP PANotDoge

PAHSWRLNotIt:
  TXA
  CLC
  ADC #$03
  TAX
  SEC
  CMP #$21 ;eleven entries times three bytes
  ;BMI PAHSpawnWoodRLoop
  BCC PAHSpawnWoodRLoop
  JMP PANotDoge

PAHSpawnWoodDn:
  LDX #$00
PAHSpawnWoodDnLoop:
  ;check entries for dir=$00
  LDA EntryPoints + 2, x
  CMP #$00
  BNE PAHSWDLNotIt
  ;then do a +/- x check and a 1-tile range "below doge" y check
  LDA cur_ent_x ;the entry point's x has a 0-byte offset
  SEC
  SBC EntryPoints, x
  BCC PAHSWDLXNeg ;these labels are getting ridiculous, hope i'm not running up against some length limit
  SEC
  CMP #$10
  ;BPL PAHSWDLNotIt
  BCS PAHSWDLNotIt
  JMP PAHSWDLYCheck
PAHSWDLXNeg:
  SEC
  CMP #$EF
  ;BMI PAHSWDLNotIt
  BCC PAHSWDLNotIt
  JMP PAHSWDLYCheck
PAHSWDLYCheck:
;the entry point's y should be greater or the difference should roll over
  LDA EntryPoints + 1, x
  SEC
  SBC cur_ent_y 
  SEC
  CMP #$20
  ;BPL PAHSWDLNotIt
  BCS PAHSWDLNotIt ;if it's more than 8 away, not it
  ;now we spawn wood
  ;sta check
  LDA ent_blob + ENT_STA
  BEQ PAHSWDTooTired
  LDA #ENT_TYPE_WOOD
  STA new_ent_type
  JSR SpawnEnt
  ;and copy x, y, and dir from the entry point. guess we can use obj_ent for a holding area
  LDA EntryPoints, x
  STA obj_ent_x
  LDA EntryPoints + 1, x
  STA obj_ent_y
  LDA EntryPoints + 2, x
  AND #%00000001
  STA obj_ent_dir

  TXA
  PHA
  LDX new_ent
  
  LDA obj_ent_x
  STA ent_blob + ENT_X, x
  LDA obj_ent_y
  STA ent_blob + ENT_Y, x
  LDA obj_ent_dir
  STA ent_blob + ENT_DIR, x
  PLA
  TAX
PASWDTooTired:
  JMP PANotDoge

PAHSWDLNotIt: ;always close the loop right here
  TXA
  CLC
  ADC #$03
  TAX
  SEC
  CMP #$21 ;eleven entries times three bytes
  ;BMI PAHSpawnWoodDnLoop
  BCC PAHSpawnWoodDnLoop

  JMP PANotDoge

PAHSpawnWoodL:
  LDX #$00
PAHSpawnWoodLLoop:
;check entries for dir=$01
  LDA EntryPoints + 2, x
  CMP #$01
  BNE PAHSWLLNotIt
;then check +/- y for within $10 of doge
  LDA EntryPoints + 1, x
  SEC
  SBC cur_ent_y
  BCC PAHSWLLYNeg
  SEC
  CMP #$10
  ;BPL PAHSWLLNotIt
  BCS PAHSWLLNotIt
  JMP PAHSWLLXCheck
PAHSWLLYNeg:
  SEC
  CMP #$EF
  ;BMI PAHSWLLNotIt
  BCC PAHSWLLNotIt
  JMP PAHSWLLXCheck
PAHSWLLXCheck:
;the doge's x should be higher than the entry point's and within $10
  LDA cur_ent_x
  SEC
  SBC EntryPoints, x
  SEC
  CMP #$10
  ;BPL PAHSWLLNotIt
  BCS PAHSWLLNotIt
;sta check
  LDA ent_blob + ENT_STA
  BEQ PAHSWLTooTired
;spawn wood here
  LDA #ENT_TYPE_WOOD
  STA new_ent_type
  JSR SpawnEnt
  DEC ent_blob + ENT_STA
  ;and copy x, y, and dir from the entry point. guess we can use obj_ent for a holding area
  LDA EntryPoints, x
  STA obj_ent_x
  LDA EntryPoints + 1, x
  STA obj_ent_y
  LDA EntryPoints + 2, x
  AND #%00000001
  STA obj_ent_dir

  TXA
  PHA
  LDX new_ent
  
  LDA obj_ent_x
  STA ent_blob + ENT_X, x
  LDA obj_ent_y
  STA ent_blob + ENT_Y, x
  LDA obj_ent_dir
  STA ent_blob + ENT_DIR, x
  PLA
  TAX
PAHSWLTooTired:
  JMP PANotDoge

PAHSWLLNotIt:
  TXA
  CLC
  ADC #$03
  TAX
  SEC
  CMP #$21 ;eleven entries times three bytes
  ;BMI PAHSpawnWoodLLoop
  BCC PAHSpawnWoodLLoop
;double check all the labels and variables in each of these
  JMP PANotDoge


PATorch: ;actually torch is handled in ZombieBrains
;torch should also damage wood though
;just treat it like the hammer only backwards in here
;dumping in copypasta MODIFIED AS OF NOW, BUT DOUBLE CHECK
;-----------------------------------------
  LDA cur_ent_dir
  CMP #$00
  BEQ PATUp
  CMP #$01
  BEQ PATRight
  CMP #$02
  BEQ PATDownBase
  CMP #$03
  BEQ PATLeftBase
  JMP PANotDoge ;should only happen if something gets corrupted, but handle it gracefully
PATDownBase: ;branch limit
  JMP PATDown
PATLeftBase:
  JMP PATLeft

PATUp:
;look for wood objects with x within 16px of doge and y less than, but no more than 8px less than doge
;first rule out everything that's not wood
  LDX #$00
PATUpBlobLoop:
  LDA ent_blob + ENT_TYPE, x
  CMP #ENT_TYPE_WOOD
  BNE PATUNotWood
  ;k, now do the position checks. x will be the big one for up and down, gotta check positive and negative difference
  ;just need to check a small range for y, try to order the sbc to make sure it's positive in each case
  LDA ent_blob + ENT_X, x
  SEC
  SBC cur_ent_x
  BCS PATUXNeg
  SEC
  CMP #$10
  ;BPL PATUNotWood ;go on to the next one if it's too far to the right
  BCS PATUNotWood
  JMP PATUYCheck ;just write the y-check once per dir to save some code space
PATUXNeg:
  SEC
  CMP #$EF
  ;BMI PATUNotWood ;go on to the next one if it's too far to the left
  BCC PATUNotWood
  JMP PATUYCheck
PATUYCheck:
  ;blob y should be less than doge y, and the difference should be less than or equal to 8
  ;may need to fine tune the range depending on how collisions behave. up to $10 or so would be acceptable
  LDA cur_ent_y
  SEC
  SBC ent_blob + ENT_Y, x
  SEC
  CMP #$08
  ;BPL PATUNotWood ;thanks to the rollover, a negative result (wood below doge) would look very high here
  BCS PATUNotWood
  ;so he's using the hammer with wood in a good position. fix that wood.
  LDA ent_blob + ENT_HP, x
  SEC
  SBC #$01 ;the amount to raise the wood's hp, tweak as needed
  STA ent_blob + ENT_HP, x

PATUNotWood:
  TXA
  CLC
  ADC #$10
  TAX
  BCC PATUpBlobLoop ;hope the carry flag survives the TAY. pretty sure it should
  
  JMP PANotDoge
PATRight:
  ;now just do the same thing three more times with the checks shuffled around, then the same for the torch w/ -hp
  LDX #$00
PATRBlobLoop:
  LDA ent_blob + ENT_TYPE, x
  CMP #ENT_TYPE_WOOD
  BNE PATRNotWood
  ;check y first. the difference should be within #$10
  LDA ent_blob + ENT_Y, x
  SEC
  SBC cur_ent_y
  BCS PATRYNeg
  SEC
  CMP #$10
  ;BPL PATRNotWood
  BCS PATRNotWood
  JMP PATRXCheck
PATRYNeg:
  SEC
  CMP #$EF
  ;BMI PATRNotWood
  BCC PATRNotWood
  JMP PATRXCheck
PATRXCheck:
  ;load x out of the blob for the subtraction so we always get a positive result if it's to the right
  LDA ent_blob + ENT_X, x
  SEC
  SBC cur_ent_x
  SEC
  CMP #$08
  ;BPL PATRNotWood
  BCS PATRNotWood
;if we're still here, we're hurting a wood
  LDA ent_blob + ENT_HP, x
  SEC
  SBC #$01
  STA ent_blob + ENT_HP, x


;looks right
PATRNotWood:
  TXA
  CLC
  ADC #$10
  TAX
  BCC PATRBlobLoop

  JMP PANotDoge
PATDown:
;same x check as for up, reverse the operands for the subtract in the y check
  LDX #$00
PATDBlobLoop:
  LDA ent_blob + ENT_TYPE, x
  CMP #ENT_TYPE_WOOD
  BNE PATDNotWood

  LDA ent_blob + ENT_X, x
  SEC
  SBC cur_ent_x
  BCS PATDXNeg
  SEC
  CMP #$10
  ;BPL PATDNotWood
  BCS PATDNotWood
  JMP PATDYCheck
PATDXNeg:
  SEC
  CMP #$EF
  ;BMI PATDNotWood
  BCC PATDNotWood
  JMP PATDYCheck
PATDYCheck:
;we want the blob y to be greater and within $08
  LDA ent_blob + ENT_Y, x
  SEC
  SBC cur_ent_y
  SEC
  CMP #$08
  ;BPL PATDNotWood
  BCS PATDNotWood
  LDA ent_blob + ENT_HP, x
  SEC
  SBC #$01
  STA ent_blob + ENT_HP, x

PATDNotWood:
  TXA
  CLC
  ADC #$10
  TAX
  BCC PATDBlobLoop

  JMP PANotDoge
PATLeft: ;one more. these are fairly straightforward, but laborious first thing in the morning.
;same y check as right, x check wants doge x greater than blob x
  LDX #$00
PATLBlobLoop:
  LDA ent_blob + ENT_TYPE, x
  CMP #ENT_TYPE_WOOD
  BNE PATLNotWood

  LDA ent_blob + ENT_Y, x
  SEC
  SBC cur_ent_y
  BCC PATLYNeg
  SEC
  CMP #$10
  ;BPL PATLNotWood
  BCS PATLNotWood
  JMP PATLXCheck

PATLYNeg:
  SEC
  CMP #$EF
  ;BMI PATLNotWood
  BCC PATLNotWood
  JMP PATLXCheck

PATLXCheck:
  ;we want doge x greater than blob x, within $08
  LDA cur_ent_x
  SEC
  SBC ent_blob + ENT_X, x
  SEC
  CMP #$08
  ;BPL PATLNotWood
  BCS PATLNotWood
  LDA ent_blob + ENT_HP, x
  SEC
  SBC #$01
  STA ent_blob + ENT_HP, x

PATLNotWood:
  TXA
  CLC
  ADC #$10
  TAX
  BCC PATLBlobLoop

  JMP PANotDoge
;----------------------------------------------------
;end copypasta

  JMP PANotDoge

PARifle:
;scan a probably infinite line ahead of doge based on his direction, 
;lower the hp of any zombies intersecting that line
;maybe progressively lower the delta for each zombie hit, so the ones behind it take less damage

;sta check
  LDA ent_blob + ENT_STA
  BEQ PARifleTooTired
;loop through the ent_blob and look for zombies

  LDX #$00
PARifleBlobLoop:
  LDA ent_blob + ENT_TYPE, x
  CMP #ENT_TYPE_ZOMBIE
  BNE PARifleBlobLoopEndBase
  ;now branch off depending on doge's direction
  LDA cur_ent_dir
  CMP #$00
  BEQ PARifleUp
  CMP #$01
  BEQ PARifleR
  CMP #$02
  BEQ PARifleDn
  ;CMP #$03
  ;BEQ PARifleL
  JMP PARifleL
PARifleUp:
;want a zombie with a y less than doge's, x within $10 i guess
  LDA cur_ent_y ;just load in doge's y and change the branch instruction for direction
  SEC
  CMP ent_blob + ENT_Y, x
  ;BPL PARifleBlobLoopEndBase ;if it should be BMI, zombies behind doge will die instead of in front
  BCC PARifleBlobLoopEndBase
  ;now do the x check
  LDA cur_ent_x
  SEC
;check positive and negative
  SBC ent_blob + ENT_X, x
  BCC PARUXNeg
  SEC
  CMP #$10
  ;BPL PARifleBlobLoopEndBase
  BCS PARifleBlobLoopEndBase
  JMP PARUHit
PARUXNeg:
  SEC
  CMP #$EF
  ;BMI PARifleBlobLoopEndBase
  BCC PARifleBlobLoopEndBase
  JMP PARUHit
PARifleBlobLoopEndBase: ;branch limit
  JMP PARifleBlobLoopEnd

PARUHit: ;could probably put this outside the direction branches to save space
  LDA ent_blob + ENT_HP, x
  SEC
  SBC #$01 ;set this to the rifle damage
  STA ent_blob + ENT_HP, x
  JMP PARifleBlobLoopEnd

PARifleR:
;zombie x greater than doge x, y within $10
  LDA cur_ent_x
  ;CMP [ptr_lo + ENT_X], y
  ;BMI PARifleBlobLoopEnd
  SEC
  CMP ent_blob + ENT_X, x
  BCS PARifleBlobLoopEndBase
  LDA cur_ent_y
  SEC
  SBC ent_blob + ENT_Y, x
  BCC PARRYNeg
  SEC
  CMP #$10
  ;BPL PARifleBlobLoopEnd
  BCS PARifleBlobLoopEnd
  JMP PARRHit
PARRYNeg:
  SEC
  CMP #$EF
  ;BMI PARifleBlobLoopEnd
  BCC PARifleBlobLoopEnd
  JMP PARRHit
PARRHit:
  LDA ent_blob + ENT_HP, x
  SEC
  SBC #$01
  STA ent_blob + ENT_HP, x
  JMP PARifleBlobLoopEnd

;PARifleBlobLoopEndBase:
;  JMP PARifleBlobLoopEnd

PARifleDn:
;zombie y greater than doge y, x within $10
  LDA cur_ent_y
  ;CMP [ptr_lo + ENT_Y], y
  ;BMI PARifleBlobLoopEnd
  SEC
  CMP ent_blob + ENT_Y, x
  BCC PARifleBlobLoopEnd
  LDA cur_ent_x
  SEC
  SBC ent_blob + ENT_X, x
  BCC PARDXNeg
  SEC
  CMP #$10
  ;BPL PARifleBlobLoopEnd
  BCS PARifleBlobLoopEnd
  JMP PARDHit
PARDXNeg:
  SEC
  CMP #$EF
  ;BMI PARifleBlobLoopEnd
  BCC PARifleBlobLoopEnd
  JMP PARDHit
PARDHit:
  LDA ent_blob + ENT_HP, x
  SEC
  SBC #$01
  STA ent_blob + ENT_HP, x
  JMP PARifleBlobLoopEnd

PARifleL:
;zombie x less than doge x, y within $10
  LDA cur_ent_x
  ;CMP [ptr_lo + ENT_X], y
  ;BPL PARifleBlobLoopEnd
  SEC
  CMP ent_blob + ENT_X, x
  BCS PARifleBlobLoopEnd
  LDA cur_ent_y
  SEC
  SBC ent_blob + ENT_Y, x
  BCC PARLYNeg
  SEC
  CMP #$10
  ;BPL PARifleBlobLoopEnd
  BCS PARifleBlobLoopEnd
  JMP PARLHit
PARLYNeg:
  CMP #$EF
  ;BMI PARifleBlobLoopEnd
  BCC PARifleBlobLoopEnd
  JMP PARLHit
PARLHit:
  LDA ent_blob + ENT_HP, x
  SEC
  SBC #$01
  STA ent_blob + ENT_HP, x
  JMP PARifleBlobLoopEnd

PARifleBlobLoopEnd:
  TXA
  CLC
  ADC #$10
  TAX
  BCS PANotDoge ;gotta do it this way for the branch limit

  JMP PARifleBlobLoop
PARifleTooTired:
PANotDoge:
  INC cur_ent
  LDA cur_ent
  SEC
  CMP #$11
  BEQ ProcessActionDone
  JMP ProcessActionBigLoop
ProcessActionDone:

  PLA
  TAX
  PLA
  TAY

  PLA
  PLP

  RTS

;should have a little over 6k of prgrom left at this point. try not to touch too much of it. 
;no more modules if possible. need some of that for sound
