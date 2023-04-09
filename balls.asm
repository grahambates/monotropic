		include	"_main.i"
		include	"balls.i"

EFFECT_DURATION = $bff

MAX_BALLS = 10
FRICTION = $fe
IMPACT_LIMIT = $b0
SPEED_LIMIT = $20000

START_STEP = 100

; This is the zoom step where we hit max cop circle size and copper used used to draw next container
; need to adjust if max cop circle size chagnes
FLIP_STEP = $3c

; Floating point accuracy for various operations
; tweak these for balance between inaccuracy and overflow
TRANSFORM_ACC = 5
COL_OVERLAP_ACC = 5
COL_NORM_ACC = 5
BOUNDS_NORM_ACC = 2
BOUNDS_REFLECT_ACC = 4

; Radius for circluar bounds check
BOUNDS_R = DIW_H/2

; Rectangular bounds
BOUNDS_X = DIW_W/2
BOUNDS_Y = DIW_H/2

BALLS_END = $7fffffff						; Magic number for end of array

		rsreset
Ball_X		rs.l	1
Ball_Y		rs.l	1
Ball_R		rs.l	1
Ball_VX		rs.l	1
Ball_VY		rs.l	1
Ball_Col	rs.l	1
Ball_SIZEOF	rs.b	0

********************************************************************************
Balls_Effect:
;-------------------------------------------------------------------------------
Init:
; Build log steps from deltas:
		lea LogDeltas,a0
		lea LogSteps,a1
		move.w #$100,d0
		move.w d0,(a1)+
		move.w #(LogDeltasE-LogDeltas)/2-1,d7
.delta
		moveq #0,d1
		moveq #0,d6
		move.b (a0)+,d1
		move.b (a0)+,d6
.deltaRept
		add.w d1,d0
		move.w d0,(a1)+
		dbf d6,.deltaRept
		dbf d7,.delta

		move.l	VBlank,StartFrame

; Hard code first ball in center
		lea	Balls,a1
		moveq	#0,d0
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	#16<<16,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	#SCREEN_BPL,(a1)+
		move.l	#BALLS_END,(a1)+

		lea	Balls2,a1
		moveq	#MAX_BALLS-1,d1
		bsr	GenerateBalls

********************************************************************************
Frame:
		jsr	SwapBuffers
		jsr	Clear

		move.l	VBlank,d0
		sub.l	StartFrame(pc),d0
		move.l	d0,CurrFrame

; Don't set colours yet
		cmp.w	#10,d0
		ble	UpdateStep

		clr.w	LerpPos

;-------------------------------------------------------------------------------
; Write current palette to color registers
LoadColors:
		move.w	ColorStep(pc),d0
		lsl.w	#2,d0
		lea	Colors,a0
		lea	(a0,d0.w),a3
; d1 = current bg (prev 2)
; d2 = current 1
; d3 = current 2
; d4 = next 1
; d5 = next 2
		movem.w	(a3),d1-d5
		move.w	d3,d6					; d6 = cop circ (current 2)

; Transitions:
		lea	Pal0,a0					; src 1
		lea	Pal1,a1					; src 2
		lea	Pal2,a2					; dest

		move.w	Step(pc),d0
		cmp.w	#FLIP_STEP,d0
		bgt	.noFlip
; Change cop circ for steps 0-FLIP_STEP where copper is used to draw ball 0, not bounds
		move.w	d1,d6

; Transition background and next cols over last $20 steps
		sub.w	#FLIP_STEP-$20,d0			; start pos
		bgt	.ok
		moveq	#0,d0
.ok
		move.w	d0,LerpPos
; scale 0-0x8000 for lerp
		lsl.w	#8,d0
		lsl.w	#2,d0
		movem.l	d2/d3/d6,-(sp)
; from:
		move.w	-4(a3),(a0)				; prev bg
		move.w	d3,2(a0)				; current 2
		move.w	d3,4(a0)				; current 2
