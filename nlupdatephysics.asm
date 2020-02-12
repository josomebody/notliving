UpdatePhysics: ;[working on collisions between zhands and wood.]
;MAKE FOR DAMNED SURE ALL THE PUSHES AND PULLS ADD UP IF ANYTHING LOOKS OUT OF PLACE IN TEST
;STACK CORRUPTION IS A DISEASE
  PHP

  PHA ;[a0]
  TYA
  PHA ;[y0]
  TXA
  PHA ;[x0] [stack is 3 deep from here]

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
  PHA ;[stack is 9 deep from here]

;this should probably be called in NMI for timing purposes or used with some kind of clocking flag
;may actually do the math and see how many cycles this whole thing takes worst-case
;loop over ent_blob and update coordinates based on forces, check for collisions and clipping and act accordingly
;might even move force updates into here from ProcessInput or wherever they are for a nice glide

;first things first, get the master offset into ptr_lo/hi, and use y for ent selection
;looks like we could get away with indirect x addressing here, might be easier

  LDX #$00 ;pretty sure x will keep track of what ent we're on in the blob
UpdatePhysicsLoop:
  ;basically load in all the forces, add them to the coordinates, add $10 to y for the next guy, and loop
  ;first of all check type for DNE and skip over it if so
  LDA ent_blob + ENT_TYPE, x
  CMP #ENT_TYPE_DNE ;more should-be-literal garbage to look at. this module needs some work.
  BEQ NoPhysicsUpdateBase
  JMP NPUBSkip ;really ugly for the branch limit

NoPhysicsUpdateBase:
  JMP NoPhysicsUpdate
NPUBSkip: 
  LDA ent_blob + ENT_XFORCE, x
  CLC
  ADC ent_blob + ENT_X, x
  STA ent_blob + ENT_X, x

  LDA ent_blob + ENT_YFORCE, x
  CLC
  ADC ent_blob + ENT_Y, x
  STA ent_blob + ENT_Y, x ;when we're totally done with the forces, zero them out, but we still need them to 
                          ;back out of a collision right now

;oh yeah, gotta check collisions and clipping and subtract all the forces if anything returns. may be too big for NMI

;guess do clipping first, doesn't really matter
;ClipCheck runs against obj_ent, so load the indexed object into there. y should still have the right offset
;pretty sure every ent clips, so don't bother with type checking. check the rules for collisions
;the following code is experimental and replaces the commented-out code below it

  LDA ent_blob + ENT_X, x
  STA obj_ent_x
  LDA ent_blob + ENT_Y, x
  STA obj_ent_y
;think all we need is x and y
  JSR ClipCheck
  LDA clip_flag; set back to clip_flag when done testing here.
;remember clip_flag needs to be exactly $01 for real clipping. the other values are for furniture, etc.
  CMP #$01
  BNE PhysicsNoClip
;got clipping, so subtract the forces back
  LDA ent_blob + ENT_X, x
  SEC
  SBC ent_blob + ENT_XFORCE, x
  STA ent_blob + ENT_X, x

  LDA ent_blob + ENT_Y, x
  SEC
  SBC ent_blob + ENT_YFORCE, x
  STA ent_blob + ENT_Y, x 

PhysicsNoClip: 
;think we can safely zero out forces here. causing problems trying to do it later
  LDA #$00
  STA ent_blob + ENT_XFORCE, x
  STA ent_blob + ENT_YFORCE, x

  ;now go through and check every possible collision the rules allow
  ;first check the object we're working on and make a branch list for each ruleset
;load what we're looking at into cur_ent, 
;set cur_ent, which is in ones
;attempting to continue using indirect x-addressing
  TXA
  LSR A
  LSR A
  LSR A
  LSR A ;if this is closed with a LDA cur_ent/TAX, it should be followed by four ASLs. don't think it is though.
  STA cur_ent
  JSR LoadEnt
  LDA cur_ent_type
  CMP #ENT_TYPE_DOGE
  BEQ ColDoge
  CMP #ENT_TYPE_ZOMBIE
  BEQ ColZombieBase
  CMP #ENT_TYPE_HAMMER 
  BEQ ColHammerBase
  CMP #ENT_TYPE_TORCH
  BEQ ColTorchBase
  CMP #ENT_TYPE_RIFLE
  BEQ ColRifleBase
  CMP #ENT_TYPE_BANDAID
  BEQ ColBandaidBase
  CMP #ENT_TYPE_WOOD
  BEQ ColWoodBase
  CMP #ENT_TYPE_ZHANDS
  BEQ ColZhandsBase
  CMP #ENT_TYPE_WOOD_PU
  BEQ ColWoodPuBase
  CMP #ENT_TYPE_CLOTH_PU
  BEQ ColClothPuBase
  CMP #ENT_TYPE_AMMO_PU
  BEQ ColAmmoPuBase
;think the only default would be DNE or a data error, guess skip it for now
;leaving a space in case we do end up needing to jump over the following later
ColZombieBase:
  JMP ColZombie
ColHammerBase:
  JMP ColHammer
ColTorchBase:
  JMP ColTorch
ColRifleBase:
  JMP ColRifle
ColBandaidBase:
  JMP ColBandaid
ColWoodBase:
  JMP ColWood
ColZhandsBase:
  JMP ColZhands
ColWoodPuBase:
  JMP ColWoodPu
ColClothPuBase:
  JMP ColClothPu
ColAmmoPuBase:
  JMP ColAmmoPu ;so what's gonna happen if these jump tables get too long for the branch limit?

ColDoge:
;need further branch lists for the object rules, depending on type

;gonna need y to loop through the blob, should probably push it. 
;don't forget to pull it back out or the whole program will wreck
  TXA ;continuing with attempted indirect x-addressing
  PHA ;[x1] trace the actual branching and jumps for the complementing pull
;use ptr_temp just to be safe
;check the state of pretty much everything before deciding what to do here, but it looks safe to just continue reading out of the blob
;with x at a new stack level

;loop through the blob and do type-checking
  LDX #$00
ClipDogeBlobLoop:

;need to load the type and branch based on that
;re-implemented with indirect x-addressing in the following line
  LDA ent_blob + ENT_TYPE, x
;things happen if doge collides with zombies and pickups. tools are checked in input processing
  CMP #ENT_TYPE_ZOMBIE
  BEQ ClipDogeZombie ;SAFE make sure none of these branches have pulls, or if they do all of them should
  CMP #ENT_TYPE_BANDAID
  BEQ ClipDogeBandaid ; SAFE x is the last thing on the stack right now btw
  CMP #ENT_TYPE_WOOD_PU
  ;disabled for testing> BEQ ClipDogeWoodPu ; SAFE check them off if necessary
  CMP #ENT_TYPE_CLOTH_PU
  BEQ ClipDogeClothPu ; SAFE just really make sure
  CMP #ENT_TYPE_AMMO_PU
  BEQ ClipDogeAmmoPu ; SAFE stack corruption is a game breaking disease
;plenty of defaults to fall through on this, so jump out
  ;JMP ClipDogeDone ;the x1 pull is here
  JMP ClipDogeBlobLoopEnd ;make sure this doesn't clobber the stack, but it's not iterating the other way

;keep these innermost blocks short and sweet. really burning cycles now
ClipDogeZombie:

;need to load the index into obj_ent to do the actual collision check. 
;might actually speed things up doing it in the inner loop since it'll get skipped a lot that way
  TXA
  STA obj_ent ;obj_ent is a direct offset, in $10s.
;may or may not wanna knock him back. will decide later. probably just do some mercy invincibility for now
  JSR EntCollision ;will return a $01 on ent_collision in the event of a collision
  LDA ent_collision
  BEQ ClipDogeBlobLoopEndBase ;skip down to the next ent in the blob. man this is gonna be a huge block
;add in a check for mercy invincibility here later
  DEC cur_ent_hp ;don't forget to store cur_ent back in the blob on the way out
  LDA cur_ent_hp
  BNE ClipDogeBlobLoopEndBase
  LDA #$02
  STA game_state
