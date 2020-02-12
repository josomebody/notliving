;ent prototypes for loading default values. 
;coordinates are all zero, should read in each instance from a map or somewhere
;      x,y,action,dir,frame,xforce,yforce,input,hp,stamina,tool,masterspritelo,masterspritehi,type,size,maxframe
ent_protos:
proto_doge:
  .db $00,$00,$00,$02,$00,$00,$00,$00,$01,$0F,$00,LOW(doge_master_sprite_offset),HIGH(doge_master_sprite_offset),ENT_TYPE_DOGE,$04,$01

proto_zombie:
  .db $00,$00,$00,$02,$00,$00,$00,$00,$10,$FF,$00,LOW(zombie_master_sprite_offset),HIGH(zombie_master_sprite_offset),ENT_TYPE_ZOMBIE,$04,$01

;need to decide on real initial hp for the tools, since we're actually using them
;probably enough to make things easy toward the beginning, but really tedious once the bigger waves kick in
proto_hammer:
  .db $00,$00,$00,$00,$00,$00,$00,$00,$03,$FF,$00,LOW(hammer_master_sprite_offset),HIGH(hammer_master_sprite_offset),ENT_TYPE_HAMMER,$01,$01

proto_torch:
  .db $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$00,LOW(torch_master_sprite_offset),HIGH(torch_master_sprite_offset),ENT_TYPE_TORCH,$01,$01

proto_rifle:
  .db $00,$00,$00,$00,$00,$00,$00,$00,$07,$FF,$00,LOW(rifle_master_sprite_offset),HIGH(rifle_master_sprite_offset),ENT_TYPE_RIFLE,$01,$01

proto_bandaid:
  .db $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$00,LOW(bandaid_master_sprite_offset),HIGH(bandaid_master_sprite_offset),ENT_TYPE_BANDAID,$01,$01

proto_wood:
  .db $00,$00,$00,$00,$00,$00,$00,$00,$08,$FF,$00,LOW(wood_master_sprite_offset),HIGH(wood_master_sprite_offset),ENT_TYPE_WOOD,$02,$01

proto_zhands:
  .db $00,$00,$00,$00,$00,$00,$00,$00,$10,$FF,$00,LOW(zhands_master_sprite_offset),HIGH(zhands_master_sprite_offset),ENT_TYPE_ZHANDS,$02,$02

;need to add pickups
proto_wood_pu:
  .db $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$00,LOW(wood_pu_master_sprite_offset),HIGH(wood_pu_master_sprite_offset),ENT_TYPE_WOOD_PU,$01,$01

proto_cloth_pu:
  .db $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$00,LOW(cloth_pu_master_sprite_offset),HIGH(cloth_pu_master_sprite_offset),ENT_TYPE_CLOTH_PU,$01,$01

proto_ammo_pu:
  .db $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$00,LOW(ammo_pu_master_sprite_offset),HIGH(ammo_pu_master_sprite_offset),ENT_TYPE_AMMO_PU,$01,$01


