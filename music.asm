UpdateMusic:
;right now just for the sake of breaking it all the loads are constants counting from 
;music+m_current_frame
;needs to get a full pointer to the righ step in the right pattern and handle pattern ending
;check it against the pattern length and load a new pattern if necessary
   LDA m_current_step
   CMP m_current_pattern_len
   BNE NoNewPattern
   INC m_current_song_seq_pos
   LDA #$00
   STA m_current_step
;check against song length and loop if necessary
   LDA m_current_song_seq_pos
   CMP m_current_song_len
   BNE NoSongLoop
   LDA #$00
   STA m_current_song_seq_pos
NoSongLoop:
   JSR LoadPattern
NoNewPattern:
   LDA #$00
   STA m_step_ptr_lo
   STA m_step_ptr_hi
;now get a pointer to the right step and work from there
;m_current_pattern_lo/hi should be set by LoadPattern
   LDA m_current_step 
;a step is padded out to $10 bytes, so just multiply it by $10 to get the right step offset
   STA m_step_ptr_lo
   CLC
   ASL m_step_ptr_lo
   LDA #$00
   ADC m_step_ptr_hi
   STA m_step_ptr_hi
   ASL m_step_ptr_hi
   CLC
   ASL m_step_ptr_lo
   LDA #$00
   ADC m_step_ptr_hi
   STA m_step_ptr_hi
   ASL m_step_ptr_hi
   CLC
   ASL m_step_ptr_lo
   LDA #$00
   ADC m_step_ptr_hi
   STA m_step_ptr_hi
   ASL m_step_ptr_hi
   CLC
   ASL m_step_ptr_lo
   LDA #$00
   ADC m_step_ptr_hi
   STA m_step_ptr_hi
;add the pattern pointer to it and put it in m_step_ptr_lo/hi
   LDA m_current_pattern_lo
   CLC
   ADC m_step_ptr_lo
   STA m_step_ptr_lo
   LDA #$00
   ADC m_step_ptr_hi
   STA m_step_ptr_hi
   LDA m_current_pattern_hi
   CLC
   ADC m_step_ptr_hi
   STA m_step_ptr_hi
  
   LDA #$00
   STA square1_update_by_tick ;reset portamento/arp flag
   LDY #$01 ;using y to index each byte in a step, remember to keep it in sync, 
            ;the one compensates for the length byte
   LDA [m_step_ptr_lo], y ;should read in a note constant
   INY
   CMP #REL
   BNE NoRelS1
   LDA [m_step_ptr_lo], y; get the volume/decay data
   INY
   ORA #%00100000 ;flip the length counter halt bit
   STA SQUARE1
   JMP Square1Command
NoRelS1:
   CMP #OFF
   BNE NoOffS1
   INY ;gonna ignore the volume/decay data, but update y anyway for the next field
   LDA #$00
   STA SQUARE1_NOTE_HI
   JMP Square1Command
NoOffS1:
   CMP #CLR ;continue last note
   BEQ Square1NoteContinue
   STA square1_note ;might need this later
   ASL A
   TAX ;note offset is in x. note data is 11-bit. lo-8 goes on $4002,
       ;hi-3 on the low 3 bits of $4003 
   LDA notetable, x
   STA SQUARE1_NOTE_LO ;DISABLED FOR TESTING
   LDA notetable+1, x
   ORA #%11111000 ;repopulate the length counter in case it was off
   STA square1_note_hi
   STA SQUARE1_NOTE_HI ;DISABLED FOR TESTING
Square1NoteContinue:
   LDA [m_step_ptr_lo], y; get the volume/decay data
   INY
   CMP #$0F
   BPL Square1Command ;volume/decay only goes $00-$0f. ignore any higher value
   STA square1_vol
