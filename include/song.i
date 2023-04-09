
ENABLE_CH0 = 1
ENABLE_CH1 = 1
ENABLE_CH2 = 1
ENABLE_CH3 = 1

; Values based on powers of two
CHORD_SPEED = 7
PAT_SPEED = 2
CHORD_POW = 5
PAT_POW = 3
ORD_POW = 5

;-------------------------------------------------------------------------------
MusicData:

Chords:
		; Chord progression used to transpose note values

		dc.b	6-1,4-1,1-1,5-1
		dc.b	6-1,4-1,1-1,5-1
		dc.b	6-1,8-1,7-1,5-1
		dc.b	6-1,4-1,1-1,1-1
		dc.b	6-1,4-1,1-1,5-1
		dc.b	6-1,8-1,7-1,5-1
		dc.b	6-1,8-1,10-1,7-1
		dc.b	6-1,4-1,1-1,1-1
Periods:
		dc.w	0
		; Only need to store the period values for the key and range we're using
		;dc.w 214*2,190*2,170*2,160*2,143*2
		dc.w	127*4,113*4
		dc.w	214*2,190*2,170*2,160*2,143*2,127*2,113*2
		dc.w	214*1,190*1,170*1,160*1,143*1,127*1,113*1
		even
Patterns:
		dc.b	0,0,0,0,0,0,0,0				; 0: off
		dc.b	1,0,3,1,3,0,0,1				; 1: Dramtic saw
		dc.b	1,0,0,1,0,0,1,0				; 2: Bass std
		dc.b	1,0,5,1,1,3,5,0				; 3: Sin 1 A
		dc.b	1,0,5,1,5,3,5,3				; 4: Sin 1 B
		dc.b	1,5,1,0,1,3,1,3				; 5: Sin 2
		dc.b	1,0,0,3,0,0,3,0				; 6: Bas alt

		dc.b	1,0,5,1,1,0,0,0				; 7: Sin 1 C
Order:
		; Bass
		dc.b	2,2,2,2,2,2,2,6,2,2,2,6,2,2,2,6,2,2,2,6,2,2,2,6,2,2,2,6,2,2,2,6
		; Sin 1
		dc.b	0,3,3,3,3,3,3,4,3,3,3,4,3,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		; Dramtic saw!
		dc.b	0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		; Sin 2
		dc.b	0,5,5,5,5,5,5,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
Instruments:
		rsreset
Inst_Duration	rs.b	1
Inst_Octave	rs.b	1
Inst_Wave	rs.b	1
Inst_SIZEOF	rs.b	0
		dc.b	2,4,0
		dc.b	4,1,1
		dc.b	5,3,0
		dc.b	5,0,1
Waves:
		rsreset
Wave_Adr	rs.l	1
Wave_Len	rs.w	1
Wave_SIZEOF	rs.b	0
		dc.l	SquareWave
		dc.w	4
		dc.l	SinWave
		dc.w	8
		; dc.l	NoiseWave
		; dc.w	1024/4

		printt	MusicData
		printv	*-MusicData