ClipDogeBlobLoopEndBase:
  JMP ClipDogeBlobLoopEnd ;this label starts with an x1 stack level. it leads back to ClipDogeDone, so safe.

ClipDogeBandaid:
  TXA
  STA obj_ent
  JSR EntCollision
  LDA ent_collision
  BEQ ClipDogeBlobLoopEnd
  LDA cur_ent_hp ;what's a bandaid add? bout 5?
  CLC
  ADC #$05
  STA cur_ent_hp
  JMP ClipDogeBlobLoopEnd

ClipDogeWoodPu:
;don't forget to actually check for the collision, every single case down this way
  TXA
  STA obj_ent
  JSR EntCollision
  LDA ent_collision
  BEQ ClipDogeBlobLoopEnd ;SAFE
;will increase doge's stamina if he's holding the hammer and just get wasted otherwise
  LDA cur_ent_tool
  CMP #TOOL_HAMMER
  BNE ClipDogeWoodPuNoHammer ;SAFE
;let's be nice and give him like ten more boards for now. may revoke if too easy
  LDA cur_ent_sta
  CLC
  ADC #$0A
  STA cur_ent_sta
ClipDogeWoodPuNoHammer: ;either way it disappears
  LDA #ENT_TYPE_DNE
;the following line is experimental
  STA ent_blob + ENT_TYPE, x ;man that felt good
  JMP ClipDogeBlobLoopEnd ;SAFE

ClipDogeClothPu:
  TXA
  STA obj_ent
  JSR EntCollision
  LDA ent_collision
  BEQ ClipDogeBlobLoopEnd ;SAFE
;active if doge is holding the torch, same as the hammer
  LDA cur_ent_tool
  CMP #TOOL_TORCH
  BNE ClipDogeClothPuNoTorch ;SAFE
  LDA cur_ent_sta
  CLC
  ADC #$0A
  STA cur_ent_sta
ClipDogeClothPuNoTorch: ;SAFE
  LDA #ENT_TYPE_DNE
  STA ent_blob + ENT_TYPE, x
  JMP ClipDogeBlobLoopEnd ;SAFE

ClipDogeAmmoPu:
  TXA
  STA obj_ent
  JSR EntCollision
  LDA ent_collision
  BEQ ClipDogeBlobLoopEnd ;SAFE
;same deal with the rifle
  LDA cur_ent_tool
  CMP #TOOL_RIFLE
  BNE ClipDogeAmmoNoRifle ;SAFE
  LDA cur_ent_sta
  CLC
  ADC #$0A
  STA cur_ent_sta
ClipDogeAmmoNoRifle: ;SAFE
  LDA #ENT_TYPE_DNE
  STA ent_blob + ENT_TYPE, x
  JMP ClipDogeBlobLoopEnd ;SAFE

ClipDogeBlobLoopEnd:
;think we just update x to the next ent and loop back up
  TXA
  CLC
  ADC #$10
  TAX
  BCS ClipDogeDone
  JMP ClipDogeBlobLoop
;and now probably get out of these fallthrough checks
;oop, don't forget to pop y
ClipDogeDone:
  PLA ;[/x1]
  TAX ;attempted indirect x-addressing
  JMP NoPhysicsUpdate
  
ColZombie:
;don't actually seem to need this. 
;may have them turn around when they bump into each other/doge if speed permits later
  JMP NoPhysicsUpdate

;[all the tool scoots are disabled right now til the collision logic is figured out right]
ColHammer:
;the hammer (and all the tools) should check for other tools and just bounce off. 
;a tile's width of separation is fine

;gonna need y to loop through the blob, should probably push it. 
;don't forget to pull it back out or the whole program will wreck
;using experimental indirect x-addressing in the following line
  TXA
  PHA ;[x1] might need to number these pushes and pulls to make sure they line up
;loop through the blob and do type-checking
  LDX #$00