; to:
		movem.w	d1/d4/d5,(a1)				; current bg / next cols
		moveq	#3-1,d1					; colour count
		jsr	LerpPal
		movem.l	(sp)+,d2/d3/d6
; restore colours from dest
		lea	Pal2,a1
		movem.w	(a1),d1/d4/d5
		bra	.transDone
.noFlip

.transDone

; Fade out at the end
		move.w #EFFECT_DURATION-$80,d0
		sub.w CurrFrame+2,d0
		bge .noFadeOut
		add.w #$80,d0
		add.w d0,d0
		lsl.w #8,d0
		lea Pal0,a0
		lea Pal1,a1
		lea Pal2,a2
		clr.l (a0)
		clr.l 4(a0)
		clr.l 8(a0)
		movem.w d1-d6,(a1)
		moveq #6-1,d1
		jsr LerpPal
		lea Pal2,a2
		movem.w (a2),d1-d6
.noFadeOut

		lea	color00(a6),a0
		lea	color16(a6),a1
		move.w	d1,(a0)+				; bg
		move.w	d6,(a1)+				; cop circ

		move.w	d2,(a0)+				; current col 1
		move.w	d2,(a1)+

		move.w	d3,(a0)+				; current col 2
		move.w	d3,(a1)+
		move.w	d3,(a0)+
		move.w	d3,(a1)+

		move.w	d1,(a0)+				; bg
		move.w	d4,(a1)+				; next col 1
		move.w	d4,(a0)+
		move.w	d4,(a1)+
		move.w	d4,(a0)+
		move.w	d4,(a1)+
		move.w	d4,(a0)+
		move.w	d4,(a1)+

		move.w	d1,(a0)+				; bg
		move.w	d5,(a1)+				; next col 2
		move.w	d5,(a0)+
		move.w	d5,(a1)+
		move.w	d5,(a0)+
		move.w	d5,(a1)+
		move.w	d5,(a0)+
		move.w	d5,(a1)+
		move.w	d5,(a0)+
		move.w	d5,(a1)+
		move.w	d5,(a0)+
		move.w	d5,(a1)+
		move.w	d5,(a0)+
		move.w	d5,(a1)+
		move.w	d5,(a0)+
		move.w	d5,(a1)+

;-------------------------------------------------------------------------------
UpdateStep:
		lea	Vars(pc),a4
		move.w	Step(pc),d7				; d7 = step

; Step delta (speed):
		moveq	#1,d6
		move.l	CurrFrame(pc),d5
		; adjust to control where fast/slow sections occur
		; avoid slow movement when zoomed in as accuracy is bad :-(
		; also want to hide transition on flip
		;add.w	#70,d5
		; TODO
		btst	#6,d5
		bne	.s
		add.w	#2,d6
.s
		btst	#7,d5
		bne	.s1
		add.w	#2,d6
.s1
; reverse
		btst	#10,d5
		beq	.s2
		btst	#8,d5
		beq	.s2
		neg.w	d6
.s2

; Handle positive or negative step delta
		tst.b	d6
		blt	.neg

; Positive step:
		add.b	d6,d7
; Time for new group?
		bcc	.stepDone
; Increment colour step
		move.w	ColorStep(pc),d0
		addq	#1,d0
		cmp.w	#COLOR_STEPS,d0
		bne	.noWrap
		moveq	#0,d0
.noWrap
		move.w	d0,ColorStep-Vars(a4)
; swap group1/2
		movem.l	Group1(pc),a0-a1
		exg	a0,a1
		movem.l	a0-a1,Group1-Vars(a4)
; re-init group 2
		moveq	#MAX_BALLS-1,d1
		bsr	GenerateBalls
		bra	.stepDone

; Positive step:
.neg:
		neg.b	d6
		sub.b	d6,d7
; Time for new group?
		bcc	.stepDone
; Decrement colour step
.doit
		move.w	ColorStep(pc),d0
		subq	#1,d0
		bge	.noWrap1
		moveq	#COLOR_STEPS-1,d0
.noWrap1
		move.w	d0,ColorStep-Vars(a4)
; swap group1/2
		movem.l	Group1(pc),a0-a1
		exg	a0,a1
		movem.l	a0-a1,Group1-Vars(a4)
; re-init group 1
		exg	a0,a1
		moveq	#MAX_BALLS-1,d1
		bsr	GenerateBalls

.stepDone
		move.w	d7,Step-Vars(a4)

;-------------------------------------------------------------------------------
UpdateDraw:
; Group 1:
; Need to get x/y of first ball to use for pan lerp so update this first
		move.l	Group1(pc),a5
		movem.l	(a5),d0-d4
		movem.l	d3-d4,VxDelta-Vars(a4)			; Need velocity delta - store initial values
		bsr	UpdateBall
		movem.l	Ball_VX(a5),d0-d1
		sub.l	d0,VxDelta-Vars(a4)
		sub.l	d1,VyDelta-Vars(a4)

; Zoom/pan towards ball 1:
; Pan:
		move.l	Ball_X(a5),d0				; d0 = ball1 x
		move.l	Ball_Y(a5),d1				; d1 = ball1 y
		move.w	d7,d3					; d3 = step
; Smoothstep:
; x * x * (3 - 2 * x)
		move.w	d3,d7
		mulu	d7,d7					; x^2
		asr.l	d7					; shift to prevent overflow
		move.w	d3,d2
		add.w	d2,d2
		neg.w	d2					; -2x
		add.w	#$300,d2				; 3-2x
		muls	d7,d2					; x^2 * (3-2x)
		add.l	d2,d2					; undo shift
		swap	d2

; Scale x/y by step value
		neg.w	d2
		asr.l	#8,d0
		asr.l	#8,d1
		muls	d2,d0
		muls	d2,d1
		movem.l	d0-d1,PanX-Vars(a4)

; Zoom:
		lea	LogSteps,a3
		move.w	d3,d2
		add.w	d2,d2
		move.w	(a3,d2.w),d2
		move.w	d2,Zoom-Vars(a4)
		clr.l	TranslateX-Vars(a4)
		clr.l	TranslateY-Vars(a4)
		clr.w	ScaleR-Vars(a4)

; Draw bounds circle for group1 if not too big:
		moveq	#0,d7					; Copper layer used state
		move.w	d2,d6
		cmp.w	#COPCIRC_MAX_R*2,d2			; bounds = 256/2
		bge	.skipBounds
; Transform:
		move.w	#8+TRANSFORM_ACC,d5
; scale x
		asl.l	#TRANSFORM_ACC,d0
		swap	d0
		muls	d6,d0
		asr.l	d5,d0
; scale y
		asl.l	#TRANSFORM_ACC,d1
		swap	d1
		muls	d6,d1
		asr.l	d5,d1
; Draw:
		lsr	#1,d2
		jsr	CopCircle
		moveq	#1,d7					; copper free status
.skipBounds

; Now draw first ball...
; We already did the update
		move.l	DrawBuffer,a1
		lea	DIW_BW/2+SCREEN_H/2*SCREEN_BW(a1),a1	; centered with top/left padding
		move.l	DrawClearList,a2
		move.l	Group1(pc),a5
		movem.l	(a5),d0-d2
		move.l	Ball_Col(a5),d3

		add.l	PanX(pc),d0
		add.l	PanY(pc),d1
; Transform:
		move.w	#8+TRANSFORM_ACC,d5
; scale x
		asl.l	#TRANSFORM_ACC,d0
		swap	d0
		muls	d6,d0
		asr.l	d5,d0
; scale y
		asl.l	#TRANSFORM_ACC,d1
		swap	d1
		muls	d6,d1
		asr.l	d5,d1
; scale r
		asl.l	#TRANSFORM_ACC,d2
		swap	d2
		mulu	d6,d2
		asr.l	d5,d2

		move.l	d0,ContainerX-Vars(a4)
		move.l	d1,ContainerY-Vars(a4)
		tst.w	d7					; use copper for first ball if free
		beq	.cop
		jsr	DrawCircle
		bra	.next
.cop		jsr	CopCircle
.next
; Process the rest of the group
		lea	Ball_SIZEOF(a5),a5
		bsr	UpdateDrawGroup

; Group 2:
		move.l	Group2(pc),a5
		lea	Transform(pc),a4			; This got trashed
		clr.l	PanX-Transform(a4)
		clr.l	PanY-Transform(a4)
		move.w	LerpPos,d0
		move.w	d0,ScaleR-Transform(a4)
		move.l	ContainerX(pc),TranslateX-Transform(a4)	; Translate based on container pos
		move.l	ContainerY(pc),TranslateY-Transform(a4)
		move.w	Zoom-Transform(a4),d0			; Zoom based on container radius (1/8th of boundary)
		lsr.w	#3,d0
		move.w	d0,Zoom-Transform(a4)

; Update velocities in based on velocity diff of container ball
; This simultes impact from collisions affecting contents
		cmp.w	#IMPACT_LIMIT,d0			; Skip this above zoom threshold
		bge	.impactDone
		move.l	VxDelta(pc),d0
		move.l	VyDelta(pc),d1
		bne	.doImpact				; only do this if one of the values is non-zero
		tst.l	d0
		bne	.doImpact
		bra	.impactDone
.doImpact
		asl.l	#2,d0
		asl.l	#2,d1
		move.l	a5,a4
.l
		cmp.l	#BALLS_END,Ball_X(a4)
		beq	.impactDone
		add.l	d0,Ball_VX(a4)
		add.l	d1,Ball_VY(a4)
		lea	Ball_SIZEOF(a4),a4
		bra	.l
.impactDone

; Draw:
		lea	SCREEN_BPL*2(a1),a1
		bsr	UpdateDrawGroup

		move.l	#0,(a2)+				; End clear list

		jsr	WaitEOF

		cmp.l	#EFFECT_DURATION,CurrFrame
		blt	Frame
		rts


********************************************************************************
; Generate random ball data
;-------------------------------------------------------------------------------
; a1 - dest
; d1 - count-1
;-------------------------------------------------------------------------------
GenerateBalls:
		move.l	#16<<16,d2
		move.l	#SCREEN_BPL,d3
.l:
; x
		jsr	Random32
		asr.l	#8,d0
		move.l	d0,(a1)+
; y
		jsr	Random32
		asr.l	#8,d0
		move.l	d0,(a1)+
; r
		move.l	d2,(a1)+
; vx
		jsr	Random32
		ext.l	d0
		lsl.l	#2,d0
		move.l	d0,(a1)+
; vy
		jsr	Random32
		ext.l	d0
		lsl.l	#2,d0
		move.l	d0,(a1)+
; color
		move.l	d3,(a1)+

; next radius
		jsr	Random32
		move.w	d0,d2
		and.l	#15,d2
		addq	#7,d2
		swap	d2
; next color
		jsr	Random32
		moveq	#0,d3
		btst	d3,d0
		beq	.no0
		move.l	#SCREEN_BPL,d3
.no0

		dbf	d1,.l
		move.l	#BALLS_END,(a1)+
		rts


********************************************************************************
; Update and draw ball group
;-------------------------------------------------------------------------------
; a1 - Draw buffer
; a2 - Clear list
; a5 - Balls
;-------------------------------------------------------------------------------
UpdateDrawGroup:
.ball:
		movem.l	(a5),d0-d4
		cmp.l	#BALLS_END,d0				; last item?
		beq	.done
		bsr	UpdateBall

		movem.l	(a5),d0-d2
		move.l	Ball_Col(a5),d3

		bsr	DrawBall

		lea	Ball_SIZEOF(a5),a5
		moveq	#1,d7
		bra	.ball
.done		rts


********************************************************************************
; Update position/velocity for a single ball
;-------------------------------------------------------------------------------
; d0 = x
; d1 = y
; d2 = r
; d3 = vx
; d4 = vy
;-------------------------------------------------------------------------------
UpdateBall:
		movem.l	d7/a1-a2/a4,-(sp)			; Only back up what we need

; Dumb global speed limit
		move.l	#SPEED_LIMIT,d5
		cmp.l	d5,d3
		ble	.vxOk
		move.l	d5,d3
.vxOk
		cmp.l	d5,d4
		ble	.vyOk
		move.l	d5,d4
.vyOk

; Friction
		asr.l	#8,d3
		muls	#FRICTION,d3
		asr.l	#8,d4
		muls	#FRICTION,d4

		; Add velocity to position
		add.l	d3,d0
		add.l	d4,d1
		bsr	CheckBoundsCirc
		; Update props
		movem.l	d0-d4,(a5)

		bsr	CheckCollisions
		movem.l	(sp)+,d7/a1-a2/a4
		rts


********************************************************************************
; Transform and draw ball with blit or plot routine
;-------------------------------------------------------------------------------
; d0 = x
; d1 = y
; d2 = r
; d3 = colour bpl offset
; a1 - Draw buffer
; a2 - Clear list
;-------------------------------------------------------------------------------
DrawBall:

; Apply pan
		add.l	PanX(pc),d0
		add.l	PanY(pc),d1
; Apply zoom:
		move.w	Zoom(pc),d6
		move.w	#8+TRANSFORM_ACC,d5
		; scale r
		asl.l	#TRANSFORM_ACC,d2
		swap	d2
		mulu	d6,d2
		asr.l	d5,d2
		;  scale x
		asl.l	#TRANSFORM_ACC,d0
		swap	d0
		muls	d6,d0
		asr.l	d5,d0
		add.l	TranslateX(pc),d0
		; scale y
		asl.l	#TRANSFORM_ACC,d1
		swap	d1
		muls	d6,d1
		asr.l	d5,d1
		add.l	TranslateY(pc),d1

		move.w	ScaleR(pc),d6
		beq	.noScale
		mulu	d6,d2
		asr.l	#5,d2
.noScale

		jmp	DrawCircle
.skip		rts


********************************************************************************
; Check collisons with other balls
;-------------------------------------------------------------------------------
; d0 = x
; d1 = y
; d2 = r
; d3 = vx
; d4 = vy
; a5 = ptr to current ball
;-------------------------------------------------------------------------------
CheckCollisions:
		move.l	a5,a4					; a4 = target (other ball to compare)
		swap	d2
		move.w	d2,d7
		subq	#1,d7					; d7 = r
		move.l	#BALLS_END,d6				; magic number for end of array
.next:
		lea	Ball_SIZEOF(a4),a4
		move.l	Ball_X(a4),d2
		cmp.l	d6,d2					; last item?
		bne	.notLast
		rts						; exit
.notLast

		move.w	Ball_R(a4),d4
		add.w	d7,d4					; d4 = maxDist = r1+r2

		; Check rect bounds first:
		sub.l	d0,d2					; d2 = dx
		move.l	d2,a0					; a0 = dx (backup before swap)
		swap	d2
		cmp.w	d4,d2
		bgt.b	.next
		move.l	Ball_Y(a4),d5
		sub.l	d1,d5					; d5 = dy
		move.l	d5,a1					; a1 = dy
		swap	d5
		cmp.w	d4,d5
		bgt.b	.next
		neg.w	d4
		cmp.w	d4,d2
		blt.b	.next
		cmp.w	d4,d5
		blt.b	.next
		neg.w	d4

		; Check distance^2:
		move.w	d4,a2					; a2 = maxDist
		mulu	d4,d4					; d4 = maxDist^2 = (r1+r2)^2
		muls	d2,d2
		muls	d5,d5
		add.l	d5,d2					; d2 = dist^2 = dx^2+dy^2
		bne.b	.notZero				; min value to protect against divide by zero
		moveq	#1,d2
.notZero
		; Hit if dist^2 < maxDist^2:
		cmp.l	d4,d2
		bge.b	.next
; Hit!:
		; Get actual dist using sqrt lookup
		lea	SqrtTab,a3
		move.b	(a3,d2.w),d2				; d2 = dist
		and.w	#$ff,d2
		; Fix overlap:
		move.w	a2,d5
		sub.w	d2,d5					; d5 = (maxDist - dist) / 2 = overlap (FP)
		swap	d5
		clr.w	d5
		asr.l	#1+COL_OVERLAP_ACC,d5			; /2 and shift more to avoid signed overflow

		divu	d2,d5					;  / dist
		; adjust x
		move.l	a0,d3
		swap	d3
		muls	d5,d3
		asl.l	#COL_OVERLAP_ACC,d3

		sub.l	d3,Ball_X(a5)
		add.l	d3,Ball_X(a4)
		;add.l	d3,a0					; adjust dx
		; adjust Y
		move.l	a1,d3
		swap	d3
		muls	d5,d3
		asl.l	#COL_OVERLAP_ACC,d3
		sub.l	d3,Ball_Y(a5)
		add.l	d3,Ball_Y(a4)

		; use maxDist as d
		; stops velocities spiraling upwards
		move.l	a2,d2

		; Update velocities:
		; normal vector n
		move.l	a0,d3					; d3 = nx = dx/d
		asr.l	#COL_NORM_ACC,d3			; >>2 to prevent overflow
		divs	d2,d3
		ext.l	d3
		move.l	a1,d4					; d4 = ny = dy/d
		asr.l	#COL_NORM_ACC,d4
		divs	d2,d4
		add.l	d2,d2
		; velocity vector k
		move.l	Ball_VX(a5),d2				; d2 = kx = b1.vx-b2.vx
		sub.l	Ball_VX(a4),d2
		move.l	Ball_VY(a5),d5				; d2 = ky = b1.vy-b2.vy
		sub.l	Ball_VY(a4),d5
		; p = 2 * (nx * kx + ny * ky) / (b1.m + b2.m);
		lsl.l	#COL_NORM_ACC,d2			; keep some extra bits for better accuracy
		swap	d2
		muls	d3,d2					; d2 = nx * kx
		lsl.l	#COL_NORM_ACC,d5
		swap	d5
		muls	d4,d5					; d5 = ny * ky
		add.l	d5,d2
		add.l	d2,d2					; d2 = 2 * (nx * kx + ny * ky)
		move.w	d7,d5					; d5 = b1.m + b2.m (use radius as mass)
		add.w	Ball_R(a4),d5
		divs	d5,d2					; d2 = p
		; update vx
		move.w	d2,d5					; px = p * nx
		muls	d3,d5
		swap	d5
		move.w	d5,d3
		muls	Ball_R(a4),d3				; b1.vx -= px * b2.m;
		lsl.l	#COL_NORM_ACC,d3			; correct shifts in nx/ny and kx/ky
		sub.l	d3,Ball_VX(a5)
		muls	Ball_R(a5),d5				; b2.vx += px * b1.m;
		lsl.l	#COL_NORM_ACC,d5
		add.l	d5,Ball_VX(a4)
		; update vy
		muls	d4,d2					; py = p * ny
		swap	d2
		move.w	d2,d4
		muls	Ball_R(a4),d4				; b1.vy -= py * b1.m;
		lsl.l	#COL_NORM_ACC,d4
		sub.l	d4,Ball_VY(a5)
		muls	Ball_R(a5),d2				; b2.vy += py * b1.m;
		lsl.l	#COL_NORM_ACC,d2
		add.l	d2,Ball_VY(a4)
		bra	.next


********************************************************************************
; Check bounds: circle
;-------------------------------------------------------------------------------
CheckBoundsCirc:
.doCheck
		; maxDist
		; +2 improves accuracy - TODO: investigate
		move.l	#(BOUNDS_R+2)<<16,a3			; a3 = maxDist = cR - r
		sub.l	d2,a3
		; dist^2
		move.l	d0,d5
		move.l	d1,d6
		swap	d5
		swap	d6
		muls	d5,d5
		muls	d6,d6
		add.l	d5,d6					; d6 = dist^2
		; maxDist^2
		move.l	a3,d5
		swap	d5
		mulu	d5,d5					; d5 = maxDist^2

		; Outside circle?
		cmp.w	d5,d6
		blt	.inside
		lea	SqrtTab,a4
		move.b	(a4,d6.w),d6				; d6 = dist
		and.w	#$ff,d6

		; Normal
		move.l	d0,d5					; d5 = nx = dx / dist
		asr.l	#BOUNDS_NORM_ACC,d5			; prevent overflow
		divs	d6,d5
		move.l	d1,d2					; d2 = ny = dy / dist
		asr.l	#BOUNDS_NORM_ACC,d2			; prevent overflow
		divs	d6,d2
		; need to restore d2

		; move back to collision point
		move.l	a3,d0					; x = nx * maxDist;
		swap	d0
		muls	d5,d0
		lsl.l	#BOUNDS_NORM_ACC,d0
		move.l	a3,d1					; y = ny * maxDist;
		swap	d1
		muls	d2,d1
		lsl.l	#BOUNDS_NORM_ACC,d1

		; reflect velocity vector on tangent: 𝑟=𝑑−2(𝑑⋅𝑛)𝑛
		neg.w	d2					; d2.w = -ny  (FP>>2)
		asl.l	#BOUNDS_REFLECT_ACC,d3			; d3.w = vx (<<ACC)
		swap	d3
		muls	d2,d3					; d3.l = vx*-ny (FP)
		asl.l	#BOUNDS_REFLECT_ACC,d4
		swap	d4
		muls	d5,d4					; d4.l = vy*nx (FP)
		add.l	d3,d4					; d4 = dp2 = (vx*-ny + vy*nx) * 2
		add.l	d4,d4

		lsl.l	#8,d4
		swap	d4					; d4.w = dp2 (<<ACC)
		move.w	d4,d3					; vx = -ny*dp2 - vx;
		muls	d2,d3
		asr.l	#8,d3
		asr.l	#8-BOUNDS_REFLECT_ACC,d3
		sub.l	Ball_VX(a5),d3

		muls	d5,d4					; vy = nx*dp2 - vy;
		asr.l	#8,d4
		asr.l	#8-BOUNDS_REFLECT_ACC,d4
		sub.l	Ball_VY(a5),d4

		move.l	Ball_R(a5),d2
.inside
		rts

********************************************************************************
Vars:
********************************************************************************

StartFrame:	dc.l	0
CurrFrame:	dc.l	0

; Balls:
Step:		dc.w	START_STEP

LerpPos		dc.w	0

Transform:
PanX:		dc.l	0
PanY:		dc.l	0
Zoom:		dc.w	0					; $100 = 100%
TranslateX:	dc.l	0
TranslateY:	dc.l	0
ScaleR:		dc.w	0

VxDelta:	dc.l	0
VyDelta:	dc.l	0

ContainerX:	dc.l	0
ContainerY:	dc.l	0

Group1:		dc.l	Balls
Group2:		dc.l	Balls2

********************************************************************************
* Data
********************************************************************************

; To get a constant zoom speed we need a logarithmic curve
; LUT to convert linear values generated by logSteps.js
; TODO: change to deltas - can be bytes (or packed?)
;LogSteps:	dc.w	$100,$102,$104,$106,$108,$10b,$10d,$10f,$111,$113,$116,$118,$11a,$11d,$11f,$121,$124,$126,$128,$12b,$12d,$130,$132,$135,$137,$13a,$13c,$13f,$141,$144,$147,$149,$14c,$14f,$151,$154,$157,$15a,$15d,$15f,$162,$165,$168,$16b,$16e,$171,$174,$177,$17a,$17d,$180,$183,$187,$18a,$18d,$190,$193,$197,$19a,$19d,$1a1,$1a4,$1a8,$1ab,$1af,$1b2,$1b6,$1b9,$1bd,$1c0,$1c4,$1c8,$1cb,$1cf,$1d3,$1d7,$1db,$1de,$1e2,$1e6,$1ea,$1ee,$1f2,$1f6,$1fa,$1ff,$203,$207,$20b,$20f,$214,$218,$21c,$221,$225,$22a,$22e,$233,$237,$23c,$241,$245,$24a,$24f,$254,$259,$25e,$262,$267,$26c,$272,$277,$27c,$281,$286,$28b,$291,$296,$29c,$2a1,$2a6,$2ac,$2b2,$2b7,$2bd,$2c3,$2c8,$2ce,$2d4,$2da,$2e0,$2e6,$2ec,$2f2,$2f8,$2fe,$305,$30b,$311,$318,$31e,$325,$32b,$332,$338,$33f,$346,$34d,$354,$35b,$362,$369,$370,$377,$37e,$386,$38d,$394,$39c,$3a3,$3ab,$3b3,$3ba,$3c2,$3ca,$3d2,$3da,$3e2,$3ea,$3f2,$3fa,$403,$40b,$413,$41c,$425,$42d,$436,$43f,$448,$450,$459,$463,$46c,$475,$47e,$488,$491,$49b,$4a4,$4ae,$4b8,$4c2,$4cb,$4d5,$4e0,$4ea,$4f4,$4fe,$509,$513,$51e,$529,$533,$53e,$549,$554,$55f,$56b,$576,$581,$58d,$598,$5a4,$5b0,$5bc,$5c8,$5d4,$5e0,$5ec,$5f8,$605,$611,$61e,$62b,$638,$645,$652,$65f,$66c,$67a,$687,$695,$6a3,$6b0,$6be,$6cd,$6db,$6e9,$6f7,$706,$715,$723,$732,$741,$751,$760,$76f,$77f,$78e,$79e,$7ae,$7be,$7ce,$7df,$7ef,$800
LogDeltas:	dc.b	2,21,3,41,4,30,5,23,6,20,7,17,8,15,9,12,10,11,11,10,12,10,13,9,14,7,15,7,16,6,17,1
LogDeltasE
ColorStep:	dc.w	3

COLOR_STEPS = 6

		dc.w	$efc					; e4ffcf
		dc.w	$369					; 3f6c99
Colors:
		dc.w	$147					; 114579
		dc.w	$2ab
		dc.w	$6ee
		dc.w	$b2a					; ae229f
		dc.w	$747					; f28fe7
		dc.w	$ffa					; faffcf
		dc.w	$ffd					; eeff60
		dc.w	$f95					; ff9d55
		dc.w	$f65					; ff6655
		dc.w	$bda					; bdd3ab
		dc.w	$efc					; e4ffcf
		dc.w	$369					; 3f6c99
; repeat
		dc.w	$147					; 114579
		dc.w	$2ab
		dc.w	$6ee


*******************************************************************************
		bss
*******************************************************************************

Balls:		ds.b	Ball_SIZEOF*MAX_BALLS+4
Balls2:		ds.b	Ball_SIZEOF*MAX_BALLS+4
LogSteps: 	ds.b	514