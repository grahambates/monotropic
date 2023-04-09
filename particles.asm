		include	"_main.i"
		include	"particles.i"
		include	"music.i"

PARTICLES_END_FRAME = $3ff
FADEOUT_START = PARTICLES_END_FRAME-30
MAX_Z = $7ff
MAX_R = $fff
		rsreset
Paricle_X	rs.w	1
Paricle_Y	rs.w	1
Paricle_R	rs.w	1
Paricle_Z	rs.w	1
Paricle_VX	rs.w	1
Paricle_VY	rs.w	1
Particle_SIZEOF	rs.b	0

********************************************************************************
Particles_Effect:
Init:
		move.l	VBlank,StartFrame

		; Fill black and white palettes for fade
		lea	Pal3,a0
		lea	Pal1,a1
		moveq	#16-1,d7
.col		move.w	#$ffd,(a0)+
		move.w	#$000,(a1)+
		dbf	d7,.col

		; Generate random particles
		lea	Particles,a0
		moveq	#MAX_PARTICLES-1,d7
.l:
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
		and.w	MaxZ(pc),d0
		addq	#1,d0
		move.w	d0,(a0)+
; vx
		jsr	Random32
		asr.w	#7,d0
		move.w	d0,(a0)+
; vy
		jsr	Random32
		asr.w	#7,d0
		move.w	d0,(a0)+
		dbf	d7,.l

Frame:
		jsr	SwapBuffers
		jsr	Clear

		move.l	VBlank,d0
		sub.l	StartFrame(pc),d0
		move.l	d0,CurrFrame

		; X panning using sin(f)
		lea	Sin,a0
		move.l	CurrFrame(pc),d0
		move.w	d0,d6
		add.w	d0,d0
		and.w	#$3ff,d0
		add.w	d0,d0
		move.w	(a0,d0.w),d0
		ext.l	d0
		add.l	d0,d0
		move.l	d0,XPan

		; Draw copper circle for 'sun'
		cmp.w	#$3b1,d6
		bge	.noCop
		move.l	#$3ff,d3
		sub.l	d6,d3
		lsl	#2,d3
		move.l	#$ffff,d2
		divu	d3,d2
		moveq	#0,d0
		moveq	#0,d1
		jsr	CopCircle
.noCop

		; Fade out to white:
		cmp.w	#FADEOUT_START,d6
		ble	.noFadeOut
		sub.w	#FADEOUT_START,d6
		move.w	d6,d0
		lsl.w	#8,d0
		lsl.w	#2,d0
		lea	Particles_Pal,a0
		lea	Pal3,a1
		bra	.doFade

.noFadeOut
		; Fade in from black:

		; Add flicker with value noise?
		cmp.w	#100,d6
		ble	.noFlicker
		cmp.w	#$360,d6
		bgt	.noFlicker
		; clamp step value from fram
		cmp.w	#$8000>>8,d6
		ble	.fadeOk
		move.w	#$8000>>8,d6
.fadeOk
		; subtract noise value
		lea	ValueNoise,a1
		move.l	CurrFrame(pc),d0
		and.w	#$ff,d0
		move.b	(a1,d0),d0
		ext.w	d0
		sub.w	d0,d6
.noFlicker
		move.w	d6,d0
		lsl.w	#8,d0
		lea	Pal1,a0
		lea	Particles_Pal,a1

.doFade
		lea	Pal2,a2
		moveq	#16-1,d1
		jsr	LerpPal
		lea	Pal2,a1
		lea	color(a6),a2
		lea	color31(a6),a3
		moveq	#16-1,d7
.col		move.w	(a1)+,d0
		move.w	d0,(a2)+
		move.w	d0,-(a3)
		dbf	d7,.col
		move.w	d0,color31(a6)

; Update / draw particles:
		lea	Particles,a5
		move.l	DrawBuffer,a1
		lea	DIW_BW/2+SCREEN_H/2*SCREEN_BW(a1),a1	; centered with top/left padding
		move.l	DrawClearList,a2

		move.w	MaxZ(pc),d0
		subq	#1,d0
		move.w	d0,MaxZ

		move.l	CurrFrame(pc),d0
		lsr.w	#5,d0
		move.w	d0,ZSpeed

		moveq	#MAX_PARTICLES-1,d7
.l:
		; Update Z value:
		move.w	ZSpeed,d0
		sub.w	d0,Paricle_Z(a5)
		bgt	.ok1
		; loop and reset on z<=0
		move.w	MaxZ(pc),d1
		add.w	d1,Paricle_Z(a5)
		jsr	Random32
		move.w	d0,Paricle_X(a5)
		jsr	Random32
		move.w	d0,Paricle_Y(a5)
.ok1
		; Load the next particle:
		; d0 = x
		; d1 = y
		; d2 = r
		; d3 = z
		; d4 = vx
		; d5 = vy
		movem.w	(a5)+,d0-d5

; 		lea Music_Levels,a3
; 		move.w (a3),d6
; 		beq .ok
; 		lsl.w #5,d6
; 		add.w d6,d2
; .ok

		; Apply velocity
		add.w	d4,Paricle_X(a5)
		add.w	d5,Paricle_Y(a5)
		; Apply x pan
		add.l	XPan,d0

		lea	DivTab,a4
		add.w	d3,d3
		move.w	(a4,d3.w),d5
		add.w	d5,d5

		; Apply perspective
		muls	d5,d2
		swap	d2
		muls	d5,d0
		swap	d0
		muls	d5,d1
		swap	d1

		; Set colour based on z depth
		lsr.w	#8,d3
		lsr.w	#2,d3
		mulu	#SCREEN_BPL,d3

		jsr	DrawCircle

.next		dbf	d7,.l
		move.l	#0,(a2)+				; End clear list

		DebugStartIdle
		jsr	WaitEOF
		DebugStopIdle

		cmp.l	#PARTICLES_END_FRAME,CurrFrame
		blt	Frame
		rts



MaxZ:		dc.w	MAX_Z
StartFrame:	dc.l	0
CurrFrame:	dc.l	0

Particles_Pal:
		dc.w	$000
		dc.w	$013
		dc.w	$124
		dc.w	$235
		dc.w	$346
		dc.w	$456
		dc.w	$567
		dc.w	$678
		dc.w	$788
		dc.w	$899
		dc.w	$9aa
		dc.w	$bba
		dc.w	$ccb
		dc.w	$ddc
		dc.w	$eec
		dc.w	$ffd


*******************************************************************************
		bss
*******************************************************************************

Particles:	ds.b	Particle_SIZEOF*MAX_PARTICLES
ZSpeed:		ds.w	1
XPan:		ds.l	1