ClipHammerBlobLoop:
;need further branch lists for the object rules, depending on type, 
;just check for tools, direct them all to the same code
;the following lines using indirect x-addressing replace the commented-out lines below them
  LDA ent_blob + ENT_TYPE, x
  CMP #ENT_TYPE_HAMMER
  BEQ ClipHammerTool ;SAFE these branches start at stack level x1
  CMP #ENT_TYPE_TORCH
  BEQ ClipHammerTool ;SAFE check they all lead back to a pull, hopefully the same one
  CMP #ENT_TYPE_TORCH
  BEQ ClipHammerTool ;SAFE stack corruption is a disease
;and skip everything else
  JMP ClipHammerBlobLoopEnd ;SAFE ideally the pull should be under this label
ClipHammerTool: ;SAFE
;load the current slot into obj_ent for collision check
  TXA
  STA obj_ent
  JSR EntCollision
  LDA ent_collision
  BEQ ClipHammerBlobLoopEnd ;SAFE
;if there's a hit, just scoot over a tile
  LDA cur_ent_x
  CLC
  ADC #$08
;  STA cur_ent_x
  LDA cur_ent_y
  CLC
  ADC #$08
;  STA cur_ent_y ;may need to clean this up to check for map clipping and all that if it doesn't sort itself out  
;falls through to the pull, so SAFE
ClipHammerBlobLoopEnd: ;SAFE
  TXA
  CLC
  ADC #$10
  TAX
  BCC ClipHammerBlobLoop ;SAFE if this label is after the push, we can mark it safe

  PLA ;[/x1]
  TAX
  JMP NoPhysicsUpdate

ColTorch:
;need further branch lists for the object rules, depending on type

;gonna need y to loop through the blob, should probably push it. 
;don't forget to pull it back out or the whole program will wreck
  TXA
  PHA ;[x1]
;use ptr_temp just to be safe
;and so-on with indirect-x addressing
;loop through the blob and do type-checking
  LDX #$00
ClipTorchBlobLoop:
  LDA ent_blob + ENT_TYPE, x
  CMP #ENT_TYPE_HAMMER
  BEQ ClipTorchTool ; SAFE seeing a pattern that these branches tend to be remarkably safe
  CMP #ENT_TYPE_TORCH
  BEQ ClipTorchTool ; SAFE need to check them all anyway though. this is a really fragile thing
  CMP #ENT_TYPE_RIFLE
  BEQ ClipTorchTool ; SAFE no recovering from stack corruption
  JMP ClipTorchBlobLoopEnd
ClipTorchTool:
  TXA
  STA obj_ent
  JSR EntCollision
  LDA ent_collision
  BEQ ClipTorchBlobLoopEnd ;SAFE

  LDA cur_ent_x
  CLC
  ADC #$08
;  STA cur_ent_x
  LDA cur_ent_y
  CLC
  ADC #$08
;  STA cur_ent_y ;falls through, therefore SAFE

ClipTorchBlobLoopEnd: ;SAFE
  TXA
  CLC
  ADC #$10
  TAX
  BCC ClipTorchBlobLoop ;SAFE

  PLA ;[/x1]
  TAX ;check where this pull answers from. just below ColTorch
  JMP NoPhysicsUpdate

ColRifle:
;need further branch lists for the object rules, depending on type

;gonna need y to loop through the blob, should probably push it. 
;don't forget to pull it back out or the whole program will wreck
  TXA
  PHA ;[x1]
;use ptr_temp just to be safe
;loop through the blob and do type-checking
  LDX #$00
ClipRifleBlobLoop:
  LDA ent_blob + ENT_TYPE, x
  CMP #ENT_TYPE_HAMMER
  BEQ ClipRifleTool ;this is the price you pay for speed
  CMP #ENT_TYPE_TORCH
  BEQ ClipRifleTool ;very anti-unix, but what can you do
  CMP #ENT_TYPE_RIFLE
  BEQ ClipRifleTool ;1MHz to get stuff done in 1/60 of a second, one very bored developer
  JMP ClipRifleBlobLoopEnd ;i love manual stack tracing
ClipRifleTool:
  TXA
  STA obj_ent
  JSR EntCollision
  LDA ent_collision
  BEQ ClipRifleBlobLoopEnd ;SAFE this module's a little scatterbrained, but not quite the monster of SortSprites
  LDA cur_ent_x
  CLC
  ADC #$08
