StartTheGame:
	PHB
	PHK
	PLB

	LDA.w #NMI_DeletePressStart
	JSL AddNMIVector

	LDA.w #NMI_DrawVoltorbIcons
	JSL AddNMIVector

	LDA.w #NMI_WriteLevelAndControls
	JSL AddNMIVector

	JSR BrightNoBG3
	JSL WaitForNMI

	LDA.w #NMI_CreateTextBox
	JSL AddNMIVector

	SEP #$20
	LDA.b #$01
	STA.b LEVEL

;===================================================================================================

NewLevel:
	REP #$20
	SEP #$10

	LDA.w #$1FFF
	TCS

	JSR DrawTotalCoins

	JSR BuildLevel

--	JSR ControlCursor
	JSR TransferTilesAndWaitForNMI_wait1

	BRA	--

;===================================================================================================

RaiseCoins:
	SEP #$30

	LDX.b #$00

.find_first_diff
	LDA.b COINSDISP,X
	CMP.b COINSDEC,X
	BNE .next_spin

	INX
	CPX.b #4
	BCC .find_first_diff

.next_spin
	TXY

	INX
.randomize_smaller_digits
	CPX.b #4
	BCS .done_random

	JSL Random

	STA.w PPUMULT16
	STZ.w PPUMULT16

	LDA.b #10
	STA.w PPUMULT8

	LDA.w MPYM
	STA.b COINSDISP,X

	INX
	BRA .randomize_smaller_digits

.done_random
	TYX
	LDA.b COINSDISP,X
	INC
	CMP.b #10
	BCC .fine

	LDA.b #0

.fine
	STA.b COINSDISP,X

	PHX
	PHA
	PHP

	JSR DrawCoins
	JSL WaitForNMI

	PLP
	PLA
	PLX

	CMP.b COINSDEC,X
	BNE .next_spin

	INX
	CPX.b #4
	BCC .next_spin

	RTS

;===================================================================================================

DrawCoins:
	REP #$21
	SEP #$10

	; thousands
	LDX.b COINSDISP+0

	LDA.w .chars,X
	AND.w #$00FF
	ORA.w #$0800
	STA.w COINCHARS0+0
	INC
	STA.w COINCHARS0+2

	ADC.w #$000F
	STA.w COINCHARS1+0
	INC
	STA.w COINCHARS1+2

	ADC.w #$000F
	STA.w COINCHARS2+0
	INC
	STA.w COINCHARS2+2

	; hundreds
	LDX.b COINSDISP+1

	LDA.w .chars,X
	AND.w #$00FF
	ORA.w #$0800
	STA.w COINCHARS0+4
	INC
	STA.w COINCHARS0+6

	ADC.w #$000F
	STA.w COINCHARS1+4
	INC
	STA.w COINCHARS1+6

	ADC.w #$000F
	STA.w COINCHARS2+4
	INC
	STA.w COINCHARS2+6

	; tens
	LDX.b COINSDISP+2

	LDA.w .chars,X
	AND.w #$00FF
	ORA.w #$0800
	STA.w COINCHARS0+8
	INC
	STA.w COINCHARS0+10

	ADC.w #$000F
	STA.w COINCHARS1+8
	INC
	STA.w COINCHARS1+10

	ADC.w #$000F
	STA.w COINCHARS2+8
	INC
	STA.w COINCHARS2+10

	; ones
	LDX.b COINSDISP+3

	LDA.w .chars,X
	AND.w #$00FF
	ORA.w #$0800
	STA.w COINCHARS0+12
	INC
	STA.w COINCHARS0+14

	ADC.w #$000F
	STA.w COINCHARS1+12
	INC
	STA.w COINCHARS1+14

	ADC.w #$000F
	STA.w COINCHARS2+12
	INC
	STA.w COINCHARS2+14

	LDA.w #NMI_UpdateCoinDisplay
	JSL AddNMIVector

	RTS

.chars
	db $80, $82, $84, $86, $88
	db $B0, $B2, $B4, $B6, $B8

;===================================================================================================

GetCoinsDecimal:
	REP #$20
	SEP #$10

	LDX.b #10

	LDA.b COINS
	STA.w CPUDIVIDEND
	STX.w CPUDIVISOR

	JSL WaitForDivision

	LDY.w CPUREMAINDER
	STY.w COINSDEC+3

	LDA.w CPUQUOTIENT
	STA.w CPUDIVIDEND
	STX.w CPUDIVISOR

	JSL WaitForDivision

	LDY.w CPUREMAINDER
	STY.w COINSDEC+2

	LDA.w CPUQUOTIENT
	STA.w CPUDIVIDEND
	STX.w CPUDIVISOR

	JSL WaitForDivision

	LDY.w CPUREMAINDER
	STY.w COINSDEC+1

	LDA.w CPUQUOTIENT
	STA.w CPUDIVIDEND
	STX.w CPUDIVISOR

	JSL WaitForDivision

	LDY.w CPUREMAINDER
	STY.w COINSDEC+0

	RTS

;===================================================================================================

CalculateCoins:
	AND.b #$03
	ASL
	TAX

	REP #$20

	LDA.b COINS

	JMP (.vectors,X)

.vectors
	dw GameOver
	dw .get1
	dw .get2
	dw .get3

;---------------------------------------------------------------------------------------------------

.get1
	BNE ++

	INC
	STA.b COINS

++	LDX.b #FLIPPED1
	JSR IncrementGameCounter

.add_flip
	SEP #$20

	INC.b FLIPPED

	RTS

;---------------------------------------------------------------------------------------------------

.get2
	BNE ++

	INC

++	ASL

.got2
	STA.b COINS

	LDX.b #FLIPPED2
	JSR IncrementGameCounter

	BRA .got2or3