;   CLC
;   ADC square1_duty ;squarex_duty will be the two high bits, command to change it
;   STA SQUARE1      ;should take a number 0-3 and asl it six times
;restructuring -- read in the duty cycle separately, use square1apu_0 when everything's done
   LDA square1_duty
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   STA square1_apu_0
   LDA square1_pluck
   ASL A
   ASL A
   ASL A
   ASL A
   ORA square1_apu_0
   STA square1_apu_0
   LDA square1_vol
   ORA square1_apu_0
   STA square1_apu_0
   LDA square1_apu_0
   STA SQUARE1
Square1Command:
;read in command opcode byte
   LDA [m_step_ptr_lo], y
   INY
   STA square1_com
;read in command data
   LDA [m_step_ptr_lo], y
   INY
   STA square1_com_dat
   LDA square1_com
   BEQ NoComS1 ;command $00 is a no-op
   CMP #$01
   BEQ SetTimbS1
   CMP #$02
   BEQ SetPluckS1
   CMP #$03
   BEQ SetVibS1
   CMP #$04
   BEQ SetRelS1
   CMP #$05
   BEQ PortamentoS1
   CMP #$06
   BEQ ArpS1
   JMP NoComS1
SetTimbS1: ;restructure these to use _apu_x later
   LDA square1_com_dat
   STA square1_duty
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   AND square1_vol
   STA SQUARE1
   JMP NoComS1
SetPluckS1:
   LDA square1_com_dat
   ASL A
   ASL A
   ASL A
   ASL A
   AND square1_duty
   AND square1_vol
   STA SQUARE1
   JMP NoComS1
SetVibS1:
   LDA square1_com_dat
   STA SQUARE1_SWEEP
   JMP NoComS1
SetRelS1:
   LDA square1_com_dat
   ASL A
   ASL A
   ASL A
   ASL A
   AND square1_note_hi
   STA SQUARE1_NOTE_HI
   JMP NoComS1
PortamentoS1:
   LDA square1_com_dat
   STA square1_port
   LDA #$01
   STA square1_update_by_tick
   JMP NoComS1
ArpS1:
   LDA square1_com_dat
   STA square1_arp
   LDA #$01
   STA square1_update_by_tick
   JMP NoComS1
NoComS1:

UpdateSquare2:
;just copy UpdateSquare1 with the appropriate name changes when it's working
   LDA #$00
   STA square2_update_by_tick ;reset portamento/arp flag
   LDA [m_step_ptr_lo], y ;should read in a note constant
   INY
   CMP #REL
   BNE NoRelS2
   LDA [m_step_ptr_lo], y; get the volume/decay data
   INY
   ORA #%00100000 ;flip the length counter halt bit
   STA SQUARE2
   JMP Square2Command
NoRelS2:
   CMP #OFF
   BNE NoOffS2
   INY ;gonna ignore the volume/decay data, but update y anyway for the next field
   LDA #$00
   STA SQUARE2_NOTE_HI
   JMP Square2Command
NoOffS2:
   CMP #CLR ;continue last note
   BEQ Square2NoteContinue
   STA square2_note ;might need this later
   ASL A
   TAX ;note offset is in x. note data is 11-bit. lo-8 goes on $4002,
       ;hi-3 on the low 3 bits of $4003 
   LDA notetable, x
   STA SQUARE2_NOTE_LO ;DISABLED FOR TESTING
   LDA notetable+1, x
   ORA #%11111000 ;repopulate the length counter in case it was off
   STA square2_note_hi
   STA SQUARE2_NOTE_HI ;DISABLED FOR TESTING
Square2NoteContinue:
   LDA [m_step_ptr_lo], y; get the volume/decay data
   INY
   CMP #$0F
   BPL Square2Command ;volume/decay only goes $00-$0f. ignore any higher value
   STA square2_vol
;restructuring -- read in the duty cycle separately, use square1apu_0 when everything's done
   LDA square2_duty
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   STA square2_apu_0
   LDA square2_pluck
   ASL A
   ASL A
   ASL A
   ASL A
   ORA square2_apu_0
   STA square2_apu_0
   LDA square2_vol
   ORA square2_apu_0
   STA square2_apu_0
   LDA square2_apu_0
   STA SQUARE2
