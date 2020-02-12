DogeProcessInput:
;reads in joy1 and sets doge's input variable. this should probably be executed in a branch inside a loop over ;ent_blob and use cur_ent, assuming LoadEnt has already been called. analogous to ZombieBrains, but less work.
;a big unified ProcessInput for all ents is in order.
;how naive i was. just stick this directly in the blob, easiest way to do it. only need to do differenly for
;multiplayer, which ain't happening any time soon.

  LDA joy1
;lots of code relies on doge always being ent[0]. if he's ever not we're in trouble
  STA ent_blob + ENT_INPUT
  
  RTS