;---------------------------------------------------------------------------------------------------

.get3
	BNE ++

	LDA.w #$0003
	BRA .got3

++	ASL
	ADC.b COINS

.got3
	STA.b COINS

	LDX.b #FLIPPED3
	JSR IncrementGameCounter

.got2or3
	LDA.b GOODLEFT ; -1 GOODLEFT +1 (from carry) GOODGOT
	ADC.w #$00FF
	STA.b GOODLEFT

	BRA .add_flip

;===================================================================================================

Clear3ExplosionSprites:
	REP #$20

	LDA.w #$E0E0
	STA.w EXPLOSIONOAM+4
	STA.w EXPLOSIONOAM+8
	STA.w EXPLOSIONOAM+12

	SEP #$20
	RTS

;===================================================================================================

GameOver:
	SEP #$30

	LDX.b #LOST
	JSR IncrementGameCounter

	LDA.b #$32 ; same props for first steps
	STA.w EXPLOSIONOAM+3
	STA.w EXPLOSIONOAM+7
	STA.w EXPLOSIONOAM+11
	STA.w EXPLOSIONOAM+15

	; step 0
	JSR Clear3ExplosionSprites

	LDA.b CURX
	CLC
	ADC.b #$08
	STA.w EXPLOSIONOAM+0

	LDA.b CURY
	CLC
	ADC.b #$08
	STA.w EXPLOSIONOAM+1

	LDA.b #$48
	STA.w EXPLOSIONOAM+2

	LDA.b #$54
	STA.w EXPLSX

	JSR AnimateExplosion

	; step 1
	LDA.b CURX
	CLC
	ADC.b #$04
	STA.w EXPLOSIONOAM+0

	LDA.b CURY
	CLC
	ADC.b #$04
	STA.w EXPLOSIONOAM+1

	LDA.b #$4A
	STA.w EXPLOSIONOAM+2

	LDA.b #$56
	STA.w EXPLSX

	JSR AnimateExplosion

	; step 2
	LDA.b #$80
	JSR PositionBigMirroredExplosion

	; step 3
	LDA.b #$84
	JSR PositionBigMirroredExplosion

	; step 4
	LDA.b #$00
	JSR PositionGiantExplosion

	; step 5
	LDA.b #$08
	JSR PositionGiantExplosion

	; step 6
	LDA.b #$80
	JSR PositionGiantExplosion

	; finished
	JSR DeleteExplosions

	REP #$20

	LDA.w #OhNo
	JSR DisplayTextBox

	LDX.b #COINSLOST
	JSR AddCoinsToCounter

	STZ.w COINSDISP+0
	STZ.w COINSDISP+2
	JSR DrawCoins

	LDA.w #$1717
	STA.b TMQ

	LDX.b #120
	JSL WaitForNMI_x_times

;---------------------------------------------------------------------------------------------------

LevelLost:
	REP #$20

	STZ.w CURSTREAK+0
	STZ.w CURSTREAK+2
	STZ.w CURSTREAK+4
	STZ.w CURSTREAK+6

	JSR RevealLevel

	SEP #$30

	STZ.b GREAT

	LDA.b GOODGOT
	BNE ++

	INC

++	CMP.b LEVEL
	BCS .no_demotion

	STA.b LEVEL

	REP #$20

	LDA.w #NMI_WriteLevelNumber
	JSL AddNMIVector

	LDA.w #Dropped
	JSR DisplayDarkTextBoxForLong

.no_demotion
	JMP NewLevel

;===================================================================================================

DeleteExplosions:
	REP #$20

	LDA.w #$E0E0
	STA.w EXPLOSIONOAM+0

	JSR Clear3ExplosionSprites

	LDA.b #$55
	STA.b EXPLSX

	REP #$20

	LDA.w #NMI_DrawExplosion
	JSL AddNMIVector

	SEP #$30

	JSL WaitForNMI

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
	BCS ++

	LDY.b #$BB
	STY.w EXPLSX

++	CLC
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

	LDA.w #NMI_DrawExplosion
	JSL AddNMIVector

	SEP #$30

	LDX.b #$08
	JSL WaitForNMI_x_times

	RTS

;===================================================================================================

ControlCursor:
	SEP #$30

	LDA.b JOY1ANEW
	BIT.b #$20
	BNE .pressed_select

	BIT.b #$10
	BEQ .no_pause

.pressed_start
	JSR PrepareHelpBox

	BRA .wait_for_unpause

.pressed_select
	JSR PrepareStatsBox

.wait_for_unpause
	SEP #$30

	JSR DisableCursor

	LDX.b #20
	JSL WaitForNMI_x_times

	LDA.b #$C0
.looping
	JSL WaitForNMI

	BIT.b JOY1ANEW
	BNE .unpause

	BIT.b JOY1BNEW
	BEQ .looping

.unpause
	REP #$20

	STZ.b BG3HOFF

	JSR BrightNoBG3

	SEP #$20

	LDX.b #20
	JSL WaitForNMI_x_times

	RTS

;---------------------------------------------------------------------------------------------------

.no_pause
	; includes a 2 frame cooldown for exiting notes, unless you move
	LDA.b MEMOING
	BEQ ++

	DEC.b MEMOING

++	LDA.b JOY1B
	BIT.b #$20
	BEQ .no_l_press

	LDA.b MEMOING
	BNE .already_in_notes

	; clear buttons on first frame so there's no accidents
	LDA.b #$C0
	TRB.b JOY1ANEW
	TRB.b JOY1BNEW
	BRA .already_in_notes

.no_l_press
	LDA.b JOY1ANEW
	AND.b #$0F
	BNE .moving_with_no_l_press
	BRA .not_moving

