;TO DO:
;unit test/debug everything [something's causing a stack overflow if there are too many ents.
;flicker code isn't quite working right. it's good but doesn't sync to nmi perfectly.
;]
;implement a clean-up function
;add in all the functions as they start working right
;write music [write a simpler sound engine]
;do an attract mode and maybe end screen
;comment all variables with their zero-page addresses for debugging [DONE, but keep up with it]
;make sure everything that should be literal is in fact literal


;gentle reader, i hope this code and documentation proves educational. most if not all JSRs reference subroutines
;in their own source files, all lower-case, with title-specific modules prefixed "nl"

  .inesprg 2 ;these directives configure the rom header for use with an emulator, probably not necessary
  .ineschr 1 ;for physical burning to cartridge ROM,
  .inesmap 0 ;which is another exercise for another day.
  .inesmir 1 ;this code assembles with NESASM3, and should produce a .nes ROM file suitable for any NES emulator.

  .include "constants.asm" ;generally useful constants for an overhead game
  .include "nlconstants.asm" ;constants specific to Not Living, but adaptable things in here, 
                             ;like maps and an ent class



  .bank 0  ;trying to save this bank for extra data like a music engine, any code too big to fit in bank 2
  .org $8000
  .include "music.asm"
  .include "notetable.asm"



  .bank 2
  .org $C000
RESET:  ;boilerplate NES startup code. pretty much every game has something similar to this
  SEI
  CLD
  LDX #$40
  STX $4017
  LDX #$FF
  TXS
  INX
  STX $2000
  STX $2001
  STX $4010

vblankwait1:
  BIT $2002
  BPL vblankwait1

clrmem:
  LDA #$00
  STA $0000, X
  STA $0100, X
  STA $0300, X
  STA $0400, X
  STA $0500, X
  STA $0600, X
  STA $0700, X
  LDA #$FE
  STA $0200, X
  INX
  BNE clrmem

vblankwait2:
  BIT $2002
  BPL vblankwait2 ;this is the bare minimum boilerplate startup stuff



  .include "nlvariables.asm"

  .include "palettes.asm"

  ;setting up for the title screen
TitleScreen:
  LDA #LOW(nttitlescreen)
  STA bg_lo
  LDA #HIGH(nttitlescreen)
  STA bg_hi
  LDA #LOW(universalattr)
  STA attr_lo
  LDA #HIGH(universalattr)
  STA attr_hi

  JSR LoadBackground

;initialize post-boot variables here. 
;setting up for the actual game post-start-screen happens in InitGame

  LDA #$00
  STA game_state
  STA active_flicker_group
;setting  up the sound engine
  STA m_current_song
  STA m_current_song_seq_pos
  STA m_current_frame
  STA m_ticks
;enable sound
  LDA #$0F
  STA APUSTATUS
;load some music
  JSR LoadSong
;-------------------------

Forever:
;if game_state==0, wait for BUTTON_STA to get pressed, loop over the title screen
  LDA game_state
  BNE InGame
  JSR ReadControllers
  LDA joy1
  EOR oldjoy1
  AND #BUTTON_STA
  BEQ TitleScreenContinue
  LDA #$01 ;when BUTTON_STA is pressed, set game_state=1 so we go to InGame next time around
  STA game_state
;also try to load nthouse into the background
  LDA #LOW(nthouse)
  STA bg_lo
  LDA #HIGH(nthouse)
  STA bg_hi
  JSR LoadBackground
;and finally init the game state
  JSR InitGame
  ;gotta set oldclock to something somewhere for the first time
  LDA clock
  STA oldclock
;we'll do something similar to get back to the titlescreen at gameover.
TitleScreenContinue:
  JMP NotInGame

InGame:
  LDA game_state
  CMP #$02
  BEQ Dead
  CMP #$03
  BEQ DeathScreen
;call everything that doesn't need to be called in NMI in some logical order
;this is the main game loop
  BIT PPUSTATUS
  BMI InGameNoNMI
;anything that needs to happen every NMI but can't go in NMI happens here
  JSR SortSprites
  BIT PPUSTATUS
  BMI InGameNoNMI
  JSR LoadSprites ;load sprites needs to load the actve flicker group first, 
		  ;and active_flicker_group should update every NMI

InGameNoNMI:

  JSR LoadWave

  JSR ReadControllers
  JSR DogeProcessInput ;this and ZombieBrains set all the ent inputs
  JSR ZombieBrains ;needs to iterate over all zombies that exist
  JSR ProcessInput ;this sets all the other ent elements that input affects
  JSR ProcessAction
  JSR UpdatePhysics
  JSR CleanUpBlob

