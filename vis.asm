		include	"_main.i"
		include	"vis.i"
		include	"music.i"

VIS_END_FRAME = $7ff
MAX_Z = $3ff
MAX_R = $1fff
MAX_PARTICLES = 40
DECAY = 64
BG_COL = $000
MIN_LEV = 8

		rsreset
Paricle_X	rs.w	1
Paricle_Y	rs.w	1
Paricle_R	rs.w	1
Paricle_Z	rs.w	1
Paricle_Chan	rs.w	1
Particle_SIZEOF	rs.b	0

********************************************************************************
Vis_Effect:
Init:
		; Set BG color
		move.w	#BG_COL,color00(a6)

		; Generate random particles
		lea	Particles,a0
		moveq	#MAX_PARTICLES-1,d7
.l:
		bsr	InitParticle
		dbf	d7,.l

Frame:
		jsr	SwapBuffers
		jsr	Clear

		lea	Pal,a1
		lea	Pal0,a2
		lea	Music_Levels,a3
		moveq	#4-1,d6
.chan
		move.w	(a3)+,d0
		cmp.w	#MIN_LEV,d0
		bge	.noMin
		move.w	#MIN_LEV,d0
.noMin
		move.w	(a1)+,d4
		move.w	#BG_COL,d3
		add.w	d0,d0
		lsl	#8,d0
		move.w	d6,a5
		jsr	LerpCol
		move.w	d7,(a2)+
		move.w	a5,d6
		dbf	d6,.chan

; Set palette
		lea	color16(a6),a1
		move.w	#15-1,d6
.col
		lea	Pal0+8,a2
		moveq	#0,d0					; r
		moveq	#0,d1					; g
		moveq	#0,d2					; b
		; moveq #0,d7 ; dest color
		moveq	#4-1,d5					; iterate channels
.chan1
		move.w	-(a2),d4				; Channel color
		move.w	d6,d3
		addq	#1,d3
		btst	d5,d3
		beq	.nextChan

; Add the colours:

		; blue
		move.w	d4,d3
		and.w	#$f,d3
		add.w	d3,d2
		cmp.w	#$f,d2
		ble	.blueOk
		move.w	#$f,d2
.blueOk
		; green
		lsr	#4,d4
		move.w	d4,d3
		and.w	#$f,d3
		add.w	d3,d1
		cmp.w	#$f,d1
		ble	.greenOk
		move.w	#$f,d1
.greenOk
		; red
		lsr	#4,d4
		and.w	#$f,d4
		add.w	d4,d0
		cmp.w	#$f,d0
		ble	.redOk
		move.w	#$f,d0
.redOk

.nextChan
		dbf	d5,.chan1
		lsl.w	#8,d0
		lsl.w	#4,d1
		add.w	d1,d0
		add.w	d2,d0
		move.w	d0,-(a1)
		dbf	d6,.col

		; X panning using sin(f)
		lea	Sin,a0
		move.l	VBlank,d0
		move.w	d0,d6
		add.w	d0,d0
		and.w	#$3ff,d0
		add.w	d0,d0
		move.w	(a0,d0.w),d0
		ext.l	d0
		add.l	d0,d0
		move.l	d0,XPan

; Update / draw particles:
		lea	Particles,a5
		move.l	DrawBuffer,a1
		lea	DIW_BW/2+SCREEN_H/2*SCREEN_BW(a1),a1	; centered with top/left padding
		move.l	DrawClearList,a2

		moveq	#MAX_PARTICLES-1,d7
.l
		; Load the next particle:
		; d0 = x
		; d1 = y
		; d2 = r
		; d3 = z
		; d6 = chan
		movem.w	(a5)+,d0-d3/d6

		add.l	XPan,d0

		; Apply velocity
		sub.w	#300,Paricle_Y(a5)
		sub.w	#DECAY,Paricle_R(a5)

		lea	Music_Levels,a3
		add.w	d6,d6
		move.w	(a3,d6.w),d4
		beq	.ok
		lsl.w	#5,d4
		add.w	d4,d2
.ok
		tst.w	d2
		bgt	.rOk
		lea	-Particle_SIZEOF(a5),a0
		bsr	InitParticle
		bra	.next
.rOk

		lea	DivTab,a4
		add.w	d3,d3
		move.w	(a4,d3.w),d5

		; Apply perspective
		muls	d5,d2
		swap	d2
		muls	d5,d0
		swap	d0
		muls	d5,d1
		swap	d1

		mulu	#SCREEN_BPL/2,d6
		move.w	d6,d3

		jsr	DrawCircle

.next		dbf	d7,.l
		move.l	#0,(a2)+				; End clear list

		DebugStartIdle
		jsr	WaitEOF
		DebugStopIdle

		cmp.l	#VIS_END_FRAME,VBlank
		blt	Frame
		rts


********************************************************************************
InitParticle:
; x
		jsr	Random32
		move.w	d0,(a0)+
; y
		jsr	Random32
		move.w	d0,(a0)+
; r
		jsr	Random32
		and.w	#MAX_R,d0
		move.w	d0,(a0)+
; z
		jsr	Random32
		and.w	#MAX_Z,d0
		addq	#1,d0
		move.w	d0,(a0)+
; chan
		jsr	Random32
		and.w	#3,d0
		move.w	d0,(a0)+
		rts

Pal:		dc.w	$147,$bda,$f8e,$2ab


*******************************************************************************
		bss
*******************************************************************************

Particles:	ds.b	Particle_SIZEOF*MAX_PARTICLES
XPan		ds.l	1
