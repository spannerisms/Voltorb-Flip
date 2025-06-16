;===================================================================================================

StartTheGame:
	PHK
	PLB

	LDA.w #NMIVector(NMI_DeletePressStart)
	JSR AddNMIVector

	LDA.w #NMIVector(NMI_DrawVoltorbIcons)
	JSR AddNMIVector

	LDA.w #NMIVector(NMI_WriteLevelAndControls)
	JSR AddNMIVector

	JSR BrightNoBG3
	JSR WaitForNMI

	LDA.w #NMIVector(NMI_CreateTextBox)
	JSR AddNMIVector

	SEP #$20

	LDA.b #$08
	STA.b LEVEL

;===================================================================================================

NewLevel:
	REP #$20
	SEP #$10

	LDA.w #$1FFF
	TCS

	JSR DrawTotalCoins
	JSR BuildLevel
	JSR CreateHints

.play
	JSR ControlCursor

	REP #$20
	SEP #$10

	LDA.w #NMIVector(NMI_WriteLevelAndControls)
	LDX.b MEMOING
	BEQ .not_memoing

	LDA.w #NMIVector(NMI_WriteLevelAndMemoing)

.not_memoing
	JSR AddNMIVector

	SEP #$30
	JSR TransferTilesAndWaitForNMI_wait1

	BRA .play

;===================================================================================================

AwardTile:
	LDY.b CURSOR

	LDA.w TILEVAL,Y
	AND.b #$03
	BEQ GameOver

	TAX

	CPX.b #2
	BCC .not_2or3

	DEC.b GOODLEFT

.not_2or3
	REP #$20

	LDA.b COINS
	BNE .multiply_coins

	TXA
	BRA .add_coins

.multiply_coins
	CPX.b #2
	BCC .got_1

	SED
	CLC
	BEQ .got_2

	ADC.b COINS

.got_2
	ADC.b COINS

	CLD

.add_coins
	STA.b COINS

.got_1
	SEP #$30

	LDA.w .counter-1,X
	TAX
	JSR IncrementGameCounter

	INC.b FLIPPED

	LDX.w CursorIndexRow,Y
	INC.w ROWFLIPS,X

	LDX.w CursorIndexCol,Y
	INC.w COLFLIPS,X

	RTS

.counter
	db FLIPPED1
	db FLIPPED2
	db FLIPPED3

;===================================================================================================

GameOver:
	SEP #$30

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

	STZ.w COINSDISP+0
	JSR DrawCoins

	LDA.w #$1717
	STA.b TMQ

	LDX.b #120
	JSR WaitForNMI_x_times

;===================================================================================================

LevelLost:
	REP #$20

	STZ.w CURSTREAK+0
	STZ.w CURSTREAK+2
	STZ.w CURSTREAK+4
	STZ.w CURSTREAK+6

	JSR RevealLevel

	SEP #$30

	STZ.b GREAT

	LDA.b FLIPPED
	BNE .flipped_something

	INC

.flipped_something
	CMP.b LEVEL
	BCS .no_demotion

	STA.b LEVEL

	REP #$20

	LDA.w #NMIVector(NMI_WriteLevelNumber)
	JSR AddNMIVector

	LDA.w #Dropped
	JSR DisplayDarkTextBoxForLong

.no_demotion
	JMP NewLevel

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
	JSR WaitForNMI_x_times

	JSR WaitForInput

	REP #$20

	STZ.b BG3HOFF

	JMP BrightAndReturn

;---------------------------------------------------------------------------------------------------

.no_pause
	; includes a 2 frame cooldown for exiting notes, unless you move
	LDA.b MEMOING
	BEQ .not_memoing

	DEC.b MEMOING

.not_memoing
	LDA.b JOY1B
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
	BPL .not_0_note_press
	EOR.b #$01

	; Y for 1
.not_0_note_press
	BVC .not_1_note_press
	EOR.b #$02

	; A for 3
.not_1_note_press
	BIT.b JOY1BNEW
	BPL .not_3_note_press
	EOR.b #$08

	; X for 2
.not_3_note_press
	BVC .not_2_note_press
	EOR.b #$04

.not_2_note_press
	STA.w TILEMEMO,X

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
	JSR AwardTile

	SEP #$30

	LDA.b #$04
	JSR PositionBigMirroredExplosion

	LDA.b #$08
	JSR PositionBigMirroredExplosion

	LDA.b #$0C
	JSR PositionBigMirroredExplosion

	JSR DeleteExplosions

	JSR RaiseCoins

	SEP #$30

	LDA.b GOODLEFT
	BEQ LevelCleared

	RTS

;---------------------------------------------------------------------------------------------------

.moving_with_no_l_press
	STZ.b MEMOING