Square2Command:
;read in command opcode byte
   LDA [m_step_ptr_lo], y
   INY
   STA square2_com
;read in command data
   LDA [m_step_ptr_lo], y
   INY
   STA square2_com_dat
   LDA square2_com
   BEQ NoComS2 ;command $00 is a no-op
   CMP #$01
   BEQ SetTimbS2
   CMP #$02
   BEQ SetPluckS2
   CMP #$03
   BEQ SetVibS2
   CMP #$04
   BEQ SetRelS2
   CMP #$05
   BEQ PortamentoS2
   CMP #$06
   BEQ ArpS2
   JMP NoComS2
SetTimbS2: ;restructure these to use _apu_x later
   LDA square2_com_dat
   STA square2_duty
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   AND square2_vol
   STA SQUARE2
   JMP NoComS2
SetPluckS2:
   LDA square2_com_dat
   ASL A
   ASL A
   ASL A
   ASL A
   AND square2_duty
   AND square2_vol
   STA SQUARE2
   JMP NoComS2
SetVibS2:
   LDA square2_com_dat
   STA SQUARE2_SWEEP
   JMP NoComS2
SetRelS2:
   LDA square2_com_dat
   ASL A
   ASL A
   ASL A
   ASL A
   AND square2_note_hi
   STA SQUARE2_NOTE_HI
   JMP NoComS2
PortamentoS2:
   LDA square2_com_dat
   STA square2_port
   LDA #$01
   STA square2_update_by_tick
   JMP NoComS2
ArpS2:
   LDA square2_com_dat
   STA square2_arp
   LDA #$01
   STA square2_update_by_tick
   JMP NoComS2
NoComS2:




UpdateTriangle:
   LDA [m_step_ptr_lo], y
   INY
   CMP #OFF
   BNE NoOffTri
   LDA #$00
   STA TRIANGLE_NOTE_HI 
   INY
   JMP TriangleDone
NoOffTri:
   CMP #CLR
   BEQ TriNoteContinue
   ASL A
   TAX
   LDA notetable, x
   STA TRIANGLE_NOTE_LO ;DISABLED FOR TESTING
   LDA notetable+1, x
   ORA #%11111000 ;gotta turn the triangle on, hopefully
   STA TRIANGLE_NOTE_HI ;DISABLED FOR TESTING
TriNoteContinue:
;triangle takes one command, $00 for legato, anything else for staccato
   LDA [m_step_ptr_lo], y
   INY
   BNE TriStac
   LDA #$00
   STA TRIANGLE
   JMP TriNoStac
TriStac:
   LDA #%01111111
   STA TRIANGLE
TriNoStac:
   LDA #%11111111
   STA TRIANGLE
TriangleDone:

UpdateNoise:
;noise code is a wreck here, maybe start over
   LDA [m_step_ptr_lo], y ;should be the period value for noise, 4-bits, F=low pitch, 0=high pitch
   INY
   CMP #OFF
   BNE NoNoiseOff
;turn the noise off for a step
   LDA $00
   STA NOISE_TOGGLE
   STA NOISE
   JMP NoiseDone
NoNoiseOff:
;NSN  NSV  NSE  LEN  MOD  jnk
   STA noise_note ;noise channel only takes a 4-bit period value ($0-high $F-low)
   LDA [m_step_ptr_lo], y ;volume
   INY
   STA noise_vol ;noise takes a 4-bit volume/decay value
   LDA [m_step_ptr_lo], y ;and a 1-bit envelope toggle
   INY
   STA noise_env
   LDA [m_step_ptr_lo], y ;length counter, 5-bit
   STA noise_len
   INY
   LDA [m_step_ptr_lo], y ;mode bit, 0=hiss, 1=buzz
   INY
   STA noise_mode