;  STA cur_ent_x
  LDA cur_ent_y
  CLC
  ADC #$08
;  STA cur_ent_y ;falls through, therefore SAFE nor the snipe hunt for the missing/extra byte that was LoadEnt
ClipRifleBlobLoopEnd:
  TXA
  ADC #$10
  TAX
  BCC ClipRifleBlobLoop ;SAFE lot of extraneous documentation though

  PLA ;[/x1]
  TAX
  JMP NoPhysicsUpdate

ColBandaid:
;yeah actually unless it's gonna physically interact with anything, we don't need to worry about pickups.
;doge checks them, and they already to ClipCheck up there. otherwise just let them pile up on each other
  JMP NoPhysicsUpdate

ColWood:
;wood should check for zhands and periodically loose hp, guess check the clock for it somehow
;need further branch lists for the object rules, depending on type

;gonna need y to loop through the blob, should probably push it. 
;don't forget to pull it back out or the whole program will wreck
  TXA
  PHA ;[x1]

;loop through the blob and do type-checking
  LDX #$00
ClipWoodBlobLoop:
  LDA ent_blob + ENT_TYPE, x
  CMP #ENT_TYPE_ZHANDS
  BNE ClipWoodBlobLoopEnd ;SAFE this set looks a little different, better be sharp about it
  ;JMP ClipWoodZhands ;think this is just a fall-through that i forgot to label before rearranging

;found a zhands, check for a collision

  TXA
  STA obj_ent
  JSR EntCollision ;check EntCollision for register safety
  LDA ent_collision
  BEQ ClipWoodBlobLoopEnd ;SAFE
  ;hm, or cycle down the wood's stamina and lose hp every time it's zero
  DEC cur_ent_sta
  BNE ClipWoodZhandsAllGood ;SAFE check these again if any code ends up between this label and ClipWoodBlobLoopEnd
  DEC cur_ent_hp
  LDA cur_ent_hp
  BNE ClipWoodZhandsAllGood ;SAFE and this one^^
  LDA #ENT_TYPE_DNE
  STA cur_ent_type

ClipWoodZhandsAllGood: ;SAFE
ClipWoodBlobLoopEnd: ;SAFE
  TXA
  ADC #$10
  TAX
  BCC ClipWoodBlobLoop ;SAFE

  PLA ;[/x1]
  TAX
  JMP NoPhysicsUpdate

ColZhands:
;zhands should check for wood and spawn a zombie if no collision
;need further branch lists for the object rules, depending on type


;gonna need y to loop through the blob, should probably push it. 
;don't forget to pull it back out or the whole program will wreck
  TXA
  PHA ;[x1] god how many of these are there? least they're not nested. i hope they're not nested.
;loop through the blob and do type-checking
  LDX #$00
ClipZhandsBlobLoop:
  LDA ent_blob + ENT_TYPE, x
  CMP #ENT_TYPE_WOOD
  BNE ClipZhandsBlobLoopDone
  TXA ;ok, think this loop is non-terminating. see(1)
  STA obj_ent
  JSR EntCollision
  LDA ent_collision
  BNE ClipZhandsCollision ;we're checking for a collision-free zone here, so just get out once we find one
			  ;ClibZhandsCollision exits stack level x2. this branch instruction is at stack level x1
ClipZhandsBlobLoopDone:
  TXA
  CLC
  ADC #$10
  TAX ;(1) this was missing earlier and seems to be necessary to iterate the loop
  BCC ClipZhandsBlobLoop
;this seems to be where the x1 pulls should go, flattening that nesting out

  PLA ;[/x1]
  TAX ;take it back out and put it down toward ClipZhandsCollision if bad blob reads happen after this

;if we get through the whole blob without jumping down to ClipZhandsCollision, then things happen
;spawn a zombie and give it this zhands's x, y, and dir, then kill the zhands
  LDA #ENT_TYPE_ZOMBIE
  STA new_ent_type
  JSR SpawnEnt ;double-check SpawnEnt for x-register safety, but pretty sure it's good
