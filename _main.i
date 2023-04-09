	incdir	"include"
	include	"hw.i"
	include	"debug.i"
	include	"macros.i"

	xdef	_start

	xref	SwapBuffers
	xref	Clear
	xref	LerpPal
	xref	LerpCol
	xref	Random32
	xref	WaitEOF
	xref	BlitCircle
	xref	DrawCircle
	xref	CopCircle
	xref	Plot

	xref	VBlank
	xref	DrawBuffer
	xref	DrawClearList

	xref	Sin
	xref	SqrtTab
	xref	DivTab
	xref	ValueNoise
	xref	LogSteps
	xref	Pal0
	xref	Pal1
	xref	Pal2
	xref	Pal3

; Maximum radius for blitter circles
; Need to adjust BltCircBpl size when you change this
BLTCIRC_MAX_R = 90

; Copper rendered circles:
COPCIRC_MIN_R = 1						; Minimum radius. This saves a bit of space in offsets data
COPCIRC_MAX_R = 208						; Maximum radius
COPCIRC_PAD = 32
COPCIRC_BW = (COPCIRC_MAX_R*2+COPCIRC_PAD)/8			; Byte width of triangles bpl
COPCIRC_INST_SZ = 12						; Size of copper instruction for a single line
COPCIRC_INST_MAX = COPCIRC_MAX_R*2				; Maximum number of instructions

; Display window:
DIW_W = 320
DIW_H = 256
BPLS = 5

; Screen buffer:
SCREEN_W = DIW_W+16
SCREEN_H = DIW_H

;-------------------------------------------------------------------------------
; Derived

COLORS = 1<<BPLS

SCREEN_BW = SCREEN_W/8						; byte-width of 1 bitplane line
SCREEN_BPL = SCREEN_BW*SCREEN_H					; bitplane offset (non-interleaved)
SCREEN_SIZE = SCREEN_BW*SCREEN_H*(BPLS-1)			; byte size of screen buffer

DIW_BW = DIW_W/8
DIW_MOD = SCREEN_BW-DIW_BW-2
DIW_XSTRT = ($242-DIW_W)/2
DIW_YSTRT = ($158-DIW_H)/2
DIW_XSTOP = DIW_XSTRT+DIW_W
DIW_YSTOP = DIW_YSTRT+DIW_H