.already_in_notes
	LDA.b #$03
	STA.b MEMOING

	LDA.b JOY1ANEW
	AND.b #$0F
	BNE .moving

;---------------------------------------------------------------------------------------------------

.not_moving
	JSR PositionCursor

	LDA.b MEMOING
	BEQ .not_notes

	LDX.b CURSOR
	LDA.w TILEVAL,X
	BMI .no_notes ; nothing to do if tile is revealed

	LDA.b #$C0
	BIT.b JOY1ANEW
	BNE .do_notes

	BIT.b JOY1BNEW
	BEQ .no_notes

.do_notes
	LDA.w TILEMEMO,X
	ORA.b #$80

	; B for voltorb
	BIT.b JOY1ANEW
	BPL ++
	EOR.b #$01

	; Y for 1
++	BVC ++
	EOR.b #$02

	; A for 3
++	BIT.b JOY1BNEW
	BPL ++
	EOR.b #$08

	; X for 2
++	BVC ++
	EOR.b #$04

++	STA.w TILEMEMO,X

.no_notes
	RTS

;---------------------------------------------------------------------------------------------------

.not_notes
	LDX.b CURSOR

	LDA.w TILEVAL,X
	BMI .cant_flip

	BIT.b JOY1BNEW
	BMI .flipping

.cant_flip
	BIT.b JOY1ANEW
	BMI ManuallyEndLevel

	RTS

;---------------------------------------------------------------------------------------------------

.flipping
	JSR FlipTile

	LDX.b CURSOR
	LDA.w TILEVAL,X

	JSR CalculateCoins

	SEP #$30

	LDA.b #$04
	JSR PositionBigMirroredExplosion

	LDA.b #$08
	JSR PositionBigMirroredExplosion

	LDA.b #$0C
	JSR PositionBigMirroredExplosion

	JSR DeleteExplosions

	JSR GetCoinsDecimal
	JSR RaiseCoins

	SEP #$30

	LDA.b GOODLEFT
	BEQ LevelCleared

	RTS

;---------------------------------------------------------------------------------------------------

.moving_with_no_l_press
	STZ.b MEMOING

.moving
	JSR GetCursorRowColumn

	LDA.b JOY1ANEW
	AND.b #$03
	TAX
	LDY.b #$00
	JSR ApplyMovementToCoordinate

	LDA.b JOY1ANEW
	AND.b #$0C
	LSR
	LSR
	TAX
	INY
	JSR ApplyMovementToCoordinate

	LDX.b SCRATCH+1
	LDA.w RowOffsets,X
	CLC
	ADC.b SCRATCH+0

	STA.b CURSOR

	RTS

;===================================================================================================

ManuallyEndLevel:
	JSR DisableCursor

	REP #$20

	LDA.w #Forfeit
	JSR DisplayDarkTextBox

	LDX.b #5
	JSL WaitForNMI_x_times

.loop
	LDX.b JOY1ANEW
	BMI .continue_playing

	LDX.b JOY1BNEW
	BMI .end

	JSL WaitForNMI
	BRA .loop

;---------------------------------------------------------------------------------------------------

.end
	LDX.b #WINNINGS
	JSR AddCoinsToCounter

	LDX.b #QUIT
	JSR IncrementGameCounter

	JMP LevelLost

;---------------------------------------------------------------------------------------------------

.continue_playing
	JSR BrightNoBG3

	LDX.b #20
	JSL WaitForNMI_x_times

	RTS

;===================================================================================================

LevelCleared:
	REP #$20

	LDA.w #Win
	JSR DisplayDarkTextBoxForLong

	SEP #$30

	LDX.b #WINNINGS
	JSR AddCoinsToCounter

	LDX.b #WINS
	JSR IncrementGameCounter

	LDX.b #CURSTREAK
	JSR IncrementGameCounter

	LDA.b LEVEL
	CMP.w MAXLEVEL
	BCC ++

	STA.w MAXLEVEL

++	REP #$20

	LDA.w CURSTREAK+0
	CMP.w STREAK+0
	BCC .no_new_streak
	BEQ .check_streak_b
	BCS .new_streak

.check_streak_b
	LDA.w CURSTREAK+2
	CMP.w STREAK+2
	BCC .no_new_streak
	BEQ .check_streak_c
	BCS .new_streak

.check_streak_c
	LDA.w CURSTREAK+4
	CMP.w STREAK+4
	BCC .no_new_streak
	BEQ .check_streak_d
	BCS .new_streak

.check_streak_d
	LDA.w CURSTREAK+6
	CMP.w STREAK+6
	BCC .no_new_streak

.new_streak
	LDA.w CURSTREAK+0
	STA.w STREAK+0

	LDA.w CURSTREAK+2
	STA.w STREAK+2

	LDA.w CURSTREAK+4
	STA.w STREAK+4

	LDA.w CURSTREAK+6
	STA.w STREAK+6

;---------------------------------------------------------------------------------------------------

.no_new_streak
	JSR RevealLevel

	SEP #$20

	STZ.b SCRATCH ; track level change

	LDA.b LEVEL
	CMP.b #8
	BCS .done_level

	LDA.b FLIPPED
	CMP.b #8
	BCC .not_great

	INC.b GREAT

	LDA.b GREAT
	CMP.b #5
	BCC .not_great_enough

	LDA.b #8
	BRA .advance_level

.not_great
	STZ.b GREAT

.not_great_enough
	LDA.b LEVEL
	CMP.b #7
	BCS .done_level

	INC

.advance_level
	STA.b SCRATCH
	STA.b LEVEL

.done_level
	LDA.b SCRATCH
	BEQ .not_advancing

	REP #$20

	LDA.w #NMI_WriteLevelNumber
	JSL AddNMIVector

	LDA.w #Advanced
	JSR DisplayDarkTextBoxForLong

