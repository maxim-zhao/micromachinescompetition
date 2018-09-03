.memorymap
slotsize $4000
slot 0 $0000
slot 1 $4000
slot 2 $8000
defaultslot 2
.endme

.rombankmap
bankstotal 16 ; must be a multiple of 4 for Everdrive compatibility
banksize $4000
banks 16
.endro

.define TIME_TRIAL

.background "Micro Machines.sms"

; Title screen level select auto enter and set 2-player mode
.bank 2 slot 2
.orga $8bc3
.section "Title screen level select check" overwrite
.ifndef TIME_TRIAL
	; Set the game to 2-player mode
	ld a,1
	ld (RAM_GameMode),a
.endif
	; Then enter the level select (which is usually 1-player)
	jp PracticeMode
	; We trash some other code, but we don't need it
.ends

.define PracticeMode $8c23

; Limit level select to avoid Ruff Trux (which don't work right in 2-player mode)
; and to not show the last race either (as it's a duplicate).
; Race 0 (qualifying race) is excluded too, it seems not to work properly anyway.
.define MAX_LEVEL $1c-4
.orga $b298
.section "Track increment patch" overwrite
	ld a,(RAM_TrackIndex)
	add a, 1
	cp MAX_LEVEL+1 ; Modifying value here
.ends

.orga $b27e
.section "Track decrement patch" overwrite
	ld a, (RAM_TrackIndex)
	sub 1
	or a
	jr nz, +
	ld a, MAX_LEVEL ; Modifying value here
+:
.ends

; Disable splash
.unbackground $8018 $801a
.orga $8018
	; was: call $c000
	nop
	nop
	nop

; Define symbols for RAM
.define RAM_TrackIndex $dbd8
.export RAM_TrackIndex
.define RAM_TitleScreenMode $d699
.export RAM_TitleScreenMode
.define RAM_GameMode $dc3d ; 1 for 2-player
.export RAM_GameMode

.ifdef TIME_TRIAL
; Replace HUD sprite locations
.bank 0 slot 0
.unbackground $a6d $a7e
.orga $a6d
.section "HUD sprite locaitons" force
;   laps   :    .    m    m    s    s    f    f
.db $10, $21, $35, $10, $18, $24, $2c, $38, $40 ; X - kerned around punctuation TODO
.db $08, $11, $11, $11, $11, $11, $11, $11, $11 ; Y
.ends

; Replace HUD sprite index updates
; - RAM location of tile index data
.define TileIndexes $df37
; - Initialisation
.unbackground $3d1f $3d32
.orga $3d1f
.section "HUD initialisation" force
  ; We set the punctuation tiles, wait for the refresh to do digits
  ld a,Tile_colon
  ld (TileIndexes+1),a
  ld a,Tile_dot
  ld (TileIndexes+2),a
  jp $3d33 ; skip unused code
.ends

.enum $94
  Tile_5 db
  Tile_6 db
  Tile_7 db
  Tile_8 db
  Tile_st db
  Tile_nd db
  Tile_rd db
  Tile_th db
  Tile_9 db
  Tile_0 db
  Tile_dot db
  Tile_colon db
  Tile_Dust1 db
  Tile_Dust2 db
  Tile_Dust3 db
  Tile_Dust4 db
  Tile_1 db
  Tile_2 db
  Tile_3 db
  Tile_4 db
.ende

; We ut this lookup in some unused space
.unbackground $26 $37
.section "Number to tile lookup" free
NumbersToTiles:
.db Tile_0
.db Tile_1
.db Tile_2
.db Tile_3
.db Tile_4
.db Tile_5
.db Tile_6
.db Tile_7
.db Tile_8
.db Tile_9
.ends

; - Updates
.bank 1 slot 1
.unbackground $710a $7170
.orga $710a
.section "Per-frame HUD update" force
  ; Gets called every frame, should update TileIndexes
  ld a,($DE4F) ; RaceStartCounter
  cp $80
  jr nz,_updateTiles ; not in race
  ld a,($DF65) ; HasFinished
  or a
  jr nz,_updateTiles ; finished
  ; Race is in progress
UpdateTime:
.define TimerMemory $dfa0 ; between heap and stack
  ; We use the memory left-to-right, 6 digits
  ld hl,TimerMemory+5
  ld a,(hl) ; hundredths
  add a,2 ; 0.02 = 1/50s
  cp 10
  jr nz,_noOverflow
  call _overflowDigit
  cp 10 ; tenths
  jr nz,_noOverflow
  call _overflowDigit
  cp 10 ; seconds
  jr nz,_noOverflow
  call _overflowDigit
  cp 6 ; tens of seconds
  jr nz,_noOverflow
  call _overflowDigit
  cp 10 ; minutes
  jr nz,_noOverflow
  cp 10 ; tens of minutes
  jr nz,_noOverflow
  ; can't overflow to another digit... so we fix at the max
  ld a,9
  ld b,6
-:ld (hl),a
  inc hl
  djnz -
  jr _updateTiles
  
_noOverflow:
  ld (hl),a
  ; fall through

_updateTiles:
  ; now we convert them to tile indices
  ld de,TimerMemory
  ld ix,TileIndexes+3 ; HUD tile index cache in RAM
  ld b,6
-:; get number
  ld a,(de)
  inc de
  ; convert to index
  ld hl,NumbersToTiles
  add a,l
  ld l,a
  ld a,h
  adc a,0
  ld h,a
  ld a,(hl)
  ; save
  ld (ix+0),a
  inc ix
  ; loop
  djnz -
  ret

_overflowDigit:
  ; zero
  xor a
  ; save value
  ld (hl),a
  ; point to next one
  dec hl
  ; read it in
  ld a,(hl)
  ; increment it
  inc a
  ret
.ends

; Replace sprite tiles
.bank 12 slot 2
.unbackground $30a68 $30c47
.orga $8a68
.section "Time trial HUD tiles" force
.incbin "Time trial HUD.bin"
.ends

.endif
