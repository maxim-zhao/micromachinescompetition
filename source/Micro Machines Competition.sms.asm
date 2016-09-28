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

.background "Micro Machines.sms"

; Title screen level select auto enter and set 2-player mode
.bank 2 slot 2
.orga $8bc3
.section "Title screen level select check" overwrite
	; Set the game to 2-player mode
	ld a,1
	ld (RAM_GameMode),a
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