.not_advancing
	JMP NewLevel

;===================================================================================================

RevealLevel:
	SEP #$10

	LDX.b #GAMES
	JSR IncrementGameCounter

	JSR UpdateSRAM

	JSR BrightNoBG3

	JSR RevealEveryTile

	SEP #$10

	LDX.b #40
	JSL WaitForNMI_x_times

	JSR ResetBoard

	JSR CreateHints

	LDA.w #NMI_WriteVoltorbHints
	JSL AddNMIVector

	JMP DisableCursor

;===================================================================================================

DisplayDarkTextBoxForLong:
	JSR DisplayDarkTextBox

	SEP #$10

	LDX.b #120
	JSL WaitForNMI_x_times

	JMP BrightNoBG3

;===================================================================================================

DisplayDarkTextBox:
	PHA

	JSR DarkenGameBoard

	PLA

;===================================================================================================

DisplayTextBox:
	STA.b SAFESCRATCH

	PHP

	LDA.w #$1717
	STA.b TMQ

	JSL ResetVWF

	LDA.w #$7000>>1
	STA.b VWFV

	LDA.w #NMI_TransferTextChars
	JSL AddNMIVector
	JSL WaitForNMI

	LDA.w #3

.next_char
	JSL DrawOneCharFrame

	LDA.b (SAFESCRATCH)
	INC.b SAFESCRATCH

	AND.w #$00FF
	CMP.w #$0080
	BCC .next_char
	BEQ .draw_level

.done
	PLP
	RTS

.draw_level
	LDA.b LEVEL
	AND.w #$000F
	ADC.w #$0007

	BRA .next_char

;===================================================================================================

BrightNoBG3:
	PHP
	REP #$20

	LDA.w #$1313
	STA.b TMQ
	STZ.b CGWSELQ

	PLP
	RTS

;===================================================================================================

DarkenGameBoard:
	PHP
	REP #$20

	LDA.w #$E1E3
	STZ.b CGWSELQ
	STA.b CGADSUBQ

	PLP
	RTS

;===================================================================================================

PositionCursor:
	SEP #$20

	LDA.b CURSOR
	BMI HideCursor

	JSR GetCursorRowColumn

	LDA.b MEMOING
	CMP.b #$01

	LDA.b #$00
	ROL
	TAX

	LDA.w .tile,X
	STA.b CURTILE

	LDA.b #$30
	STA.b CURPROP

	LDA.b #$02
	STA.b CURSX

	RTS

.tile
	db $40
	db $44

;===================================================================================================

DisableCursor:
	REP #$20

	LDA.w #NMI_DrawGameCursor
	JSL AddNMIVector

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

GetCursorRowColumn:
	LDX.b CURSOR

	LDA.w .row_column,X
	AND.b #$07
	STA.b SCRATCH+0
	ASL
	ASL
	ASL
	ASL
	ASL
	ADC.b #12
	STA.b CURX

	LDA.w .row_column,X
	LSR
	LSR
	LSR
	LSR
	STA.b SCRATCH+1

	LDA.w .row_column,X
	AND.b #$70
	ASL
	ADC.b #12
	STA.b CURY

	RTS

.row_column
	db $00, $01, $02, $03, $04
	db $10, $11, $12, $13, $14
	db $20, $21, $22, $23, $24
	db $30, $31, $32, $33, $34
	db $40, $41, $42, $43, $44

;===================================================================================================

ApplyMovementToCoordinate:
	CLC
	LDA.w SCRATCH,Y
	ADC.w .movement,X
	CMP.b #$05 ; catches both negative values and >4
	BCS .exit

	STA.w SCRATCH,Y

.exit
	RTS

.movement
	db  0 ; 00
	db +1 ; 01
	db -1 ; 10
	db  0 ; 11

;===================================================================================================

CreateHints:
	SEP #$30

	LDX.b #0
	JSR GetRowHints

	LDX.b #1
	JSR GetRowHints

	LDX.b #2
	JSR GetRowHints

	LDX.b #3
	JSR GetRowHints

	LDX.b #4
	JSR GetRowHints

	LDX.b #0
	JSR GetColumnHints

	LDX.b #1
	JSR GetColumnHints

	LDX.b #2
	JSR GetColumnHints

	LDX.b #3
	JSR GetColumnHints

	LDX.b #4
	JSR GetColumnHints

	REP #$20

	LDA.w #NMI_WriteVoltorbHints
	JSL AddNMIVector

	RTS

;===================================================================================================
; Enters with
;   X = row
;===================================================================================================
GetRowHints:
	SEP #$30

	LDY.w RowOffsets,X
	TXA
	TYX

	; push offset into buffer
	ASL
	ASL
	PHA

	LDY.b #$05

	STZ.b SCRATCH
	STZ.b SCRATCH+2

.next
	LDA.w TILEVAL,X
	AND.b #$03
	BNE .not_voltorb

	INC.b SCRATCH+2

.not_voltorb
	CLC
	ADC.b SCRATCH
	STA.b SCRATCH

	INX
	DEY
	BNE .next

	BRA AddHintTilesToBuffer

;===================================================================================================

RowOffsets:
	db  0
	db  5
	db 10
	db 15
	db 20

;===================================================================================================
; Enters with
;   X = column
;===================================================================================================
GetColumnHints:
	SEP #$30

	TXA
	ASL
	ASL
	ADC.b #20
	PHA

	LDY.b #$05

	STZ.b SCRATCH
	STZ.b SCRATCH+2

.next
	LDA.w TILEVAL,X
	AND.b #$03
	BNE .not_voltorb

	INC.b SCRATCH+2

