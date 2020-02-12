SaveEnt:
  PHP
  PHA
  TYA
  PHA
  TXA
  PHA

;saves cur_ent into its proper slot in ent_blob
  LDA cur_ent
  ASL A
  ASL A
  ASL A
  ASL A
  TAX
;offset from ent_blob is now in x
  LDA cur_ent_x
  STA ent_blob + ENT_X, x
  LDA cur_ent_y
  STA ent_blob + ENT_Y, x
  LDA cur_ent_action
  STA ent_blob + ENT_ACTION, x
  LDA cur_ent_dir
  STA ent_blob + ENT_DIR, x
  LDA cur_ent_cur_frame
  STA ent_blob + ENT_FRAME, x
  LDA cur_ent_xforce
  STA ent_blob + ENT_XFORCE, x
  LDA cur_ent_yforce
  STA ent_blob + ENT_YFORCE, x
  LDA cur_ent_input
  STA ent_blob + ENT_INPUT, x
  LDA cur_ent_hp
  STA ent_blob + ENT_HP, x
  LDA cur_ent_sta
  STA ent_blob + ENT_STA, x
  LDA cur_ent_tool
  STA ent_blob + ENT_TOOL, x
;the variable set cur_ent_sprite points to the metasprite table for the CURRENT action, dir, and frame.
;the ent_blob offset ENT_SPRLO/HI is the master sprite offset for the ent, and should only ever get set
;by SpawnEnt
  LDA cur_ent_type
  STA ent_blob + ENT_TYPE, x
  LDA cur_ent_size
  STA ent_blob + ENT_SPRITE_SIZE, x
  LDA cur_ent_max_frames
  STA ent_blob + ENT_MAX_FRAMES, x


  PLA
  TAX
  PLA
  TAY
  PLA
  PLP
  RTS