;and only then, dump it all to the apu buffers and then to the apu
   LDA noise_vol
   AND #%00001111
   STA noise_apu_0
   LDA noise_env
   ASL A
   ASL A
   ASL A
   ASL A
   ORA noise_apu_0
   STA noise_apu_0
   LDA noise_len
   ASL A
   ASL A
   ASL A
   STA noise_apu_3
   LDA noise_mode
   AND #%00000001
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   STA noise_apu_2

   LDA noise_apu_0
   STA $400C
   LDA noise_apu_2
   STA $400E
   LDA noise_apu_3
   STA $400F
NoiseDone:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;update the current step
   INC m_current_step
   RTS

UpdateMusicByTick:
;put arp and portamento code here, skip over if there is none
   LDA square1_update_by_tick
   CMP #$00
   BEQ NoSquare1ByTick
   LDA square1_com
   CMP #$05 ;portamento
   BNE NoSquare1Port
;figure out what to do with the data, probably use the upper bit as a sign and add/sub the rest to note_lo
NoSquare1Port:
   LDA square1_com
   CMP #$06 ;arp
   BNE NoSquare1ByTick
;figure out what to do with the data, namely read in arp_tick, use that to determine which digit to add to _note
;then update arp_tick
NoSquare1ByTick:
   RTS

LoadPattern: ;read in pattern number, look up offset from there, read in pattern length

   LDA m_current_song_seq_pos
   CLC
   ASL A ;reading the pattern in as a word
   ADC #$17 ;get through all the song settings to the pattern sequence MAGIC NUMBER: length of song header up to the pattern sequence
   TAY
   LDA [m_current_song_lo], y
   STA m_current_pattern_lo
   INY
   LDA [m_current_song_lo], y
   STA m_current_pattern_hi
   LDY #$00 ;get the first byte of pattern data, which is the length
   LDA [m_current_pattern_lo], y
   STA m_current_pattern_len
   RTS

LoadSong: ;take current song (set by map engine), load in length and pattern sequence
   LDA #$00
   STA m_ticks
   STA m_current_song_seq_pos
   STA m_current_step
   STA m_step_ptr_lo
   STA m_step_ptr_hi ;set the pattern and step sequencers to zero
   LDA m_current_song
   ASL A ;getting a word address
   TAX
   LDA music, x
   STA m_current_song_lo
   LDA music + 1, x
   STA m_current_song_hi ;pretty sure this is an absolute address. double check if problems
;load in length, which is the first byte of song data
   LDY #$00
   LDA [m_current_song_lo], y
   STA m_current_song_len
;second byte should be tempo
   INY
   LDA [m_current_song_lo], y
   STA m_tempo
;next will be some initial insrument settings
;store everything in variables that exist, then write in apu memory
;actually, just make a variable for every parameter and do all the bitwise operations to dump them
;to apu with even more variables, make life easy
   INY
   LDA [m_current_song_lo], y ;sq1 duty
   STA square1_duty

   INY
   LDA [m_current_song_lo], y ;sq1 pluck
   STA square1_pluck

   INY
   LDA [m_current_song_lo], y ;sq1 vibrato on/off
   STA square1_sweep

   INY
   LDA [m_current_song_lo], y ;sq1 vibrato rate
   STA square1_sweep_rate

   INY
   LDA [m_current_song_lo], y ;sq1 vibrato up/down
   STA square1_sweep_ud

   INY
   LDA [m_current_song_lo], y ;sq1 release rate
   STA square1_rel

   INY
   LDA [m_current_song_lo], y; sq1 volume
   STA square1_vol


   INY
   LDA [m_current_song_lo], y ;sq2 duty
   STA square2_duty

   INY
   LDA [m_current_song_lo], y ;sq2 pluck
   STA square2_pluck

   INY
   LDA [m_current_song_lo], y ;sq2 vibrato on/off
   STA square2_sweep

   INY
   LDA [m_current_song_lo], y ;sq2 vibrato rate
   STA square2_sweep_rate

   INY
   LDA [m_current_song_lo], y ;sq2 vibrato up/down
   STA square2_sweep_ud

   INY
   LDA [m_current_song_lo], y ;sq2 release rate
   STA square2_rel

   INY
   LDA [m_current_song_lo], y; sq2 volume
   STA square2_vol



   INY
   LDA [m_current_song_lo], y ;triangle stacato off/on
   STA tri_stac


   INY
   LDA [m_current_song_lo], y ;noise envelope on/off
   STA noise_env

   INY
   LDA [m_current_song_lo], y ;noise volume
   STA noise_env

;now do bitwise ops to get everything into apu buffers and dump it to the apu
   LDA square1_duty 
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   STA square1_apu_0
   LDA square1_pluck
   AND #%00000011
   ASL A
   ASL A
   ASL A
   ASL A
   ORA square1_apu_0
   STA square1_apu_0
   LDA square1_vol
   AND #%00001111
   ORA square1_apu_0
   STA square1_apu_0

   LDA square1_sweep
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   STA square1_apu_1
   LDA square1_sweep_rate
   AND #%00000111
   ORA square1_apu_1
   STA square1_apu_1
   LDA square1_sweep_ud
   AND #%00000001
   ASL A
   ASL A
   ASL A
   ORA square1_apu_1
   STA square1_apu_1
   LDA square1_sweep_depth
   AND #%00000111
   ASL A
   ASL A
   ASL A
   ASL A
   ORA square1_apu_1
   STA square1_apu_1

   LDA square1_rel
   ASL A
   ASL A
   ASL A
   ORA square1_apu_3
   STA square1_apu_3

;now just copy square1 for square2 with appropriate name changes
   LDA square2_duty 
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   STA square2_apu_0
   LDA square2_pluck
   AND #%00000011
   ASL A
   ASL A
   ASL A
   ASL A
   ORA square2_apu_0
   STA square2_apu_0
   LDA square2_vol
   AND #%00001111
   ORA square2_apu_0
   STA square2_apu_0

   LDA square2_sweep
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   STA square2_apu_1
   LDA square2_sweep_rate
   AND #%00000111
   ORA square2_apu_1
   STA square2_apu_1
   LDA square2_sweep_ud
   AND #%00000001
   ASL A
   ASL A
   ASL A
   ORA square2_apu_1
   STA square2_apu_1
   LDA square2_sweep_depth
   AND #%00000111
   ASL A
   ASL A
   ASL A
   ASL A
   ORA square2_apu_1
   STA square2_apu_1

   LDA square2_rel
   ASL A
   ASL A
   ASL A
   ORA square2_apu_3
   STA square2_apu_3

;now triangle
   LDA tri_stac
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   STA tri_apu_0

;and noise
   LDA noise_vol
   AND #%00001111
   STA noise_apu_0
   LDA noise_env
   ASL A
   ASL A
   ASL A
   ASL A
   ORA noise_apu_0
   STA noise_apu_0
   LDA noise_len
   ASL A
   ASL A
   ASL A
   STA noise_apu_3
   LDA noise_mode
   AND #%00000001
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   ASL A
   STA noise_apu_2

;and dump it all to apu
   LDA square1_apu_0
   STA $4000
   LDA square1_apu_1
   STA $4001
   LDA square1_apu_2
   STA $4002
   LDA square1_apu_3
   STA $4003
   LDA square2_apu_0
   STA $4004
   LDA square2_apu_1
   STA $4005
   LDA square2_apu_2
   STA $4006
   LDA square2_apu_3
   STA $4007
   LDA tri_apu_0
   STA $4008
   LDA noise_apu_0
   STA $400C
   LDA noise_apu_2
   STA $400E
   LDA noise_apu_3
   STA $400F


   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;then a pattern sequence, should probably store an offset for it somewhere
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   RTS