.not_voltorb
	CLC
	ADC.b SCRATCH
	STA.b SCRATCH

	TXA
	CLC
	ADC.b #$05
	TAX

	DEY
	BNE .next

	LDA.b SCRATCH

;===================================================================================================

AddHintTilesToBuffer:
	LDY.b #$00
	CMP.b #10
	BCC .less_than_10

	SBC.b #10
	INY

.less_than_10
	REP #$20

	PLX

	AND.w #$000F
	ORA.w #$0450
	STA.w HINTNUMTILES+2,X

	TYA
	ORA.w #$0450
	STA.w HINTNUMTILES+0,X

	TXA
	LSR
	TAX

	LDA.b SCRATCH+2
	AND.w #$000F
	ORA.w #$0460
	STA.w VOLTNUMTILES,X

	RTS

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
	TAX

	LDA.w #NMI_DrawGameCursor
	JSL AddNMIVector

	LDA.w #NMI_TransferTileQueue
	JSL AddNMIVector

	JSL WaitForNMI_x_times

	PLP
--	RTS

;===================================================================================================

FlipTile:
	LDX.b CURSOR
	LDA.w TILEVAL,X
	BMI --

	JSR TransferTilesAndWaitForNMI_wait2

	LDX.b CURSOR
	LDA.b #$80
	STA.w TILEMEMO,X

	JSR TransferTilesAndWaitForNMI_wait1

	LDX.b CURSOR
	LDA.b #$81
	STA.w TILEDISP,X

	JSR TransferTilesAndWaitForNMI_flipping

	LDX.b CURSOR
	LDA.b #$82
	STA.w TILEDISP,X

	JSR TransferTilesAndWaitForNMI_flipping

	LDX.b CURSOR

	LDA.w TILEVAL,X
	ORA.b #$80
	STA.w TILEVAL,X

	ORA.b #$08
	STA.w TILEDISP,X

	JSR TransferTilesAndWaitForNMI_flipping

	LDX.b CURSOR
	LDA.w TILEDISP,X
	ORA.b #$8C
	STA.w TILEDISP,X

	JMP TransferTilesAndWaitForNMI_flipping

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

	LDX.b #24
	LDA.b #$81

.next_tile_b
	LDY.w TILEVAL,X
	BMI .skip_b

	STA.w TILEDISP,X

.skip_b
	DEX
	BPL .next_tile_b

	JSR TransferTilesAndWaitForNMI_flipping

	LDX.b #24
	LDA.b #$82

.next_tile_c
	LDY.w TILEVAL,X
	BMI .skip_c

	STA.w TILEDISP,X

.skip_c
	DEX
	BPL .next_tile_c

	JSR TransferTilesAndWaitForNMI_flipping

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

	LDX.b SAFESCRATCH

	LDY.b #5

.next_row_c
	LDA.b #$82
	STA.w TILEDISP,X

	TXA
	CLC
	ADC.b #5
	TAX
	DEY
	BNE .next_row_c

	JSR TransferTilesAndWaitForNMI_flipping

	LDX.b SAFESCRATCH

	LDY.b #5

.next_row_b
	LDA.b #$81
	STA.w TILEDISP,X

	TXA
	CLC
	ADC.b #5
	TAX
	DEY
	BNE .next_row_b

	JSR TransferTilesAndWaitForNMI_flipping

	LDX.b SAFESCRATCH

	LDY.b #5

.next_row_a
	LDA.b #$80
	STA.w TILEDISP,X

	TXA
	CLC
	ADC.b #5
	TAX
	DEY
	BNE .next_row_a

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

ClearBoard:
	LDX.b #24

.next_clear
	STZ.w TILEDISP,X
	STZ.w TILEMEMO,X
	STZ.w TILEVAL,X

	DEX
	BPL .next_clear

	RTS

;===================================================================================================

BuildLevel:
	SEP #$30

	JSR ClearBoard

	; random number between 0 and 4
	JSL Random
	STA.w $4202

	LDA.b #$05
	STA.w $4203

	REP #$20

	LDA.b LEVEL
	ASL
	TAX

	LDA.w LevelDistributions-2,X
	STA.b SAFESCRATCH

	SEP #$20

	LDA.w $4217 ; CPUPRODUCT+1 for high byte
	ASL
	ASL
	TAY

	LDX.b #24

	; distribute 2s
	LDA.b (SAFESCRATCH),Y
	BEQ .no_twos

	STA.b SCRATCH

	LDA.b #$02

--	STA.w TILEVAL,X
	DEX
	DEC.b SCRATCH
	BNE --

.no_twos
	INY

	; distribute 3s
	LDA.b (SAFESCRATCH),Y
	BEQ .no_threes

	STA.b SCRATCH

	LDA.b #$03

--	STA.w TILEVAL,X
	DEX
	DEC.b SCRATCH
	BNE --

.no_threes
	INY

	; totals
	LDA.b (SAFESCRATCH),Y
	STA.b GOODLEFT
	STZ.b GOODGOT
	STZ.b FLIPPED

	INY

	; distribute voltorbs
	LDA.b (SAFESCRATCH),Y

--	STZ.w TILEVAL,X
	DEX
	DEC
	BNE --

	; fill with 1s
	LDA.b #$01

--	STA.w TILEVAL,X
	DEX
	BPL --

;---------------------------------------------------------------------------------------------------

	; Shuffle the board
	LDA.b #200
	STA.b SCRATCH

	STZ.b CURSOR

.next_swap
	JSR Random25
	TAX

	JSR Random25
	TAY

	LDA.w TILEVAL,X
	PHA

	LDA.w TILEVAL,Y
	STA.w TILEVAL,X

	PLA
	STA.w TILEVAL,Y

	DEC.b SCRATCH
	BNE .next_swap

