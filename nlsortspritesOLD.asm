SortSprites:
  PHP
  PHA

  TYA ;[0]
  PHA
;pointer safety
  LDA ptr_lo
  PHA
  LDA ptr_hi
  PHA
  LDA ptr_temp_lo
  PHA
  LDA ptr_temp_hi
  PHA

;sorts sprites by z-priority and puts them into flicker groups, returns a list for LoadSprites
;really burning some cycles in NMI now, should figure out a very lean way to do it
;going at it blind, first idea is to divide the sprites into 2-4 groups and use a 1-2-bit flag to determine
;which group gets definitely shown every frame, and roll that flag at the end of the dump
;guess sort them all by x-coordinate and loop through that list, assigning every 4-8 to a new group
;best looking option from there is probably show one from each group in the event of a scanline overload
;seems like a lot of work to add to one game/frame cycle though
;don't really know how everybody else does it
;probably need an initial buffer to hold coordinates and screen priority of the x-sorted ent list
;then pull them out in flicker group order, checking against everything else's y-coordinate,
;then re-sort them by screen priority and dumping that to the real buffer
;that's a lot of ram and a lot of probably selection sort
;almost wanna do it in C
;definitely shouldn't do it inside some inner loop
;need to creatively reuse ent_type for z-priority, make a map structure if necessary, or just a bunch of branches

;k, let's spec this out. the final list probably just needs blob indices of the sprites to show this frame
;define at last one, maybe two, buffers in nlvariables.asm
;those buffers will need to hold enough info to sort, so definitely x and type, y on the way out to keep track of
;who's sharing scanlines
;so first of all, sort by x into flicker groups, like
;x-lo                            x-hi
;[0 1 2 3][0 1 2 3][0 1 2 3][0 1 2 3]
;and the flicker count will determine which element of each group definitely gets shown
;so go through and add e.g. all the 0s when the flicker count is 0
;that will guarantee at least four sprites are shown if four or more exist, and they'll be
;evenly distributed across the screen.
;then add the rest on condition of y-checking, like for each one go through the already-made list,
;check that abs(me.y-thisguy.y) > 8 and only add me to the list if so
;the result is a usually smaller list guaranteed not to overload the sprite limit
;sort that list by z-priority and send it to loadsprites
;this being assembly language, also need to pad the lists out with some kind of null so we know when to quit
;and man these sorts are gonna be very messy and ad hoc.

;the list buffers have a fixed capacity of 16 bytes. need to fill them all with $FFs so there's some known padding
;for an exit condition
  LDA #LOW(sprites_that_exist)
  STA ptr_lo
  LDA #HIGH(sprites_that_exist)
  STA ptr_hi
  LDY #$0F
SpritesThatExistPaddingLoop:
  LDA #$FF
  STA [ptr_lo], y
  DEY
  CPY #$FF
  BNE SpritesThatExistPaddingLoop

  LDA #LOW(flicker_groups)
  STA ptr_lo
  LDA #HIGH(flicker_groups)
  STA ptr_hi
  LDY #$0F
FlickerGroupsPaddingLoop:
  LDA #$FF
  STA [ptr_lo], y
  DEY
  CPY #$FF
  BNE FlickerGroupsPaddingLoop

  LDA #LOW(sorted_sprites)
  STA ptr_lo
  LDA #HIGH(sorted_sprites)
  STA ptr_hi
  LDY #$0F
SortedSpritesPaddingLoop:
  LDA #$FF
  STA [ptr_lo], y
  DEY
  CPY #$FF
  BNE SortedSpritesPaddingLoop

;alright, enough idle chit-chat. dig through the blob and add the indices not pointing to DNEs in sprites_that_exist
;use ptr_temp to index the lists
;need to really modularize this and keep it clear
FillSpritesThatExist:
;the old code mostly worked, but was kinda buggy and bulky and hard to improve. gonna try to do it a better way
  TXA
  PHA
  LDA #$00
  STA list_index

;  TYA
;  PHA
;easy enough, just go through the blob, check if each ent has a type other than DNE, add it to the list
;  LDY #ENT_TYPE
;  LDA #LOW(ent_blob)
;  STA ptr_lo
;  LDA #HIGH(ent_blob)
;  STA ptr_hi
;  LDA #$00
;  STA list_index ;list index points to sprites_that_exist. 
                 ;to traverse it, only increment this and temporarily make y=0.
