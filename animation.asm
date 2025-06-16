;===================================================================================================

RaiseCoins:
	SEP #$38

.do_high_digits
	LDA.b COINSDISP+1
	CMP.b COINS+1
	BCS .start_tens

	ADC.b #$01
	STA.b COINSDISP+1
	CMP.b COINS+1
	BCC .still_doing_high_digits

	LDA.b COINS+0
	SBC.b #$40
	BCS .set_low_digits

	LDA.b COINS+0
	AND.b #$0F
	SBC.b #$04
	BCS .set_low_digits

	LDA.b #$00
	BRA .set_low_digits

.still_doing_high_digits
	LDA.b COINSDISP+0
	ADC.b #$27

.set_low_digits
	STA.b COINSDISP+0

	JSR .frame
	BRA .do_high_digits

;---------------------------------------------------------------------------------------------------

.start_tens
	LDA.b COINSDISP+0
	CMP.b COINS+0
	BEQ .done

.do_tens
	LDA.b COINSDISP+0
	EOR.b COINS+0
	AND.b #$F0
	BEQ .do_ones

	LDA.b COINSDISP+0
	CLC
	ADC.b #$10
	AND.b #$F0
	STA.b SCRATCH

	EOR.b COINS+0
	AND.b #$F0
	BNE .still_doing_tens

	LDA.b COINS+0
	AND.b #$0F
	SEC
	SBC.b #$04
	BCS .set_ones

	LDA.b #$00
	BRA .set_ones

.still_doing_tens
	LDA.b COINSDISP+0
	ADC.b #$05

.set_ones
	AND.b #$0F
	ORA.b SCRATCH
	STA.b COINSDISP+0

	JSR .frame
	BRA .do_tens

;---------------------------------------------------------------------------------------------------

.do_ones
	LDA.b COINSDISP+0
	EOR.b COINS+0
	AND.b #$0F
	BEQ .done

	LDA.b COINSDISP+0
	CLC
	ADC.b #$01
	STA.b COINSDISP+0

	JSR .frame
	BRA .do_ones

;---------------------------------------------------------------------------------------------------

.done
	REP #$28

	LDA.b COINS
	STA.b COINSDISP

	JSR DrawCoins
	JMP WaitForNMI

;---------------------------------------------------------------------------------------------------

.frame
	CLD

	JSR DrawCoins

	SEP #$38
	JMP WaitForNMI

;===================================================================================================

DrawCoins:
	REP #$29
	SEP #$10

	; get ones and hundreds
	LDA.b COINSDISP
	ASL
	ASL
	ASL
	ASL
	PHA

	; ones
	LDY.b #12
	JSR .add_char

	; tens
	LDA.b COINSDISP
	LDY.b #8
	JSR .add_char

	; hundreds
	PLA
	XBA
	LDY.b #4
	JSR .add_char

	; thousands
	LDA.b COINSDISP+1
	LDY.b #0
	JSR .add_char

	LDA.w #NMIVector(NMI_UpdateCoinDisplay)
	JSR AddNMIVector

	RTS

;---------------------------------------------------------------------------------------------------

.add_char
	AND.w #$00F0
	TAX

	LDA.w .chars+00,X
	STA.w COINCHARS0+0,Y
	LDA.w .chars+02,X
	STA.w COINCHARS0+2,Y

	LDA.w .chars+04,X
	STA.w COINCHARS1+0,Y
	LDA.w .chars+06,X
	STA.w COINCHARS1+2,Y

	LDA.w .chars+08,X
	STA.w COINCHARS2+0,Y
	LDA.w .chars+10,X
	STA.w COINCHARS2+2,Y

	RTS

.chars
	dw $08C0, $48C0, $08C1, $48C1, $88C0, $C8C0, $0000, $0000 ; 0
	dw $08C2, $08C3, $08C4, $08C5, $08C6, $48C6, $0000, $0000 ; 1
	dw $08C0, $48C0, $08C7, $C8C0, $08C8, $08C9, $0000, $0000 ; 2
	dw $08C0, $48C0, $08D0, $08D1, $88C0, $C8C0, $0000, $0000 ; 3
	dw $08D2, $08D2, $08C8, $08D3, $0800, $88D2, $0000, $0000 ; 4
	dw $88C8, $08C9, $08D4, $48C0, $88C0, $C8C0, $0000, $0000 ; 5
	dw $08C0, $48C0, $48D3, $48C7, $88C0, $C8C0, $0000, $0000 ; 6
	dw $88C8, $C8C8, $08D5, $08D6, $08D7, $08D8, $0000, $0000 ; 7
	dw $08C0, $48C0, $48D1, $08D1, $88C0, $C8C0, $0000, $0000 ; 8
	dw $08C0, $48C0, $88C7, $08D3, $88C0, $C8C0, $0000, $0000 ; 9

