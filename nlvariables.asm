  .rsset $0000
;offsets in the comments are from working RAM $0000, so should show up in the first block of a debugging hex viewer
;also for debugging purposes, the giant entity structure starts at $0400 and takes up one page (256 bytes)
;this contains all the logic data for every entity on screen, i.e. characters, pickups, and tools

;general purpose utilities
ctr_lo .rs 1 ;$00
ctr_hi .rs 1 ;$01
ptr_lo .rs 1 ;$02
ptr_hi .rs 1 ;$03
ptr_temp_lo .rs 1 ;$04
ptr_temp_hi .rs 1 ;$05
clock .rs 1 ;$06
bigclock .rs 1 ;$07
oldclock .rs 1 ;$08 to be updated at the end of the forever loop, used for timing outside of NMI
tmp .rs 1 ;$09
tmp2 .rs 1 ;$0A
list_index .rs 1 ;$0B
list_index2 .rs 1 ;$0C
list_index3 .rs 1 ;$0D
list_empty_flag .rs 1 ;$0E
active_flicker_group .rs 1 ;$0F
current_z_priority .rs 1 ;$10


;game state variables
game_state .rs 1 ;$11
bg_lo .rs 1 ;$12
bg_hi .rs 1 ;$13
attr_lo .rs 1 ;$14
attr_hi .rs 1 ;$15

;controller input
joy1 .rs 1 ;$16
joy2 .rs 1 ;$17
oldjoy1 .rs 1 ;$18
oldjoy2 .rs 1 ;$19

;ent properties, to be loaded via loop over ent_blob
cur_ent .rs 1 ;$1A
cur_ent_x .rs 1 ;$1B
cur_ent_y .rs 1 ;$1C
cur_ent_action .rs 1 ;$1D
cur_ent_dir .rs 1 ;$1E
cur_ent_cur_frame .rs 1 ;$1F
cur_ent_xforce .rs 1 ;$20
cur_ent_yforce .rs 1 ;$21
cur_ent_input .rs 1 ;$22
cur_ent_hp .rs 1 ;$23
cur_ent_sta .rs 1 ;$24
cur_ent_tool .rs 1 ;$25
cur_ent_sprite_lo .rs 1 ;$26
cur_ent_sprite_hi .rs 1 ;$27
cur_ent_type .rs 1 ;$28
cur_ent_size .rs 1 ;$29
cur_ent_max_frames .rs 1 ;$2A

;holds an ent type value for spawning or whatever else
new_ent_type .rs 1 ;$2B
;and an index for it 
new_ent .rs 1 ;$2C

;utility variables for collision checking and whatever else they may come in handy for
cur_ent_center_x .rs 1 ;$2D
cur_ent_center_y .rs 1 ;$2E
cur_ent_width .rs 1 ;$2F
cur_ent_height .rs 1 ;$30
obj_ent .rs 1 ;$31
obj_ent_x .rs 1 ;$32
obj_ent_y .rs 1 ;$33
obj_ent_dir .rs 1 ;$34
obj_ent_center_x .rs 1 ;$35
obj_ent_center_y .rs 1 ;$36
obj_ent_width .rs 1 ;$37
obj_ent_height .rs 1 ;$38
dist_x .rs 1 ;$39
dist_y .rs 1 ;$3A
ent_collision .rs 1 ;$3B
clip_flag .rs 1 ;$3C
clip_offset_lo .rs 1 ;$3D
clip_offset_hi .rs 1 ;$3E
wood_found .rs 1 ;$3F applies to the adjacent entry point to spawn wood if doge uses the hammer and there is none
last_a_clock .rs 1 ;$40
last_a_bigclock .rs 1 ;$41
last_b_clock .rs 1 ;$42
last_b_bigclock .rs 1 ;$43
a_delay_lo .rs 1; $44
a_delay_hi .rs 1; $45
b_delay_lo .rs 1; $46
b_delay_hi .rs 1; $47

  .rsset $0050
;little list buffers for the damned sorts
sprites_that_exist .rs 16 ;$50
flicker_groups .rs 16 ;$60
sorted_sprites .rs 16 ;$70