FillSpritesThatExistLoop:
  LDA ent_blob + ENT_TYPE, x
  CMP #ENT_TYPE_DNE
  BEQ FillSpritesThatExistDNE
  LDA #LOW(sprites_that_exist)
  STA ptr_temp_lo
  LDA #HIGH(sprites_that_exist)
  STA ptr_temp_hi
  LDY list_index
  TXA
  STA [ptr_lo], y
  INC list_index
;  LDA [ptr_lo], y
;  CMP #ENT_TYPE_DNE
;  BEQ FillSpritesThatExistDNE
  ;got handy dandy list index variables. just keep them up to date and add them to the pointers to the right lists
  ;reset ptr_temp to the base of sprites_that_exist so it will always increment by one instead of going nuts
;  LDA #LOW(sprites_that_exist)
;  STA ptr_temp_lo
;  LDA #HIGH(sprites_that_exist)
;  STA ptr_temp_hi
  ;then add in list_index and we should be in the right place every time through
;  LDA list_index
;  CLC
;  ADC ptr_temp_lo
;  STA ptr_temp_lo
;  LDA #$00
;  ADC ptr_temp_hi
;  STA ptr_temp_hi
;  TYA ;now store the offset from ent_blob of the guy we found in sprites_that_exist (ptr_temp)
  ;need y=0 for addressing. only a tiny amount of juggling, just straighten it out fast
;  LDY #$00
;  SEC
;  SBC #ENT_TYPE ;need to always subtract ENT_TYPE for a clean offset for the lists, then add it back after the store
;  STA [ptr_temp_lo], y ;old y value is still in a
;  CLC
;  ADC #ENT_TYPE
  ;and one entry down
FillSpritesThatExistDNE:
  TXA
  CLC
  ADC #$10
  TAX
  BCC FillSpritesThatExistLoop

  PLA
  TAX
;jump y ahead to the next blob entry
;  CLC ;[a seems to always be zero right here, gotta fix that]
;  ADC #$10 ;old y value is still in a
;  TAY ;new value is now in y
;gotta update list index
;  INC list_index 
;  BCC FillSpritesThatExistLoop ;relying on TAY and INC not affecting the carry flag, 
                               ;but can work around if it turns out they do
;  PLA
;  TAY


FillFlickerGroups:
  TYA
  PHA
;now a little trickier, loop through sprites_that_exist, find the one with the lowest x value,
;append it to ficker_groups, replace it with $FE in sprites_that_exist so it doesn't get entered more than once

;one step at a time, set the pointers and empty flag up
;sprites_that_exist will be ptr_lo/hi
  LDA #LOW(sprites_that_exist)
  STA ptr_lo
  LDA #HIGH(sprites_that_exist)
  STA ptr_hi
;flicker_groups will be ptr_temp_lo/hi
  LDA #LOW(flicker_groups)
  STA ptr_temp_lo
  LDA #HIGH(flicker_groups)
  STA ptr_temp_hi
;still need to read out of the blob. it'll be in ctr_lo/hi
  LDA #LOW(ent_blob)
  STA ctr_lo
  LDA #HIGH(ent_blob)
  STA ctr_hi

;probably push y [1]
;so we need an outer loop to iterate all the way through sprites_that_exist until it's empty
;may need an empty flag to tell when it's empty
IterateSpritesThatExistLoop:
;set list_empty_flag to 1 and assume the list is empty until an entry is found, in which case set it to zero
  LDA #$01
  STA list_empty_flag

;probably push y [2]
  TYA ;[2]
  PHA