;===================================================================================================

DeleteExplosions:
	REP #$20

	LDA.w #$E0E0
	STA.w EXPLOSIONOAM+0

	JSR Clear3ExplosionSprites_loaded

	LDA.b #$55
	STA.b EXPLSX

	REP #$20

	LDA.w #NMIVector(NMI_DrawExplosion)
	JSR AddVectorAndWaitForNMI

	SEP #$30

	RTS

;===================================================================================================

Clear3ExplosionSprites:
	REP #$20

	LDA.w #$E0E0

Clear3ExplosionSprites_loaded:
	STA.w EXPLOSIONOAM+4
	STA.w EXPLOSIONOAM+8
	STA.w EXPLOSIONOAM+12

	SEP #$20
	RTS

;===================================================================================================

; Enters with:
; A = character
PositionBigMirroredExplosion:
	STA.w EXPLOSIONOAM+2
	STA.w EXPLOSIONOAM+6
	STA.w EXPLOSIONOAM+10
	STA.w EXPLOSIONOAM+14

	LDA.b #$32
	STA.w EXPLOSIONOAM+3

	LDA.b #$72
	STA.w EXPLOSIONOAM+7

	LDA.b #$B2
	STA.w EXPLOSIONOAM+11

	LDA.b #$F2
	STA.w EXPLOSIONOAM+15

	BRA PositionBigExplosion

;===================================================================================================

PositionGiantExplosion:
	STA.w EXPLOSIONOAM+2

	CLC
	ADC.b #$04
	STA.w EXPLOSIONOAM+6

	CLC
	ADC.b #$3C
	STA.w EXPLOSIONOAM+10

	CLC
	ADC.b #$04
	STA.w EXPLOSIONOAM+14

	LDA.b #$33
	STA.w EXPLOSIONOAM+3
	STA.w EXPLOSIONOAM+7
	STA.w EXPLOSIONOAM+11
	STA.w EXPLOSIONOAM+15

;===================================================================================================

PositionBigExplosion:
	LDA.b #$AA
	STA.w EXPLSX

	LDA.b CURX
	SEC
	SBC.b #16
	STA.w EXPLOSIONOAM+0
	STA.w EXPLOSIONOAM+8

	; should only be possible for the left side to be offscreen on the X axis
	BCS .on_screen

	LDY.b #$BB
	STY.w EXPLSX

.on_screen
	CLC
	ADC.b #32
	STA.w EXPLOSIONOAM+4
	STA.w EXPLOSIONOAM+12

	LDA.b CURY
	SEC
	SBC.b #16
	STA.w EXPLOSIONOAM+1
	STA.w EXPLOSIONOAM+5

	CLC
	ADC.b #32
	STA.w EXPLOSIONOAM+9
	STA.w EXPLOSIONOAM+13

;===================================================================================================

AnimateExplosion:
	REP #$20

	LDA.w #NMIVector(NMI_DrawExplosion)
	JSR AddNMIVector

	SEP #$30

	LDX.b #$08
	JMP WaitForNMI_x_times

;===================================================================================================

RevealLevel:
	JSR BrightNoBG3

	JSR RevealEveryTile

	SEP #$10

	LDX.b #10
	JSR WaitForNMI_x_times

	JSR WaitForInput

	JSR ResetBoard

;===================================================================================================

DisableCursor:
	REP #$20

	LDA.w #NMIVector(NMI_DrawGameCursor)
	JSR AddNMIVector

	SEP #$20

;===================================================================================================

HideCursor:
	LDA.b #$01
	STA.b CURSX

	LDA.b #$20
	STA.b CURX

	LDA.b #$E1
	STA.b CURY

	RTS

;===================================================================================================

PositionCursor:
	SEP #$20

	LDA.b CURSOR
	BMI HideCursor

	JSR GetCursorOAMCoordinates

	LDA.b #$40

	LDX.b MEMOING
	BEQ .not_memo

	LDA.b #$44

.not_memo
	STA.b CURTILE

	LDA.b #$30
	STA.b CURPROP

	LDA.b #$02
	STA.b CURSX

	RTS

;===================================================================================================

CreateHints:
	REP #$30

	LDX.w #TILEVAL
	STX.b SCRATCH

	STZ.w HINTSR+0
	STZ.w HINTSR+1
	STZ.w HINTSR+2
	STZ.w HINTSC+0
	STZ.w HINTSC+2
	STZ.w HINTSC+3

	SEP #$30

	LDX.b #$00