;---------------------------------------------------------------------------------------------------

	REP #$20

	STZ.b COINS
	STZ.b COINSDISP+0
	STZ.b COINSDISP+2
	STZ.b COINSDEC+0
	STZ.b COINSDEC+2

	JSR DrawCoins

	JSR CreateHints

	REP #$20

	LDA.w #NMI_WriteLevelNumber
	JSL AddNMIVector

	RTS

;===================================================================================================

Random25:
	JSL Random

	STA.w PPUMULT16
	STZ.w PPUMULT16

	LDA.b #25
	STA.w PPUMULT8

	LDA.w MPYM

	RTS

;===================================================================================================

LevelDistributions:
	dw .level1
	dw .level2
	dw .level3
	dw .level4
	dw .level5
	dw .level6
	dw .level7
	dw .level8

	; 2s, 3s, total, voltorbs
.level1
	db  3,  1,  4,  6
	db  0,  3,  3,  6
	db  5,  0,  5,  6
	db  2,  2,  4,  6
	db  4,  1,  5,  6

.level2
	db  1,  3,  4,  7
	db  6,  0,  6,  7
	db  3,  2,  5,  7
	db  0,  4,  4,  7
	db  5,  1,  6,  7

.level3
	db  2,  3,  5,  8
	db  7,  0,  7,  8
	db  4,  2,  6,  8
	db  1,  4,  5,  8
	db  6,  1,  7,  8

.level4
	db  3,  3,  6,  8
	db  0,  5,  5,  8
	db  8,  0,  8, 10
	db  5,  2,  7, 10
	db  2,  4,  6, 10

.level5
	db  7,  1,  8, 10
	db  4,  3,  7, 10
	db  1,  5,  6, 10
	db  9,  0,  9, 10
	db  6,  2,  8, 10

.level6
	db  3,  4,  7, 10
	db  0,  6,  6, 10
	db  8,  1,  9, 10
	db  5,  3,  8, 10
	db  2,  5,  7, 10

.level7
	db  7,  2,  9, 10
	db  4,  4,  8, 10
	db  1,  6,  7, 13
	db  9,  1, 10, 13
	db  6,  3,  9, 10

.level8
	db  0,  7,  7, 10
	db  8,  2, 10, 10
	db  5,  4,  9, 10
	db  2,  6,  8, 10
	db  7,  3, 10, 10

;===================================================================================================