;think we're done with ptr_temp, still hopefully pointing at the base of the blob
;probably need a new stack level to restructure this for indirect x-addressing [NOT DONE YET]
;push x to stay safe, make sure to pull it back after
  TXA
  PHA ;[x1] <strike>shit, now they're nested. </strike>this level has been verified. 
;make sure we don't need old x in here anywhere

  LDX new_ent ;index to the new zombie in the blob (in tens)


;x should point to the zombie's slot in ent_blob with the new change.
  LDA cur_ent_x
  STA ent_blob + ENT_X, x
  LDA cur_ent_y
  STA ent_blob + ENT_Y, x
  LDA cur_ent_dir
  STA ent_blob + ENT_DIR, x
;need to destroy the zhands after it's replaced
  PHA
  LDA #ENT_TYPE_DNE
  STA cur_ent_type
  JSR SaveEnt
  PLA
;then scoot it into the house based on its dir
;still got dir in a, just check from here
  CMP #$00
  BEQ NewZombieScootUp ;SAFE
  CMP #$01
  BEQ NewZombieScootRight ;SAFE
  CMP #$02
  BEQ NewZombieScootDown ;SAFE
  CMP #$03
  BEQ NewZombieScootLeft ;SAFE
  JMP ClipZhandsCollision; SAFE just to be safe
NewZombieScootUp:
  LDA ent_blob + ENT_Y, x
  SEC
  SBC #$20; probably go four tiles just to make sure it's inside
  STA ent_blob + ENT_Y, x
;and don't forget to get out
  JMP ClipZhandsCollision ;SAFE

NewZombieScootRight:
  LDA ent_blob + ENT_X, x
  CLC
  ADC #$20
  STA ent_blob + ENT_X, x
  JMP ClipZhandsCollision ;SAFE

NewZombieScootDown:
  LDA ent_blob + ENT_Y, x
  CLC
  ADC #$20
  STA ent_blob + ENT_Y, x
  JMP ClipZhandsCollision ;SAFE

NewZombieScootLeft:
  LDA ent_blob + ENT_X, x
  SEC
  SBC #$20
  STA ent_blob + ENT_X, x
  JMP ClipZhandsCollision ;SAFE

ClipZhandsCollision:
  PLA ;[/x1] verify the internal of this stack level first
;figure out where this pull answers from. looks like a good place for the NewZombie pull of x
  TAX ;we're back at stack level x0
  JMP NoPhysicsUpdate

ColWoodPu:
;probably need to just take these pickup checks out, really just gonna slow things down

  JMP NoPhysicsUpdate

ColClothPu:

  JMP NoPhysicsUpdate

ColAmmoPu:

  JMP NoPhysicsUpdate

;think that's it, but may have to do some comparisons against max values. don't think any of that is implemented yet.
;probably need either a universal speed limit, adding like two instructions here, or a max speed per type,
;which will require type-check branching and be a little bigger

NoPhysicsUpdate:
;save cur_ent back. hopefully this is the best place to do it 
;[looks like we're dealing with the blob directly, so try not saving just in case]
  JSR SaveEnt ;SaveEnt is definitely good.
;get out of the loop when done
;if there's stack corruption anywhere, pull x here. the pull is here for testing purposes
;---begin testing
;  PLA ;right now any further pulls would get into pointer safety from the top of the subroutine.
;  TAX
;---end testing
;what is x right here? should be the ent we're updating physics for. make sure.
;think we zero out forces here. or not.
  ;LDA #$00                
  ;STA ent_blob + ENT_XFORCE, x
  ;STA ent_blob + ENT_YFORCE, x 
;let's hope so.
  TXA ;can skip the juggling (at the cost of a little readability, gaining a couple of cycles, esr would frown)
  CLC ;if the testing code leaves the stack clean^
  ADC #$10
  BCS UpdatePhysicsDone
  TAX 
  JMP UpdatePhysicsLoop

UpdatePhysicsDone:

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
  PLA ;[stack looks 3 deep to me. think everything added back up]
  STA ptr_lo

  PLA ;[x0]
  TAX
  PLA
  TAY  
  PLA

  PLP

  RTS