.next_row
	LDY.b #$00

.next_column
	LDA.b (SCRATCH)
	INC.b SCRATCH

	AND.b #$03
	BNE .not_voltorb

	LDA.b #$10

.not_voltorb
	STA.b SCRATCH+2

	CLC
	ADC.w HINTSC,Y
	STA.w HINTSC,Y

	LDA.b SCRATCH+2
	CLC
	ADC.w HINTSR,X
	STA.w HINTSR,X

	INY
	CPY.b #5
	BCC .next_column

	INX
	CPX.b #5
	BCC .next_row

;===================================================================================================

CreateHintsBuffer:
	REP #$20

	LDX.b #$00
	TXY
	BRA .start

.next_hint_set
	TYA
	ADC.w #$0010
	TAY

	INX

.start
	PHX

	TXA
	ASL
	TAX

	; set up VRAM addresses
	LDA.w .vram_addresses,X
	STA.w HINTSBUFFER+$0000,Y

	INC
	STA.w HINTSBUFFER+$0004,Y

	CLC
	ADC.w #vma($0040)
	STA.w HINTSBUFFER+$0008,Y

	ADC.w #vma($0040)
	STA.w HINTSBUFFER+$000C,Y

	PLX

	; voltorb numbers
	LDA.w HINTSR,X
	AND.w #$0070
	LSR
	LSR
	LSR
	LSR
	ORA.w #$0460
	STA.w HINTSBUFFER+$000A,Y

	ORA.w #$0010
	STA.w HINTSBUFFER+$000E,Y

	; coin numbers
	LDA.w HINTSR,X
	AND.w #$000F
	CMP.w #10
	BCC .under_10

	SBC.w #10

.under_10
	ORA.w #$0450
	STA.w HINTSBUFFER+$0006,Y

	; if <10, carry clear for 0; otherwise set for 1
	LDA.w #$0450
	ADC.w #$0000
	STA.w HINTSBUFFER+$0002,Y

	CPY.b #$90
	BCC .next_hint_set

	LDA.w #NMIVector(NMI_WriteVoltorbHints)
	JSR AddNMIVector

	SEP #$30
	RTS

;---------------------------------------------------------------------------------------------------

.vram_addresses
	dw vma(!ROW1HINTAT+2)
	dw vma(!ROW2HINTAT+2)
	dw vma(!ROW3HINTAT+2)
	dw vma(!ROW4HINTAT+2)
	dw vma(!ROW5HINTAT+2)

	dw vma(!COL1HINTAT+2)
	dw vma(!COL2HINTAT+2)
	dw vma(!COL3HINTAT+2)
	dw vma(!COL4HINTAT+2)
	dw vma(!COL5HINTAT+2)

;===================================================================================================

TransferTilesAndWaitForNMI_flipping:
	LDA.b #$04
	BRA TransferTilesAndWaitForNMI

;---------------------------------------------------------------------------------------------------

TransferTilesAndWaitForNMI_wait2:
	LDA.b #$02
	BRA TransferTilesAndWaitForNMI

;---------------------------------------------------------------------------------------------------

TransferTilesAndWaitForNMI_wait1:
	LDA.b #$01

;---------------------------------------------------------------------------------------------------

TransferTilesAndWaitForNMI:
	PHP

	REP #$20

	AND.w #$00FF
	PHA

	LDA.w #NMIVector(NMI_DrawGameCursor)
	JSR AddNMIVector

	JSR PerformTileUpdates

	PLA
	TAX
	JSR WaitForNMI_x_times

	PLP
	RTS

;===================================================================================================

RevealEveryTile:
	SEP #$30

	JSR TransferTilesAndWaitForNMI_wait2

	LDX.b #24
	LDA.b #$80

.next_tile_a
	STA.w TILEMEMO,X

	DEX
	BPL .next_tile_a

	JSR TransferTilesAndWaitForNMI_wait1

	LDA.b #$81
	JSR .reveal_step

	LDA.b #$82
	JSR .reveal_step

	LDX.b #24

.next_tile_d
	LDA.w TILEVAL,X
	BMI .skip_d

	ORA.b #$88
	STA.w TILEDISP,X

.skip_d
	DEX
	BPL .next_tile_d

	JSR TransferTilesAndWaitForNMI_flipping

	LDX.b #24

.next_tile_e
	LDA.w TILEVAL,X
	BMI .skip_e

	ORA.b #$80
	STA.w TILEVAL,X

	ORA.b #$0C
	STA.w TILEDISP,X

.skip_e
	DEX
	BPL .next_tile_e

	JMP TransferTilesAndWaitForNMI_flipping