;then an inner loop to always find the lowest x value
;first, set tmp to the x value of the first entry, (bad idea, stops working after the first entry's blanked out)
;first, set tmp to #$FF so we can keep comparing down from there

;really keep track of y with nested pushes
  TYA ;[4]
  PHA

;  LDY #$00
;  LDA [ptr_lo], y ;blob index of the first entry is in a
;  TAY ;now it's in y
;  LDY #ENT_X
;  LDA [ctr_lo], y ;now the x value we need is in a
;  STA tmp ;and now it's in tmp where we need it
  LDA #$FF ;pretty sure this will work better than just loading the first entry
  STA tmp  ;these two lines are experimental<^
;looks good right now though, on to the next sort debugging

  PLA
  TAY ;[4]

;then for each entry, if it's x is less than tmp, it's the new tmp
;already have the first entry, use y with nested pushes to keep track of where we are in sprites_that_exist

FindLowestXLoop:
  INY
  LDA [ptr_lo], y ;next blob index is in a
  SEC
  CMP #$FD ;but is it an empty entry or padding
  BCS LowestXLoopEmptyEntry ;the N flag does not behave predictably here, use the carry flag to check <>
  STA list_index ;and now in list_index
;don't forget to unset list_empty_flag
  LDA #$00
  STA list_empty_flag

  TYA ;[5]
  PHA ;y is safe
  
  LDY list_index
  LDA [ctr_lo], y ;x value for checking is in a (ENT_X==$00, so this is cleaned up)
  SEC
  CMP tmp ;is it smaller than tmp?
  BCS NotLowestX
  STA tmp ;if so, store it in tmp
NotLowestX:  

  PLA
  TAY ;[5]

LowestXLoopEmptyEntry:
;FindLowestXLoop will iterate until we hit $FF padding, and loop before the core to search the whole
;sprites_that_exist so we have the right one to transfer
  CMP #$FF
  BNE FindLowestXLoop

;ok, gone all the way through sprites_that_exist, and the lowest x value should be in tmp
;maybe push y [3]
  TYA ;[3]
  PHA

;then a core with the actual transfer
;now go through it again and grab the first entry with that x value, append that index to flicker_groups,
;and replace it with an $FE skip value
  LDY #$00
LowestXGrabLoop: 
  LDA [ptr_lo], y ;next blob index is in a, sprites_that_exist is in ptr_lo/hi
  SEC
  CMP #$FD
  BCS LowestXGrabEmptyEntry
  STA list_index
  ;gonna need to remember the index of sprites_that_exist later to blank it out
  STY list_index3 ;so put it here, and remember to do something with it when the time comes

;had a push here, but it wasn't working with the jump out at success. hope we didn't need it. [x]

  LDY list_index
  LDA [ctr_lo], y ;grabbing the x value out of the blob
  CMP tmp ;is it the one stored in tmp as lowest
  BNE LowestXGrabNotIt ;if not, keep looking
  ;the blob index (+ ENT_X) we want to put into flicker_groups is in y handily
  ;now what we need to do is append it, so we should keep a running index in list_index2
  ;also probably need to put it somewhere for now because of all the shuffling transfer
  TYA
  SEC
  SBC #ENT_X ;pretty sure ENT_X=0 though, so trim this back out if we need space
  STA tmp2
  CLC
  ADC #ENT_X
  ;gonna use y for addressing, so nested push, even if it looks redundant
  TYA ;[6]
  PHA

  LDA list_index2
  TAY
  LDA tmp2
  STA [ptr_temp_lo], y ;this is flicker_groups
  INC list_index2 ;so we have the position for the next append
;and blank it out in sprites_that_exist
  LDY list_index3 ;guess this is how we're getting an offset from sprites_that_exist. make sure it updates at the end
  LDA #$FE
  STA [ptr_lo], y  

  PLA
  TAY ;[6]

  JMP FoundLowestX ;the end condition here is when we find one, so probably just need to jump out
                   ;tricky part is making sure to keep the stack straight
                   ;little bit of spaghetti showing up in the seams
LowestXGrabNotIt:
  
;and that complementing pull was here [x]

LowestXGrabEmptyEntry:
;end LowestXGrabLoop
;think this is where list_index3 should be updated to the next entry in sprites_that_exist
  INC list_index3
;double check we're not at the end of the list
  LDA list_index3
  SEC
  CMP #$10 ;$10 is one byte past the end of the list. if we're here we need to get out, but also keep the stack clean
  BEQ FoundLowestX ;best looking spot inside the current stack nesting rn. 
;and we need it in y too
  LDY list_index3

  JMP LowestXGrabLoop
FoundLowestX:

;maybe pull y [3]
  PLA
  TAY ;[3]

;next thing to do is find the next lowest x i think

;finish the inner loop
  ;INY ;think the end condition here is the first entry returning an $FF instead of a real blob index
  ;LDA [ptr_lo], y    ;need to check for that instead of a max y for the branch condition
  ;CMP #$FF ;heh, this compare doesn't do anything. that's no good. we've got a stack problem, if we're gonna jump,
  ;BNE          ;stay inside stack level [2]
  ;no idea, this should probably be combined with list_index maxing out.
  ;if we can figure this out later, it'd save us a handful of cycles, but this loop does terminate as-is
;probably pull y [2]
  PLA
  TAY ;[2]

;finish the outer loop when list_empty_flag is 1
  LDA list_empty_flag
  BNE IterateSpritesThatExistCont ;this leads outside the loop, so only if list_empty_flag is 1
  JMP IterateSpritesThatExistLoop
;so ugly, but more branch limit
IterateSpritesThatExistCont:

;probably pull y [1]


  PLA ;these are from FillFlickerGroups first push
  TAY


FillSortedSprites:
  TYA
  PHA
;and then finally set z-priority by looping through the active flicker group,
;transferring things in order by ENT_TYPE (probably a loop for each type) to sorted_sprites,
;then adding everything that's left to sorted_sprites

;we need flicker_groups, sorted_sprites, and ent_blob
  LDA #LOW(flicker_groups)
  STA ptr_lo
  LDA #HIGH(flicker_groups)
  STA ptr_hi

  LDA #LOW(sorted_sprites)
  STA ptr_temp_lo
  LDA #HIGH(sorted_sprites)
  STA ptr_temp_hi

  LDA #LOW(ent_blob)
  STA ctr_lo
  LDA #HIGH(ent_blob)
  STA ctr_hi

;active flicker group should be fairly easy, just add the value of active_flicker_group to the first index
;and always add 4 to get the next sprite
  LDA active_flicker_group
  STA list_index ;this will keep track of flicker_group
  LDA #$00
  STA list_index2 ;and this will keep track of sorted_sprites

;there will always be at most 4 sprites in this loop, just go all the way through it and check that each one exists
;since we're dealing with a known and low quantity, we have the luxury of iterating with X as a loop counter
  LDX #$04
AddActiveFlickerGroupLoop: 
  LDY list_index
  LDA [ptr_lo], y
  SEC
  CMP #$FD
  BCS AddActiveFlickerGroupEmpty
;still need to do z-priority, but that may be a project for another day
  LDY list_index2
  STA [ptr_temp_lo], y
  INC list_index2
  LDY list_index ;need to blank it out so they don't get copied with the other groups
  LDA #$FE       
  STA [ptr_lo], y

AddActiveFlickerGroupEmpty:

;don't forget list_index skips by four to only pick the active group sprites
  LDA list_index
  CLC
  ADC #$04

  DEX
  BNE AddActiveFlickerGroupLoop

;then just grab all the rest
;should be 16 altogether
;skipping this for now to see if it fixes a glitch. may do y checks as a condition of adding them back.
;  JMP NoOtherFlickerGroups ;didn't fix it. really need to hunt down the cause of that glitch
;end skip

  LDA #$00
  STA list_index
  LDX #$10
AddOtherFlickerGroupsLoop:
  LDY list_index
  LDA [ptr_lo], y
  CMP #$FD
  BCS AddOtherFlickerGroupsEmpty
  LDY list_index2
  STA [ptr_temp_lo], y
  INC list_index2
;definitely don't need to blank it out anymore, done with that stupid list

AddOtherFlickerGroupsEmpty:
  INC list_index ;scouring every entry this time through as opposed to the add 4 last time
  DEX
  BNE AddOtherFlickerGroupsLoop
NoOtherFlickerGroups
  PLA
  TAY

;so now that that's relatively taken care of, LoadSprites needs to pull indices from sorted_sprites
;instead of directly from the blob
;man this is gonna suck to debug.

SortSpritesEnd:
;reset all the list_indices for next time
  LDA #$00
  STA list_index
  STA list_index2
  STA list_index3
;pointers had better be at the top of the stack now
  PLA
  STA ptr_temp_hi
  PLA
  STA ptr_temp_lo
  PLA
  STA ptr_hi
  PLA
  STA ptr_lo
;and then the registers
  PLA
  TAY ;[0]
  PLA
  PLP
  RTS
;k, sorted_sprites is populated after the first call of this, and looks correct.
