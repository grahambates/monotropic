WAIT_BLIT	macro
		tst.w	(a6)					;for compatibility with A1000
.\@:		btst	#6,2(a6)
		bne.s	.\@
		endm