;---------------------------------------------------------------------------------------------------

.reveal_step
	LDX.b #24

.next_reveal
	BIT.w TILEVAL,X
	BMI .skip_this

	STA.w TILEDISP,X

.skip_this
	DEX
	BPL .next_reveal

	JMP TransferTilesAndWaitForNMI_flipping

;===================================================================================================

ResetBoard:
	SEP #$30

	LDX.b #$00
	JSR HideColumn

	LDX.b #$01
	JSR HideColumn

	LDX.b #$02
	JSR HideColumn

	LDX.b #$03
	JSR HideColumn

	LDX.b #$04
	JSR HideColumn

;===================================================================================================

ResetHints:
	REP #$20

	STZ.w HINTSR+0
	STZ.w HINTSR+2
	STZ.w HINTSR+3
	STZ.w HINTSC+0
	STZ.w HINTSC+2
	STZ.w HINTSC+3

	JMP CreateHintsBuffer

;===================================================================================================

HideColumn:
	STX.b SAFESCRATCH

	LDY.b #5

.next_row_d
	LDA.w TILEVAL,X
	ORA.b #$88
	STA.w TILEDISP,X

	TXA
	CLC
	ADC.b #5
	TAX
	DEY
	BNE .next_row_d

	JSR TransferTilesAndWaitForNMI_flipping

	LDA.b #$82
	JSR .one_column

	LDA.b #$81
	JSR .one_column

	LDA.b #$80

;---------------------------------------------------------------------------------------------------

.one_column
	LDX.b SAFESCRATCH

	STA.w TILEDISP+00,X
	STA.w TILEDISP+05,X
	STA.w TILEDISP+10,X
	STA.w TILEDISP+15,X
	STA.w TILEDISP+20,X

	JMP TransferTilesAndWaitForNMI_flipping

;===================================================================================================

DrawTotalCoins:
	SEP #$10
	REP #$20

	LDX.b #$20

.next_clear
	STZ.w TOTALTILESA-2,X
	STZ.w TOTALTILESB-2,X

	DEX
	DEX
	BNE .next_clear

	LDA.w #WINNINGS
	JSR SplitBCD

.next_draw
	LDA.w BCDNUMS,X
	AND.w #$000F
	ORA.w #$24E0
	STA.w TOTALTILESA,Y

	ORA.w #$0010
	STA.w TOTALTILESB,Y

	INY
	INY
	INX
	CPX.b #16
	BCC .next_draw

	LDA.w #NMIVector(NMI_DrawTotalCoins)
	JSR AddNMIVector

	RTS

;===================================================================================================

PerformTileUpdates:
	REP #$30

	LDY.w #24
	LDX.w #0
	STX.w BRDUPDATEX

.next_box
	SEP #$20

	LDA.w TILEDISP,Y
	BMI .yes_change

	JMP .no_tile_change

.yes_change
	STA.b SCRATCH

	AND.b #$0F
	STA.w TILEDISP,Y

	REP #$20

	PHY
	AND.w #$00FF
	ASL
	TAY
	LDA.w .tile_pointers,Y
	TAY

	LDA.w $0000,Y
	STA.l BOARDUPDATES+$02,X
	LDA.w $0002,Y
	STA.l BOARDUPDATES+$06,X
	LDA.w $0004,Y
	STA.l BOARDUPDATES+$0A,X

	LDA.w $0006,Y
	STA.l BOARDUPDATES+$0E,X
	LDA.w $0008,Y
	STA.l BOARDUPDATES+$12,X
	LDA.w $000A,Y
	STA.l BOARDUPDATES+$16,X

	LDA.w $000C,Y
	STA.l BOARDUPDATES+$1A,X
	LDA.w $000E,Y
	STA.l BOARDUPDATES+$1E,X
	LDA.w $0010,Y
	STA.l BOARDUPDATES+$22,X

	LDA 1,S
	ASL
	TAY

	LDA.w DrawAtOffset,Y
	ADC.w #vma(!BOARDMAP)
	STA.l BOARDUPDATES+$00,X
	INC
	STA.l BOARDUPDATES+$04,X
	INC
	STA.l BOARDUPDATES+$08,X

	ADC.w #$001E
	STA.l BOARDUPDATES+$0C,X
	INC
	STA.l BOARDUPDATES+$10,X
	INC
	STA.l BOARDUPDATES+$14,X

	ADC.w #$001E
	STA.l BOARDUPDATES+$18,X
	INC
	STA.l BOARDUPDATES+$1C,X
	INC
	STA.l BOARDUPDATES+$20,X

	PLY

	TXA
	CLC
	ADC.w #36
	TAX

	SEP #$20