;sound engine variables
m_current_song .rs 1 ;$80
m_current_song_lo .rs 1 ;$81
m_current_song_hi .rs 1 ;$82
m_current_song_len .rs 1 ;$83
m_current_song_seq_pos .rs 1 ;$84
m_current_pattern .rs 1 ;$85
m_current_pattern_lo .rs 1 ;$86
m_current_pattern_hi .rs 1 ;$87
m_current_pattern_len .rs 1 ;$88
m_current_step .rs 1 ;$89
m_new_pattern .rs 1 ;$8A
m_step_ptr_lo .rs 1 ;$8B
m_step_ptr_hi .rs 1 ;$8C
m_current_frame .rs 1 ;$8D
m_ticks .rs 1 ;$8E
m_tempo .rs 1 ;$8F
square1_note .rs 1 ;$90
square1_note_hi .rs 1 ;$91
square1_duty .rs 1 ;$92
square1_vol .rs 1 ;$93
square1_pluck .rs 1 ;$94
square1_sweep .rs 1 ;$95
square1_sweep_rate .rs 1 ;$96
square1_sweep_ud .rs 1 ;$97
square1_sweep_depth .rs 1 ;$98
square1_rel .rs 1 ;$99
square1_com .rs 1 ;$9A
square1_com_dat .rs 1 ;$9B
square1_port .rs 1 ;$9C
square1_arp .rs 1 ;$9D
square1_arp_ticker .rs 1 ;$9E
square1_update_by_tick .rs 1 ;$9F
square1_apu_0 .rs 1 ;$A0
square1_apu_1 .rs 1 ;$A1
square1_apu_2 .rs 1 ;$A2
square1_apu_3 .rs 1 ;$A3
square2_note .rs 1 ;$A4
square2_note_hi .rs 1 ;$A5
square2_duty .rs 1 ;$A6
square2_vol .rs 1 ;$A7
square2_pluck .rs 1 ;$A8
square2_sweep .rs 1 ;$A9
square2_sweep_rate .rs 1 ;$AA
square2_sweep_ud .rs 1 ;$AB
square2_sweep_depth .rs 1 ;$AC
square2_rel .rs 1 ;$AD
square2_com .rs 1 ;$AE
square2_com_dat .rs 1 ;$AF
square2_port .rs 1 ;$B0
square2_arp .rs 1 ;$B1
square2_arp_ticker .rs 1 ;$B2
square2_update_by_tick .rs 1 ;$B3
square2_apu_0 .rs 1 ;$B4
square2_apu_1 .rs 1 ;$B5
square2_apu_2 .rs 1 ;$B6
square2_apu_3 .rs 1 ;$B7
tri_stac .rs 1 ;$B8
tri_apu_0 .rs 1 ;$B9
tri_apu_2 .rs 1 ;$BA
tri_apu_3 .rs 1 ;$BB
noise_note .rs 1 ;$BC
noise_vol .rs 1 ;$BD
noise_env_loop .rs 1 ;$BE
noise_mode .rs 1 ;$BF
noise_apu_0 .rs 1 ;$C0
noise_apu_2 .rs 1 ;$C1 ;there is no noise_apu_1
noise_apu_3 .rs 1 ;$C2
sfx_queue .rs 14 ;$C3-$D1
sfx_index .rs 1 ;$D2

oldbigclockforwaves .rs 1 ;$D3
nmi_flag .rs 1 ;$D4
;need some random junk data to fill out the rest of the page, maybe some mirroring or entropy pool
;the above variables will also drive the pseudo-random number generator, 
;so it's really best to populate the whole page, mirroring some space if necessary
;otherwise it'll return $00 way too often
;may actually implement an entropy pool later to fill up the rest if there aren't enough variables

  .rsset $0400
ent_blob .rs 256
;a single ent should hopefully only need 16 bytes. proposed format:
;$0 $1 $2      $3   $4      $5     $6      $7     $8  $9        $A   $B/C             $D           $E            $F
; x, y, action, dir, frame, xforce, yforce, input, hp, stamina, tool, mst offset lo/hi,type/$FF=DNE,size in tiles,max_frames
;set these in stone with constants and write handy dandy functions around them