;how bout right here we put some timing-specific stuff and try to keep NMI clean-ish
  LDA clock
  ;CMP oldclock ;if this stuff just never happens if could be that clock rolls over
  SEC
  SBC oldclock; getting an actual delta for now, gonna slow things down a bit.
  SEC
  CMP #$0C ;checking the delta against hypothetically a framecount. 60 should be 1sec. 0C seems perfect for doge. maybe do individual timing for sprites later.
  BCC TimeDeltaZero ;and syncs up to this loop. 
                    ;unlikely, but add a check to bigclock if we have to
  JSR AnimUpdate

  LDA clock
  STA oldclock
TimeDeltaZero:
  JMP NotInGame
Dead: ;add cool death screen here
  LDA #LOW(ntdeathscreen)
  STA bg_lo
  LDA #HIGH(ntdeathscreen)
  STA bg_hi
  JSR LoadBackground
  LDA #$03
  STA game_state
;clear the sprites
  LDX #$00
  LDA #$EF
DeathClearSpritesLoop:
  STA $0200, X
  INX
  BNE DeathClearSpritesLoop

DeathScreen:
  JSR ReadControllers
  LDA joy1
  EOR oldjoy1
  AND #BUTTON_STA
  BEQ DeathScreen
  JMP RESET

NotInGame:
;and update oldclock at the end of forever so we can get time deltas
  JMP Forever



NMI:  ;anything that has to happen while a frame is being written to screen happens in here
  PHA ;this interrupt is useful for keeping the timing of things good, but try not to cram too much into it
  TXA
  PHA
  TYA
  PHA

  LDA #$00
  STA PPUMASK
  STA OAMADDR
  LDA #$02
  STA OAMDMA
  
;clock code
  CLC
  LDA clock
  ADC #$01
  STA clock
  LDA #$00
  ADC bigclock
  STA bigclock
  LDA #$01
  STA nmi_flag
;any game functions that need to be in here should probably go after this comment

  LDA m_ticks
  CLC
  ADC m_tempo
  STA m_ticks
  BCS DoMusicUpdate
  JMP NoMusicUpdate
DoMusicUpdate:
  JSR UpdateMusic
NoMusicUpdate:


;and before this one
  INC active_flicker_group
  LDA active_flicker_group
  AND #%00000011
  STA active_flicker_group

  LDA #%10010000
  STA PPUCTRL
  LDA #%00011110
  STA PPUMASK
  LDA #$00
  STA PPUSCROLL
  STA PPUSCROLL

  PLA
  TAY
  PLA
  TAX
  PLA
  RTI


;all function modules go here i think
;may need a stubs.asm for unit testing
  .include "nlzombiebrains.asm"
  .include "nlprocessaction.asm"
  .include "nlloadsprites.asm"
  .include "nlsortsprites.asm"
  .include "nlupdatephysics.asm"
  .include "nlloadwave.asm"
  .include "nlwaves.asm"
  .include "nlentprotos.asm"
  .include "nlprocessinput.asm"
  .include "nlclipcheck.asm"
  .include "nlentcollision.asm"
  .include "nlspawnent.asm"
  .include "nlgetentsize.asm"
  .include "nldogeprocessinput.asm"
  .include "nlanimupdate.asm"
  .include "nlsaveent.asm"
  .include "nlloadent.asm"
  .include "nlentrypoints.asm"
  .include "nlloadbackground.asm"
  .include "readcontrollers.asm"
  .include "nlinitgame.asm"
  .include "nlnewgamestate.asm"
  .include "nlcleanupblob.asm"

;yoinked from the bottom of bank 3. works beter in here so far, may put it back if this bank fills up
;clipmap is indeed too big
sprites:
  .include "nlsprites.asm" ;if you look in this file, it's all the info that gets written to a sprite buffer
                           ;to blit a sprite, e.g. relative coordinates, tile numbers, attribute bytes
                           ;the tile numbers point to the .chr file referenced in bank 4

  .bank 3
  .org $E000
nametables:
  .include "nlnametables.asm" ;actual background maps
attributetables:
  .include "nlattribute.asm" ;attribute tables obviously, for setting the palettes for background tiles
palette:
  ;.include "nlpalettes.asm"
  .incbin "notliving.dat" ;binary palette, hope your tile editor spits one out for you
clipmap:
  .include "nlcliptable.asm" ;my in-house clipping table. logic to handle this is in nlclipcheck.asm

;music:
  .include "nlsoundtrack.asm"





  .org $FFFA ;think the NES looks in here at boot for the addresses of NMI and RESET, so put them in here
  .dw NMI

  .dw RESET
  .dw 0




  .bank 4
  .org $0000 ;put tile/character tables here. best to make them with a tool that spits out binaries
  .incbin "notliving.chr"