.moving
	JSR GetCursorOAMCoordinates

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
	JSR WaitForNMI_x_times

.loop
	LDX.b JOY1ANEW
	BMI BrightAndReturn

	LDX.b JOY1BNEW
	BMI .end

	JSR WaitForNMI
	BRA .loop

;---------------------------------------------------------------------------------------------------

.end
	LDX.b #WINNINGS
	JSR AddCoinsToCounter

	LDX.b #QUIT
	JSR IncrementGameCounter

	LDX.b #GAMES
	JSR IncrementGameCounter

	JSR UpdateSRAM

	JMP LevelLost

;---------------------------------------------------------------------------------------------------

BrightAndReturn:
	SEP #$30

	JSR BrightNoBG3

	LDX.b #20
	JMP WaitForNMI_x_times

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
	BCC .not_new_best

	STA.w MAXLEVEL

.not_new_best
	REP #$20

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
	LDX.b #GAMES
	JSR IncrementGameCounter

	JSR UpdateSRAM

	JSR RevealLevel

	SEP #$30

	LDX.b LEVEL
	CPX.b #8
	BCS .not_advancing

	LDA.b FLIPPED
	CMP.b #8
	BCC .not_great

	INC.b GREAT

	LDA.b GREAT
	CMP.b #5
	BCC .not_great_enough

	LDX.b #8
	BRA .advance_level

.not_great
	STZ.b GREAT

.not_great_enough
	CPX.b #7
	BCS .not_advancing

	INX

.advance_level
	STX.b LEVEL

	REP #$20

	LDA.w #NMIVector(NMI_WriteLevelNumber)
	JSR AddNMIVector

	LDA.w #Advanced
	JSR DisplayDarkTextBoxForLong

.not_advancing
	JMP NewLevel

;===================================================================================================

GetCursorOAMCoordinates:
	LDX.b CURSOR

	LDA.w CursorIndexCol,X
	STA.b SCRATCH+0
	ASL
	ASL
	ASL
	ASL
	ASL
	ADC.b #12
	STA.b CURX

	LDA.w CursorIndexRow,X
	STA.b SCRATCH+1

	ASL
	ASL
	ASL
	ASL
	ASL
	ADC.b #12
	STA.b CURY

	RTS

;===================================================================================================

CursorIndexCol:
	db 0, 1, 2, 3, 4
	db 0, 1, 2, 3, 4
	db 0, 1, 2, 3, 4
	db 0, 1, 2, 3, 4
	db 0, 1, 2, 3, 4

CursorIndexRow:
	db 0, 0, 0, 0, 0
	db 1, 1, 1, 1, 1
	db 2, 2, 2, 2, 2
	db 3, 3, 3, 3, 3
	db 4, 4, 4, 4, 4

;===================================================================================================

RowOffsets:
	db  0
	db  5
	db 10
	db 15
	db 20

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

TestRisk:
	PHA

	LSR
	LSR
	LSR
	LSR
	TAY

	PLA
	AND.b #$07
	CMP.w .risky_at_count,Y

#cannot_flip:
	RTS

.risky_at_count
	db 128
	db 4
	db 3
	db 1
	db 0
	db 0

;===================================================================================================

FlipTile:
	LDX.b CURSOR
	LDA.w TILEVAL,X
	BMI cannot_flip

	PHA ; save tile value

	; check to see if this was a risky move
	LDY.w CursorIndexRow,X

	LDA.w HINTSR,Y
	AND.b #$70
	BEQ .not_risky

	ORA.w ROWFLIPS,Y
	STA.b SCRATCH

	LDY.w CursorIndexCol,X

	LDA.w HINTSC,Y
	AND.b #$70
	BEQ .not_risky

	ORA.w COLFLIPS,Y
	JSR TestRisk
	BCS .risky

	LDA.b SCRATCH
	JSR TestRisk
	BCC .not_risky

.risky
	LDX.b #RISKYMOVES
	JSR IncrementGameCounter

;---------------------------------------------------------------------------------------------------

.not_risky
	PLA ; get tile value
	AND.b #$07
	BNE .not_voltorb

	; here to prevent save scum
	LDX.b #LOST
	JSR IncrementGameCounter

	LDX.b #COINSLOST
	JSR AddCoinsToCounter

	LDX.b #GAMES
	JSR IncrementGameCounter

	JSR UpdateSRAM

	SEP #$30

;---------------------------------------------------------------------------------------------------

.not_voltorb
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

