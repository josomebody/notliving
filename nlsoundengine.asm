UpdateMusic: ;to do: sustain a note using the envelope if it recieves a CLR
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
;will read from a soundtrack file and play music, also take sfx from a queue. 
;should be called in NMI
;NMI adds m_tempo to m_ticks every frame and calls this when it rolls over, so once per step
;if we need an update by ticks for fine control, probably need another function for it

;first check if there's a new pattern and reset variables if necessary
  LDA m_new_pattern
  BNE UpdateMusicNoNewPattern
  INC m_current_song_seq_pos
  LDA m_current_song_len
  SEC
  CMP m_current_song_seq_pos ;if the sequence position is longer than the length, roll it over
  BCS UpdateMusicSeqCont
  LDA #$00
  STA m_current_song_seq_pos
UpdateMusicSeqCont:
;now find the current pattern
  LDY m_current_song_seq_pos ;there are two bytes before the pattern sequence
  INY ;pattern sequence length
  INY ;and tempo
  LDA [m_current_song_lo], y ;pretty sure this will be the low byte of an address to a pattern
  STA m_current_pattern_lo
  INY ;now the high byte
  LDA [m_current_song_lo], y
  STA m_current_pattern_hi
;and set the new pattern length in steps
  LDY #$00
  LDA [m_current_pattern_lo], y
  STA m_current_pattern_len
;and reset m_new_pattern
  LDA #$00
  STA m_new_pattern

;next load in a step of pattern data and process it and make the writes to the apu registers
UpdateMusicNoNewPattern:
;wanna implement a pretty simple format here, probably take note constants for each channel, volume, 
;then just "extra data" to OR into those and make writes to the registers
  ;need an offset to the current step of the right pattern
  LDA m_current_step ;current step is in ones. we need 10s 
  ;(there are $E bytes of data in a frame, one garbage)
  ;[ACTUALLY THERE ARE $12 RIGHT NOW. NEED TO REDUCE IT OR OTHERWISE TAKE CARE OF IT.]
  ASL A
  ASL A
  ASL A
  ASL A
  TAY ;now the frame offset is in Y and we can just increment as we read.
  INY ;the first byte is the pattern length, so this is treating it like pattern+1
;SQUARE CHANNEL FORMAT:
;note(constant pointing to a table), duty/vol(v:0-F + d:0-3*64?), env toggle(1/0), sweep(EPPPNSSS)
  ;so first the note constant, 
  LDA [current_pattern_lo], y
  INY
  STA square1_note ;save it, 
  TAX ;use it as an index from notetable 
  LDA notetable, x ;to get the low byte of the note
  STA square1_apu_2
  LDA notetable + 1, x ;then the high bte
  STA square1_apu_3 ;may need to OR this with %11111000 to reset the length counter. we'll see.

  ;now the volume or envelope length and duty cycle
  LDA [current_pattern_lo], y
  INY
  STA square1_vol
  STA square1_apu_0 ;register 0 keeps the volume in the low 4 bits

   ;now the envelope toggle bit
  LDA [current_pattern_lo], y
  INY
  ;which goes on bit 4 (constant volume) of register 0
  AND #%00000001
  ASL A
  ASL A
  ASL A
  ASL A
  ORA square1_apu_0
  STA square1_apu_0

  ;and finally the sweep, just take a full byte directly into the register
  LDA [current_pattern_lo], y
  INY
  STA square1_apu_1

;and copypasta with the channel numbers changed for square2
  ;so first the note constant, 
  LDA [current_pattern_lo], y
  INY
  STA square2_note ;save it, 
  TAX ;use it as an index from notetable 
  LDA notetable, x ;to get the low byte of the note
  STA square2_apu_2
  LDA notetable + 1, x ;then the high bte
  STA square2_apu_3 ;may need to OR this with %11111000 to reset the length counter. we'll see.

  ;now the volume or envelope length and duty cycle
  LDA [current_pattern_lo], y
  INY
  STA square2_vol
  STA square2_apu_0 ;register 0 keeps the volume in the low 4 bits

  ;now the envelope toggle bit
  LDA [current_pattern_lo], y
  INY
  ;which goes on bit 4 (constant volume) of register 0
  AND #%00000001
  ASL A
  ASL A
  ASL A
  ASL A
  ORA square2_apu_0
  STA square2_apu_0

  ;and finally the sweep, just take a full byte directly into the register
  LDA [current_pattern_lo], y
  INY
  STA square2_apu_1