BaseTileMap:
	dw $0407, $0409, $0409, $0409, $0409, $0409, $0409, $0409
	dw $0409, $0409, $0409, $0409, $0409, $0409, $0409, $0409
	dw $0409, $0409, $0409, $0409, $0409, $0409, $0409, $0409
	dw $0409, $0409, $0409, $0409, $0409, $0409, $0409, $4407

	dw $0408, $0410, $0416, $0416, $0416, $0413, $0416, $0416
	dw $0416, $0413, $0416, $0416, $0416, $0413, $0416, $0416
	dw $0416, $0413, $0416, $0416, $0416, $0413, $0416, $0416
	dw $0416, $4410, $0400, $0400, $0400, $0400, $0400, $4408

	; First voltorb row
	dw $0408, $0417, $040A, $040B, $440A, $0419, $040A, $040B
	dw $440A, $0419, $040A, $040B, $440A, $0419, $040A, $040B
	dw $440A, $0419, $040A, $040B, $440A, $0419, $0430, $0430
	dw $0430, $4417, $0400, $0400, $0400, $0400, $0400, $4408

	dw $0408, $0417, $040C, $040D, $440C, $0420, $040C, $040D
	dw $440C, $0420, $040C, $040D, $440C, $0420, $040C, $040D
	dw $440C, $0420, $040C, $040D, $440C, $0420, $0440, $0440
	dw $0440, $4417, $0400, $0400, $0400, $0400, $0400, $4408

	dw $0408, $0417, $840A, $840B, $C40A, $0419, $840A, $840B
	dw $C40A, $0419, $840A, $840B, $C40A, $0419, $840A, $840B
	dw $C40A, $0419, $840A, $840B, $C40A, $0419, $0430, $0430
	dw $0430, $4417, $0400, $0400, $0400, $0400, $0400, $4408

	dw $0408, $0411, $0418, $0425, $0418, $0415, $0418, $0426
	dw $0418, $0415, $0418, $0427, $0418, $0415, $0418, $0428
	dw $0418, $0415, $0418, $0429, $0418, $0415, $0418, $0418
	dw $0418, $4411, $0400, $0400, $0400, $0400, $0400, $4408

	; Second voltorb row
	dw $0408, $0417, $040A, $040B, $440A, $0419, $040A, $040B
	dw $440A, $0419, $040A, $040B, $440A, $0419, $040A, $040B
	dw $440A, $0419, $040A, $040B, $440A, $0419, $0431, $0431
	dw $0431, $4417, $0400, $0400, $0400, $0400, $0400, $4408

	dw $0408, $0417, $040C, $040D, $440C, $0421, $040C, $040D
	dw $440C, $0421, $040C, $040D, $440C, $0421, $040C, $040D
	dw $440C, $0421, $040C, $040D, $440C, $0421, $0441, $0441
	dw $0441, $4417, $0400, $0400, $0400, $0400, $0400, $4408

	dw $0408, $0417, $840A, $840B, $C40A, $0419, $840A, $840B
	dw $C40A, $0419, $840A, $840B, $C40A, $0419, $840A, $840B
	dw $C40A, $0419, $840A, $840B, $C40A, $0419, $0431, $0431
	dw $0431, $4417, $0400, $0400, $0400, $0400, $0400, $4408

	dw $0408, $0411, $0418, $0425, $0418, $0415, $0418, $0426
	dw $0418, $0415, $0418, $0427, $0418, $0415, $0418, $0428
	dw $0418, $0415, $0418, $0429, $0418, $0415, $0418, $0418
	dw $0418, $4411, $0400, $0400, $0400, $0400, $0400, $4408

	; Third voltorb row
	dw $0408, $0417, $040A, $040B, $440A, $0419, $040A, $040B
	dw $440A, $0419, $040A, $040B, $440A, $0419, $040A, $040B
	dw $440A, $0419, $040A, $040B, $440A, $0419, $0432, $0432
	dw $0432, $4417, $0400, $0400, $0400, $0400, $0400, $4408

	dw $0408, $0417, $040C, $040D, $440C, $0422, $040C, $040D
	dw $440C, $0422, $040C, $040D, $440C, $0422, $040C, $040D
	dw $440C, $0422, $040C, $040D, $440C, $0422, $0442, $0442
	dw $0442, $4417, $0400, $0400, $0400, $0400, $0400, $4408

	dw $0408, $0417, $840A, $840B, $C40A, $0419, $840A, $840B
	dw $C40A, $0419, $840A, $840B, $C40A, $0419, $840A, $840B
	dw $C40A, $0419, $840A, $840B, $C40A, $0419, $0432, $0432
	dw $0432, $4417, $0400, $0400, $0400, $0400, $0400, $4408

	dw $0408, $0411, $0418, $0425, $0418, $0415, $0418, $0426
	dw $0418, $0415, $0418, $0427, $0418, $0415, $0418, $0428
	dw $0418, $0415, $0418, $0429, $0418, $0415, $0418, $0418
	dw $0418, $4411, $0400, $0400, $0400, $0400, $0400, $4408

	; Fourth voltorb row
	dw $0408, $0417, $040A, $040B, $440A, $0419, $040A, $040B
	dw $440A, $0419, $040A, $040B, $440A, $0419, $040A, $040B
	dw $440A, $0419, $040A, $040B, $440A, $0419, $0433, $0433
	dw $0433, $4417, $0400, $0400, $0400, $0400, $0400, $4408

	dw $0408, $0417, $040C, $040D, $440C, $0423, $040C, $040D
	dw $440C, $0423, $040C, $040D, $440C, $0423, $040C, $040D
	dw $440C, $0423, $040C, $040D, $440C, $0423, $0443, $0443
	dw $0443, $4417, $0400, $0400, $0400, $0400, $0400, $4408

	dw $0408, $0417, $840A, $840B, $C40A, $0419, $840A, $840B
	dw $C40A, $0419, $840A, $840B, $C40A, $0419, $840A, $840B
	dw $C40A, $0419, $840A, $840B, $C40A, $0419, $0433, $0433
	dw $0433, $4417, $0400, $0400, $0400, $0400, $0400, $4408

	dw $0408, $0411, $0418, $0425, $0418, $0415, $0418, $0426
	dw $0418, $0415, $0418, $0427, $0418, $0415, $0418, $0428
	dw $0418, $0415, $0418, $0429, $0418, $0415, $0418, $0418
	dw $0418, $4411, $0400, $0400, $0400, $0400, $0400, $4408

	; Fifth voltorb row
	dw $0408, $0417, $040A, $040B, $440A, $0419, $040A, $040B
	dw $440A, $0419, $040A, $040B, $440A, $0419, $040A, $040B
	dw $440A, $0419, $040A, $040B, $440A, $0419, $0434, $0434
	dw $0434, $4417, $0400, $0400, $0400, $0400, $0400, $4408

	dw $0408, $0417, $040C, $040D, $440C, $0424, $040C, $040D
	dw $440C, $0424, $040C, $040D, $440C, $0424, $040C, $040D
	dw $440C, $0424, $040C, $040D, $440C, $0424, $0444, $0444
	dw $0444, $4417, $0400, $0400, $0400, $0400, $0400, $4408

	dw $0408, $0417, $840A, $840B, $C40A, $0419, $840A, $840B
	dw $C40A, $0419, $840A, $840B, $C40A, $0419, $840A, $840B
	dw $C40A, $0419, $840A, $840B, $C40A, $0419, $0434, $0434
	dw $0434, $4417, $0400, $0400, $0400, $0400, $0400, $4408

	dw $0408, $0411, $0418, $0425, $0418, $0415, $0418, $0426
	dw $0418, $0415, $0418, $0427, $0418, $0415, $0418, $0428
	dw $0418, $0415, $0418, $0429, $0418, $049A, $049B, $049B
	dw $049B, $049C, $049D, $049D, $049D, $049D, $049E, $4408

	; horizontal hint row
	dw $0408, $0417, $0430, $0430, $0430, $0419, $0431, $0431
	dw $0431, $0419, $0432, $0432, $0432, $0419, $0433, $0433
	dw $0433, $0419, $0434, $0434, $0434, $04AA, $04AB, $04AB
	dw $04AB, $04AB, $04AB, $04AB, $04AB, $04AB, $04AE, $4408

	dw $0408, $0417, $0440, $0440, $0440, $0419, $0441, $0441
	dw $0441, $0419, $0442, $0442, $0442, $0419, $0443, $0443
	dw $0443, $0419, $0444, $0444, $0444, $04AA, $04AB, $04AB
	dw $04AB, $04AB, $04AB, $04AB, $04AB, $04AB, $04AE, $4408

	dw $0408, $0417, $0430, $0430, $0430, $0419, $0431, $0431
	dw $0431, $0419, $0432, $0432, $0432, $0419, $0433, $0433
	dw $0433, $0419, $0434, $0434, $0434, $04AA, $04AB, $04AB
	dw $04AB, $04AB, $04AB, $04AB, $04AB, $04AB, $04AE, $4408

	dw $0408, $8410, $8416, $8416, $8416, $8413, $8416, $8416
	dw $8416, $8413, $8416, $8416, $8416, $8413, $8416, $8416
	dw $8416, $8413, $8416, $8416, $8416, $04BA, $849D, $849D
	dw $849D, $849D, $849D, $849D, $849D, $849D, $849E, $4408

	dw $0408, $0400, $0400, $0400, $0400, $0400, $0400, $0400
	dw $0400, $0400, $0400, $0400, $0400, $0400, $0400, $0400
	dw $0400, $0400, $0400, $0400, $0400, $0400, $0400, $0400
	dw $0400, $0400, $0400, $0400, $0400, $0400, $0400, $4408

	dw $8407, $8409, $8409, $8409, $8409, $8409, $8409, $8409
	dw $8409, $8409, $8409, $8409, $8409, $8409, $8409, $8409
	dw $8409, $8409, $8409, $8409, $8409, $8409, $8409, $8409
	dw $8409, $8409, $8409, $8409, $8409, $8409, $8409, $C407

	dw $0400, $0400, $0400, $0400, $0400, $0400, $0400, $0400
	dw $0400, $0400, $0400, $0400, $0400, $0400, $0400, $0400
	dw $0400, $0400, $0400, $0400, $0400, $0400, $0400, $0400
	dw $0400, $0400, $0400, $0400, $0400, $0400, $0400, $0400

	dw $0400, $0400, $0400, $0400, $0400, $0400, $0400, $0400
	dw $0400, $0400, $0400, $0400, $0400, $0400, $0400, $0400
	dw $0400, $0400, $0400, $0400, $0400, $0400, $0400, $0400
	dw $0400, $0400, $0400, $0400, $0400, $0400, $0400, $0400

	dw $0400, $0400, $0400, $0400, $0400, $0400, $0400, $0400
	dw $0400, $0400, $0400, $0400, $0400, $0400, $0400, $0400
	dw $0400, $0400, $0400, $0400, $0400, $0400, $0400, $0400
	dw $0400, $0400, $0400, $0400, $0400, $0400, $0400, $0400

	dw $0400, $0400, $0400, $0400, $0400, $0400, $0400, $0400
	dw $0400, $0400, $0400, $0400, $0400, $0400, $0400, $0400
	dw $0400, $0400, $0400, $0400, $0400, $0400, $0400, $0400
	dw $0400, $0400, $0400, $0400, $0400, $0400, $0400, $0400