.no_tile_change
	LDA.w TILEMEMO,Y
	BPL .no_note_change

	AND.b #$0F
	STA.w TILEMEMO,Y
	STA.b SCRATCH

	REP #$30

	PHY

	TYA
	ASL
	TAY

	LDA.w DrawAtOffset,Y
	ADC.w #vma(!NOTESMAP)
	STA.l BOARDUPDATES+$00,X
	ADC.w #$0002
	STA.l BOARDUPDATES+$04,X
	ADC.w #$003E
	STA.l BOARDUPDATES+$08,X
	ADC.w #$0002
	STA.l BOARDUPDATES+$0C,X

	LDA.w #$0000
	LSR.b SCRATCH
	BCC .no_voltorb_note

	LDA.w #$2508

.no_voltorb_note
	STA.l BOARDUPDATES+$02,X

	LDA.w #$0000
	LSR.b SCRATCH
	BCC .no_1_note

	LDA.w #$2509

.no_1_note
	STA.l BOARDUPDATES+$06,X

	LDA.w #$0000
	LSR.b SCRATCH
	BCC .no_2_note

	LDA.w #$2518

.no_2_note
	STA.l BOARDUPDATES+$0A,X

	LDA.w #$0000
	LSR.b SCRATCH
	BCC .no_3_note

	LDA.w #$2519

.no_3_note
	STA.l BOARDUPDATES+$0E,X

	PLY

	TXA
	CLC
	ADC.w #16
	TAX

.no_note_change
	DEY
	BMI .done

	JMP .next_box

;---------------------------------------------------------------------------------------------------

.done
	STX.w BRDUPDATEX

	REP #$30

	LDA.w #NMIVector(NMI_TransferTileQueue)
	JSR AddNMIVector

	RTS

;---------------------------------------------------------------------------------------------------

.tile_pointers
	dw EmptyTile  ; 00
	dw FlipATile  ; 01
	dw FlipBTile  ; 02
	dw EmptyTile  ; 03
	dw EmptyTile  ; 04
	dw EmptyTile  ; 05
	dw EmptyTile  ; 06
	dw EmptyTile  ; 07
	dw FlipVTile  ; 08
	dw Flip1Tile  ; 09
	dw Flip2Tile  ; 0A
	dw Flip3Tile  ; 0B
	dw ScoreVTile ; 0C
	dw Score1Tile ; 0D
	dw Score2Tile ; 0E
	dw Score3Tile ; 0F

;===================================================================================================

EmptyTile:
	dw $040A, $040B, $440A
	dw $040C, $040D, $440C
	dw $840A, $840B, $C40A

FlipATile:
	dw $041A, $041B, $041C
	dw $042A, $042B, $042C
	dw $841A, $841B, $841C

FlipBTile:
	dw $041D, $041E, $441D
	dw $042D, $042E, $442D
	dw $841D, $841E, $C41D

FlipVTile:
	dw $086A, $086E, $086F
	dw $087A, $087E, $087F
	dw $886A, $088E, $886F

Flip1Tile:
	dw $086A, $086B, $086F
	dw $087A, $087B, $087F
	dw $886A, $088B, $886F

Flip2Tile:
	dw $086A, $086C, $086F
	dw $087A, $087C, $087F
	dw $886A, $088C, $886F

Flip3Tile:
	dw $086A, $086D, $086F
	dw $087A, $087D, $087F
	dw $886A, $088D, $886F

Score1Tile:
	dw $083A, $083B, $483A
	dw $084A, $084B, $484A
	dw $883A, $085B, $C83A

Score2Tile:
	dw $083A, $083C, $483A
	dw $084A, $084C, $484A
	dw $883A, $085C, $C83A

Score3Tile:
	dw $083A, $083D, $483A
	dw $084A, $084D, $484A
	dw $883A, $085D, $C83A

ScoreVTile:
	dw $083E, $083F, $483E
	dw $084E, $084F, $484E
	dw $085E, $085F, $485E

;===================================================================================================

function bta(r,c) = vma($84+($100*r+$08*c))

DrawAtOffset:
	dw bta(0, 0), bta(0, 1), bta(0, 2), bta(0, 3), bta(0, 4)
	dw bta(1, 0), bta(1, 1), bta(1, 2), bta(1, 3), bta(1, 4)
	dw bta(2, 0), bta(2, 1), bta(2, 2), bta(2, 3), bta(2, 4)
	dw bta(3, 0), bta(3, 1), bta(3, 2), bta(3, 3), bta(3, 4)
	dw bta(4, 0), bta(4, 1), bta(4, 2), bta(4, 3), bta(4, 4)

;===================================================================================================