;TRIANGLE CHANNEL FORMAT:
;note(constant pointing to a table), on/off(0/1)!, linear counter(7-bit), length counter(5-bit)
  ;so load the note constant
  LDA [current_pattern_lo], y
  INY
  ;and this works the same as the squares, but the actual pitch will be an octave lower
  TAX ;not bothering to save it, doubt we'll need it later
  LDA notetable, x ;get the low byte of the period
  STA tri_apu_2
  LDA notetable + 1, x ;now the high byte
  STA tri_apu_3

  ;then an on/off bit. hopefully it'll actually work right.
  LDA [current_pattern_lo], y
  INY
  ;pretty sure that goes on the high bit of register 0
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A
  STA tri_apu_0

  ;now the linear counter. 
  ;pretty sure you can do short notes with either this or length counter. 
  ;whichever rolls over first kills the note
  LDA [current_pattern_lo], y
  INY
  ;this goes in the low seven bits of register zero
  ORA tri_apu_0
  STA tri_apu_0

  ;and finally the length counter
  LDA [current_pattern_lo], y ;this is a 5-bit value and goes in the high end of register 3
  INY
  ASL A
  ASL A
  ASL A
  ORA tri_apu_3
  STA tri_apu_3

;NOISE CHANNEL FORMAT:
;pitch(0-f), volume(0-f), static/robot(0/1), envelope off/on(1/0)!, loop/oneshot(1/0)
  ;first the 4-bit period value
  LDA [current_pattern_lo], y
  INY
  STA noise_note
  STA noise_apu_2

  ;then the 4-bit volume
  LDA [current_pattern_lo], y
  INY
  STA noise_vol
  STA noise_apu_0

  ;then the mode or loop toggle, one bit
  LDA [current_pattern_lo], y
  INY
  STA noise_mode
  ;this goes in the high bit of register 2
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A
  ORA noise_apu_2
  STA noise_apu_2

  ;then the envelope toggle. this is 1-constant volume 0-envelope
  LDA [current_pattern_lo], y
  INY
  ;and it goes on bit 4 of register 0
  ASL A
  ASL A
  ASL A
  ASL A
  ORA noise_apu_0
  STA noise_apu_0

  ;and the envelope loop toggle, which goes on bit 5 of register 0
  LDA [current_pattern_lo], y
  INY ;not sure we need this as it's the last thing in the frame. 
      ;maybe check the garbage byte as a kind of checksum if we need to
  STA noise_env_loop ;not sure we need to save this, but there's a variable for it
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A
  ORA noise_apu_0
  STA noise_apu_0

;then check the sfx queue and load any data from there and write it to the apu registers
;think the sfx format should really just be straight register data with maybe no-op constants consisting of
;impossible/not-very-useful values
;looks like a good way to do it would be a byte for every register, and any reg1 value AND %11110000==$00 can be no-op
;probably just use $00 on the first register of every channel for a no-op for that whole channel
  LDX #$00
  ;so like load the byte for register 0, 
  ;if it's a zero skip ahead however many bytes to the next channel
  LDA sfx_queue, x
  BNE SfxYesSquare1
  TXA ;so add three here to get to square 2 register 0 (X increments after the jump)
  CLC
  ADC #$03
  TAX
  JMP SfxNoSquare1
SfxYesSquare1: ;if we're here, the byte for square1 register 0 is in A
  STA square1_apu_0
  INX
  LDA sfx_queue, x
  STA square1_apu_1
  INX
  LDA sfx_queue, x
  STA square1_apu_2
  INX
  LDA sfx_queue, x
  STA square1_apu_3
SfxNoSquare1:
;now square2, same story
  INX
  LDA sfx_queue, x
  BNE SfxYesSquare2
  TXA
  CLC
  ADC #$03
  TAX
  JMP SfxNoSquare2
SfxYesSquare2:
  STA square2_apu_0
  INX
  LDA sfx_queue, x
  STA square2_apu_1
  INX
  LDA sfx_queue, x
  STA square2_apu_2
  INX
  LDA sfx_queue, x
  STA square2_apu_3