;===================================================================================================

Win:
	db "Game clear!", $FF

OhNo:
	db "Oh no! You get 0 Coins!", $FF

Dropped:
	db "Dropped to Game Lv. ", $80, ".", $FF

Advanced:
	db "Advanced to Game Lv. ", $80, "!", $FF

Forfeit:
	db "Press ", $46, " to quit; ", $47, " to continue.", $FF

;===================================================================================================

; Comes in with 8-bit X offset for the address into SRAM
IncrementGameCounter:
	PHP

	SEP #$18
	REP #$21

	LDA.w SMIRROR+6,X
	ADC.w #$0001
	STA.w SMIRROR+6,X

	LDA.w SMIRROR+4,X
	ADC.w #$0000
	STA.w SMIRROR+4,X

	LDA.w SMIRROR+2,X
	ADC.w #$0000
	STA.w SMIRROR+2,X

	LDA.w SMIRROR+0,X
	ADC.w #$0000
	STA.w SMIRROR+0,X

	PLP
	RTS

;===================================================================================================

; Comes in with 8-bit X offset for the address into SRAM
AddCoinsToCounter:
	PHP
	SEP #$10

	PHX

	JSR GetCoinsDecimal

	SEP #$38
	PLX

	LDA.b COINSDEC+0
	ASL
	ASL
	ASL
	ASL
	ORA.b COINSDEC+1
	XBA

	LDA.b COINSDEC+2
	ASL
	ASL
	ASL
	ASL
	ORA.b COINSDEC+3

	REP #$21

	ADC.w SMIRROR+6,X
	STA.w SMIRROR+6,X

	LDA.w #$0000
	ADC.w SMIRROR+4,X
	STA.w SMIRROR+4,X

	LDA.w #$0000
	ADC.w SMIRROR+2,X
	STA.w SMIRROR+2,X

	LDA.w #$0000
	ADC.w SMIRROR+0,X
	STA.w SMIRROR+0,X

	PLP
	RTS

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

	LDA.w #NMI_DrawTotalCoins
	JSL AddNMIVector

	RTS

;===================================================================================================

SplitBCD:
	REP #$30
	TAX

	LDA.w $0006,X
	XBA
	STA.b SCRATCH+6

	LDA.w $0004,X
	XBA
	STA.b SCRATCH+4

	LDA.w $0002,X
	XBA
	STA.b SCRATCH+2

	LDA.w $0000,X
	XBA
	STA.b SCRATCH+0

;---------------------------------------------------------------------------------------------------

	SEP #$30

	LDX.b #$07
	LDY.b #$10

.next_split
	LDA.b SCRATCH,X
	AND.b #$0F
	STA.w BCDNUMS-1,Y

	DEY

	LDA.b SCRATCH,X
	LSR
	LSR
	LSR
	LSR
	STA.w BCDNUMS-1,Y

	DEY
	DEX
	BPL .next_split

;---------------------------------------------------------------------------------------------------

	LDX.b #$00

.find_first_nonzero_digit
	LDA.w BCDNUMS,X
	BNE .found_digit

	INX
	CPX.b #15
	BCC .find_first_nonzero_digit

.found_digit
	TXA
	ASL
	TAY

	REP #$20

	RTS