BuildLevel:
	SEP #$30

	; find level data
	LDA.b LEVEL
	ASL
	TAX

	; random number between 0 and 4
	JSR Random

	REP #$30

	AND.w #$00FF
	STA.b SAFESCRATCH
	ASL
	ASL
	ADC.b SAFESCRATCH
	XBA
	AND.w #$00FF

	; multiply by 3 for data
	STA.b SAFESCRATCH
	ASL
	ADC.b SAFESCRATCH
	ADC.w LevelDistributions,X
	TAX

	LDA.w $0000,X
	STA.b SAFESCRATCH+0

	LDA.w $0001,X
	STA.b SAFESCRATCH+1

;---------------------------------------------------------------------------------------------------

	; clear the board with 1s
	SEP #$30

	LDA.b #$01

	LDX.b #24

.next_clear
	STZ.w TILEDISP,X
	STZ.w TILEMEMO,X
	STA.w TILEVAL,X

	DEX
	BPL .next_clear

	LDX.b #0

	; distribute 2s
	LDY.b SAFESCRATCH+0
	BEQ .no_twos

	LDA.b #$02
	JSR AddTilesToBoard

.no_twos
	; distribute 3s
	LDY.b SAFESCRATCH+1
	BEQ .no_threes

	LDA.b #$03
	JSR AddTilesToBoard

.no_threes
	; distribute voltorbs
	LDY.b SAFESCRATCH+2
	LDA.b #$00
	JSR AddTilesToBoard

	CLC
	LDA.b SAFESCRATCH+0
	ADC.b SAFESCRATCH+1
	STA.b GOODLEFT

	STZ.b FLIPPED

;---------------------------------------------------------------------------------------------------

	; Shuffle the board
	LDA.b #200
	STA.b SCRATCH

.next_swap
	JSR Random25
	TAX

	JSR Random25
	TAY

	LDA.w TILEVAL,X
	XBA

	LDA.w TILEVAL,Y
	STA.w TILEVAL,X

	XBA
	STA.w TILEVAL,Y

	DEC.b SCRATCH
	BNE .next_swap

;---------------------------------------------------------------------------------------------------

	STZ.b CURSOR

	STZ.w ROWFLIPS+4
	STZ.w COLFLIPS+4

	REP #$20

	STZ.w ROWFLIPS+0
	STZ.w ROWFLIPS+2

	STZ.w COLFLIPS+0
	STZ.w COLFLIPS+2

	STZ.b COINS
	STZ.b COINSDISP

	JSR DrawCoins

	REP #$20

	LDA.w #NMIVector(NMI_WriteLevelNumber)
	JSR AddNMIVector

	RTS

;===================================================================================================

AddTilesToBoard:
	STA.w TILEVAL,X

	INX
	DEY
	BNE AddTilesToBoard

	RTS

;===================================================================================================

Random25:
	JSR Random

	REP #$20

	AND.w #$00FF

	STA.b SCRATCH+2
	ASL
	ASL
	ASL
	STA.b SCRATCH+4
	ASL
	ADC.b SCRATCH+4
	ADC.b SCRATCH+2

	SEP #$20
	XBA

	RTS

;===================================================================================================

LevelDistributions:
	dw .level1
	dw .level1
	dw .level2
	dw .level3
	dw .level4
	dw .level5
	dw .level6
	dw .level7
	dw .level8

	; 2s, 3s, voltorbs
.level1
	db  3,  1,  6
	db  0,  3,  6
	db  5,  0,  6
	db  2,  2,  6
	db  4,  1,  6

.level2
	db  1,  3,  7
	db  6,  0,  7
	db  3,  2,  7
	db  0,  4,  7
	db  5,  1,  7

.level3
	db  2,  3,  8
	db  7,  0,  8
	db  4,  2,  8
	db  1,  4,  8
	db  6,  1,  8

.level4
	db  3,  3,  8
	db  0,  5,  8
	db  8,  0, 10
	db  5,  2, 10
	db  2,  4, 10

.level5
	db  7,  1, 10
	db  4,  3, 10
	db  1,  5, 10
	db  9,  0, 10
	db  6,  2, 10

.level6
	db  3,  4, 10
	db  0,  6, 10
	db  8,  1, 10
	db  5,  3, 10
	db  2,  5, 10

.level7
	db  7,  2, 10
	db  4,  4, 10
	db  1,  6, 13
	db  9,  1, 13
	db  6,  3, 10

.level8
	db  0,  7, 10
	db  8,  2, 10
	db  5,  4, 10
	db  2,  6, 10
	db  7,  3, 10

;===================================================================================================

; Enters with 8-bit X offset for the address into SRAM
IncrementGameCounter:
	PHP

	SEP #$18
	REP #$21

	LDA.w #$0001
	ADC.w SMIRROR+6,X
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

; Enters with 8-bit X offset for the address into SRAM
AddCoinsToCounter:
	PHP

	SEP #$18
	REP #$21

	LDA.b COINS
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
