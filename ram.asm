;===================================================================================================

SRAMBASE = $B16000

;===================================================================================================
; Direct page
;===================================================================================================
base $7E0000
	SCRATCH: skip 16
	SAFESCRATCH: skip 4
	NMISCRATCH: skip 4

	NMIWAIT: skip 2
	FRAME: skip 2

	; NMI vectors
	NMIVX: skip 2
	NMIVSC: skip 2

	; NMI Queues
	INIDQ: skip 1

	TMQ: skip 1
	TSQ: skip 1

	BG1SCQ: skip 1
	BG2SCQ: skip 1

	BG1HOFF: skip 2
	BG1VOFF: skip 2
	BG2HOFF: skip 2
	BG2VOFF: skip 2
	BG3HOFF: skip 2
	BG3VOFF: skip 2

	CGWSELQ: skip 1
	CGADSUBQ: skip 1
	FIXCOL: skip 2

	; Controller data
	; JOYA: BYsSUDLR
	; JOYB: AXlr
	JOY1:
	JOY1B: skip 1
	JOY1A: skip 1

	JOY1NEW:
	JOY1BNEW: skip 1
	JOY1ANEW: skip 1

	LEVEL: skip 1

	; number of 2s/3s left to find
	GOODLEFT: skip 2

	FLIPPED: skip 1
	GREAT: skip 1

	COINS: skip 2
	COINSDISP: skip 2
	CURSOR: skip 1
	CURX: skip 1
	CURY: skip 1
	CURTILE: skip 1
	CURPROP: skip 1
	CURSX: skip 1

	MEMOING: skip 1

	SEEDX: skip 2
	SEEDY: skip 2
	SEEDZ: skip 2

	VWFL: skip 2 ; letter
	VWFD: skip 2 ; pixel count for drawing
	VWFP: skip 2 ; pixel count for next letter
	VWFX: skip 2 ; index into buffer
	VWFS: skip 2 ; amount to shift
	VWFM: skip 2 ; mask for letters
	VWFV: skip 2 ; VRAM target

	VWF1A: skip 2 ; letters we shift
	VWF1B: skip 2 ; letters we shift
	VWF2A: skip 2 ; letters we shift
	VWF2B: skip 2 ; letters we shift
	VWFMSA: skip 2 ; mask for letters after shifting
	VWFMSB: skip 2 ; mask for letters after shifting

	DPEND:
warnpc $7E0100

;===================================================================================================
; Mirrored WRAM
;===================================================================================================
base $7E0100
	; u... tttt
	;   u - update during nmi
	;   t - tile to show
	TILEDISP: skip 25

	; u... nnnn
	;   u - update during nmi
	;   n - notes
	TILEMEMO: skip 25

	; s... ..vv
	;   s - show
	;   v - value
	TILEVAL: skip 25

	; .vvv ssss
	;   s - row total
	;   v - voltorb count
	HINTSR: skip 5

	; .vvv ssss
	;   s - column total
	;   v - voltorb count
	HINTSC: skip 5

	ROWFLIPS: skip 5
	COLFLIPS: skip 5

	COINCHARS0: skip 16
	COINCHARS1: skip 16
	COINCHARS2: skip 16

	skip 8

	EXPLSX: skip 2

	EXPLOSIONOAM: skip 16

	DUMB: skip 8

	BCDNUMS: skip 16

	TOTALTILESA: skip 32
	TOTALTILESB: skip 32

	BRDUPDATEX: skip 2

;---------------------------------------------------------------------------------------------------

base $7E0800
	SMIRROR:

	CKSM1: skip 2
	CKSM2: skip 2

	BBBB: skip 4

	; coins	won
	WINNINGS: skip 8

	; games played ever
	GAMES: skip 8

	; games won
	WINS: skip 8

	; games lost
	LOST: skip 8

	; games quit
	QUIT: skip 8

	; tiles of X type flipped
	FLIPPED1: skip 8
	FLIPPED2: skip 8
	FLIPPED3: skip 8

	; longest win streak
	STREAK: skip 8

	; coins lost to voltorb
	COINSLOST: skip 8

	; not sure yet
	MAXLEVEL: skip 1

	RISKYMOVES: skip 8

base $7E0880
	CURSTREAK: skip 8

;---------------------------------------------------------------------------------------------------

base $7E0B00
	VWFB1: skip $1A0 ; VFW character buffer
	VWFB2: skip $1A0

base $7E1000
	PAUSEMAP: skip $0800
	HINTSBUFFER: skip $0100



NMIVTop = $7E1EFE


BOARDUPDATES = $7E2000



;===================================================================================================

base off