SfxNoSquare2: ;now the triangle and noise only have three registers each.
  INX
  LDA sfx_queue, x
  BNE SfxYesTriangle
  TXA
  CLC
  ADC #$02
  TAX
  JMP SfxNoTriangle
SfxYesTriangle:
  STA tri_apu_0
  INX
  LDA sfx_queue, x
  STA tri_apu_2
  INX
  LDA sfx_queue, x
  STA tri_apu_3
SfxNoTriangle:
  INX
  LDA sfx_queue, x
  BNE SfxYesNoise; last channel, so just get out
  JMP SfxNoNoise
SfxYesNoise:
  STA noise_apu_0
  INX
  LDA sfx_queue, x
  STA noise_apu_2
  INX
  LDA sfx_queue, x
  STA noise_apu_3
SfxNoNoise:
;need to clear out the queue once the effect is sent
  LDA #$00
  LDX #$00
SfxClearQueueLoop:
  STA sfx_queue, x
  INX
  CPX #$0F ;whatever the size of the queue is +1. hope that comes out to $0F
  BNE SfxClearQueueLoop
;now if sfx are delayed from waiting for a new frame of music, just put this in
;a separate update by ticks and call it every frame.
;portamento and arp stuff can go in there too.  

;ultimately get it down to the *_apu_* variables and then make all the writes at once
  LDA square1_apu_0
  STA SQUARE1
  LDA square1_apu_1
  STA SQUARE1_SWEEP
  LDA square1_apu_2
  STA SQUARE1_NOTE_LO
  LDA square1_apu_3
  STA SQUARE1_NOTE_HI

  LDA square2_apu_0
  STA SQUARE2
  LDA square2_apu_1
  STA SQUARE2_SWEEP
  LDA square2_apu_2
  STA SQUARE2_NOTE_LO
  LDA square2_apu_3
  STA SQUARE2_NOTE_HI

  LDA tri_apu_0
  STA TRIANGLE
  LDA tri_apu_2 ;there is no tri_apu_1
  STA TRIANGLE_NOTE_LO
  LDA tri_apu_3
  STA TRIANGLE_NOTE_HI

  LDA noise_apu_0
  STA NOISE
  LDA noise_apu_2 ;there is no noise_apu_1
  STA NOISE_NOTE
  LDA noise_apu_3
  STA NOISE_TOGGLE

;then update m_current_step, check it against the pattern length, set m_new_pattern if they match
  INC m_current_step
  LDA m_current_pattern_len
  SEC
  CMP m_current_step
  BCS UpdateMusicStillNoNewPattern
  LDA #$01
  STA m_new_pattern
UpdateMusicStillNoNewPattern:


  PLA
  TAY
  PLA
  TAX
  PLA
  PLP

  RTS

LoadSong:
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

;reads from m_current_song, sets m_current_song_lo/hi/len and m_tempo
;and sets m_current_song_seq_pos and m_current_step to zero

;soundtrack data should start at label "music"
;first thing after that label should be word addresses for each song
  LDA m_current_song
  ASL A ;for a word address
  TAX
  LDA music, x
  STA m_current_song_lo
  LDA music + 1, x
  STA m_current_song_hi

;now read in song data. need a pattern sequence length and a tempo
  LDY #$00
  LDA [m_current_song_lo], y
  STA m_current_song_len
  INY
  LDA [m_current_song_lo], y
  STA m_tempo

;now reset all the necessary counters
  LDA #$00
  STA m_current_song_seq_pos
  STA m_current_step
  STA ticks ;just for a clean start and no missing a beat

  PLA
  TAY
  PLA
  TAX
  PLA
  PLP

  RTS

LoadSFX:
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

;reads in sfx_index, pulls 14 bytes from a table at "soundeffects" and loads it into sfx_queue
;sfx data is just all raw apu register values, probably a couple of garbage bytes at the end
;will try to keep the table in tens
  LDA sfx_index
  ASL A
  ASL A
  ASL A
  ASL A
  TAX ;X will be the actual table index getting currently read
  LDY #$00 ;Y will keep track of how many bytes read and iterate the loop to $0E
LoadSFXLoop
  LDA soundeffects, x
  STA sfx_queue
  INX
  INY
  CPY #$0F
  BNE LoadSFXLoop

  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
