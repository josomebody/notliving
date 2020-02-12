Waves:
;pointer table to wave_x, which will contain a spawn count and spawn point indices
;haha, put deployment times here too and save a couple of reads
;guess deployment times should be values of bigclock, and LoadWave will check if clock (little clock) is $00
;clock ticks every NMI, so normally probably about 60 times a second, 
;so the calculator says big clock ticks once every four seconds
  .db $04, LOW(wave_1), HIGH(wave_1) ;sixteen second breather from start
  .db $12, LOW(wave_2), HIGH(wave_2) ;think this is about one minute in
  .db $22, LOW(wave_3), HIGH(wave_3)
  .db $42, LOW(wave_4), HIGH(wave_4)
  .db $82, LOW(wave_5), HIGH(wave_5)
  .db $FF, LOW(wave_6), HIGH(wave_6) ;at this point bigclock resets, gonna need a bigger clock for more

wave_1:
;there are 11 entry points, they will be (zero-)indexed clockwise from the top left corner
;count of entries, each entry is an entry point index
  .db $01, $06

wave_2:
  .db $03, $05, $06, $07

wave_3:
  .db $05, $01, $02, $03, $05, $07

wave_4:
  .db $09, $01, $02, $03, $04, $05, $07, $08, $09, $0A

wave_5:
  .db $0A, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09

wave_6:
  .db $0A, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A