music:
;guess a look-up table of song offsets (from music), then each song has a tempo, instrument settings,
;length in patterns, and a pattern sequence, then blocks of pattern data
   .db LOW(song0), HIGH(song0)

song0:

      ;LEN TEMPO
   .db $01, $20
      ;PATTERN SEQUENCE
   .db LOW(pattern0), HIGH(pattern0)


;default frame
;   .db CLR, $0F, $00, $00, CLR, $0F, $00, $00, CLR, $00, OFF, $00, $00, $00, $00, $00

pattern0:
      ;LEN
   .db $20
            ;$00-0F                                  1/0 $00-0Fsame 0-3
      S1N  VOL  ENV  SWP   S2N  VOL  ENV  SWP   TRN  MUT  LIN   NSN  VOL  MOD  ENV  LOOP
      $00  $01  $02  $03   $04  $05  $06  $07   $08  $09  $0A   $0B  $0C  $0D  $0E  $0F
  .db AS1, $0F, $03, $00,  B_1, $0F, $03, $00,  A_3, $00, OFF,  $00, $00, $00, $00, $00



soundeffects:


