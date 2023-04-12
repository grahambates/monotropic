		include	"_main.i"
		include	"music.i"

********************************************************************************
Music_Init:
		lea	Instruments+Inst_Wave(pc),a0
		lea	aud0lch(a6),a1
		lea	Waves(pc),a2
		moveq	#0,d0
		moveq	#4-1,d7
.chan:
		move.b	(a0),d0
		mulu	#Wave_SIZEOF,d0
		lea	(a2,d0.w),a3
		move.l	(a3)+,(a1)+				; aud0lch
		move.w	(a3)+,(a1)				; aud0len
		lea	12(a1),a1
		lea	Inst_SIZEOF(a0),a0
		dbf	d7,.chan
; Only enable DMA for the first two channels for now
		move.w	#DMAF_SETCLR!ENABLE_CH0!(ENABLE_CH1<<1)!(ENABLE_CH2<<2)!(ENABLE_CH3<<3)!DMAF_MASTER,dmacon(a6)
		rts


********************************************************************************
Music_Play:
		move.l	VBlank,d5
		lea	aud0per(a6),a0
		lea	MusicData,a1
		lea	Order(pc),a2
		lea	Instruments(pc),a3
		lea	Music_Levels,a5

		move.w	d5,d6					; d6 = chord index
		lsr.w	#CHORD_SPEED,d6
		and.w	#CHORD_LEN-1,d6
		move.b	Chords-MusicData(a1,d6.w),d6		; d6 = chord value (transpose)

		moveq	#0,d4					; clear upper bytes
		moveq	#4-1,d7					; iterate channels/instruments
.chan:
		moveq	#0,d0					; d0 = volume (default off)
		moveq	#0,d1					; d1 = period
; Get indexes:
		move.w	d5,d2					; d2 = index in pattern
		move.b	Inst_Duration(a3),d4
		lsr.w	d4,d2

		; Get note:
		lsr.w	#PAT_SPEED,d2			; d2 = note index (global)
		move.w	d2,d1				; d1 = pattern index (note index / notes in pattern)
		lsr.w	#PAT_POW,d1
		and.w	#ORD_LEN-1,d1
		and.w	#PAT_LEN-1,d2
		; Get pattern:
		move.b	(a2,d1.w),d1				; d1 = pattern number from order
		lsl.w	#PAT_POW,d1				; * pattern length to get byte offset
		lea	Patterns-MusicData(a1,d1.w),a4		; a4 = current pattern
		; Find note in pattern
		move.b	(a4,d2.w),d1				; d1 = note value
		; Skip to volume if note==0 (off)
		beq.s	.setVol

		; Lookup and set period for note value
		and.w	#$ff,d1					; mask byte value
		add.w	d6,d1					; Transpose note value to apply chord
		add.w	d1,d1					; x2 for word offset
		move.w	Periods-MusicData(a1,d1.w),d1		; d1 = period for note
		move.b	Inst_Octave(a3),d2
		lsl.w	d2,d1					; shift for octave

		moveq	#64,d0					; volume on

		; Find position within note
		; We trimmed of Inst_Duration+PAT_SPEED bits - see if these were all zero
		moveq	#-1,d3
		add.w	#PAT_SPEED,d4
		lsl.w	d4,d3
		not.w	d3
		and.w	d5,d3
		beq	.setVol					; zero is start of note

.notePlaying
		; Apply volume envelope:
		; d3 ranges from 0 to 1<<d4
		lsl.w	#6,d3					; *64
		asr.w	d4,d3					; shift back
		; d3 is now 0-64
		sub.w	d3,d0					; subtract from max volume

.setVol
		move.w	d1,(a0)					; set audxper
		move.w	d0,2(a0)				; set audxvol
		move.w	d0,(a5)+
		lea	16(a0),a0				; next chan registers
		lea	ORD_LEN(a2),a2
		lea	Inst_SIZEOF(a3),a3
		dbf	d7,.chan
		rts

; Derived lengths
CHORD_LEN = 1<<CHORD_POW
PAT_LEN = 1<<PAT_POW
ORD_LEN = 1<<ORD_POW

		include	"song.i"

*******************************************************************************
		data_c
*******************************************************************************

SquareWave:
		dc.b	127,127,127,127,-127,-127,-127,-127

SinWave:
		dc.b	0,49,90,117,127,117,90,49,0,-49,-90,-117,-127,-117,-90,-49


*******************************************************************************
		bss
*******************************************************************************

Music_Levels:
		ds.w 4