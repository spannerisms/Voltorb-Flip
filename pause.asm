PrepareHelpBox:
	REP #$30

	LDA.w #NMIVector(NMI_DeleteAllTextChars)
	JSR AddVectorAndWaitForNMI

	LDX.w #$0000

	LDA.w #10
	STA.w SCRATCH

.next_empty
	JSR AddEmptyHelpRow

	DEC.b SCRATCH
	BNE .next_empty

;---------------------------------------------------------------------------------------------------

	JSR AddHelpTop

	LDA.w #$2D00
	JSR AddNext2VWFRows
	JSR AddNext2VWFRows

	JSR AddBlankHelpThen2Rows
	JSR AddBlankHelpThen2Rows

	JSR Add2BlankHelpRows
	JSR Add2BlankHelpRows
	JSR AddBlankHelpBottomRow

	JSR AddHelpBottom
	JSR AddEmptyHelpRow

;---------------------------------------------------------------------------------------------------

	LDA.w #$2CCC

	LDX.w #$0554
	JSR DrawSpecialHintVWF

	LDX.w #$0614
	JSR DrawSpecialHintVWF

	LDX.w #$0594
	JSR DrawSpecialHintVWF

	LDX.w #$0654
	JSR DrawSpecialHintVWF

;---------------------------------------------------------------------------------------------------

	LDA.w #$6C37
	STA.w PAUSEMAP+$552

	LDA.w #$2C37
	STA.w PAUSEMAP+$54A

	INC
	STA.w PAUSEMAP+$54C
	STA.w PAUSEMAP+$54E
	STA.w PAUSEMAP+$550

	INC
	STA.w PAUSEMAP+$58A
	STZ.w PAUSEMAP+$58C
	STZ.w PAUSEMAP+$58E
	STZ.w PAUSEMAP+$590

	STA.w PAUSEMAP+$5CA
	STZ.w PAUSEMAP+$5CC
	STZ.w PAUSEMAP+$5CE
	STZ.w PAUSEMAP+$5D0

	STA.w PAUSEMAP+$60A
	STZ.w PAUSEMAP+$60C
	STZ.w PAUSEMAP+$60E
	STZ.w PAUSEMAP+$610

	LDA.w #$2C49
	STA.w PAUSEMAP+$592

	LDA.w #$AC49
	STA.w PAUSEMAP+$612

	LDA.w #$6C39
	STA.w PAUSEMAP+$5D2

	LDA.w #$EC37
	STA.w PAUSEMAP+$652

	LDA.w #$AC37
	STA.w PAUSEMAP+$64A

	INC
	STA.w PAUSEMAP+$64C
	STA.w PAUSEMAP+$64E
	STA.w PAUSEMAP+$650

;---------------------------------------------------------------------------------------------------

	JSR ConfigureForPause

	LDA.w #NMIVector(NMI_TransferPauseMenu)
	JSR AddVectorAndWaitForNMI

	LDA.w #vma(!VWFCHR)
	STA.b VWFV

	LDA.w #HelpText
	STA.b SAFESCRATCH

	JSR DrawNextVWFText
	JSR DrawNextVWFText
	JSR DrawNextVWFText
	JSR DrawNextVWFText

	LDA.w #vma(!BG3CHR+$0CC0)
	STA.b VWFV

;===================================================================================================

DrawNextVWFText:
	JSR ResetVWF

	LDA.w #3

.next_char
	JSR DrawLetterToVWF

	LDA.b (SAFESCRATCH)
	INC.b SAFESCRATCH

	AND.w #$00FF
	CMP.w #$0080
	BCC .next_char

	LDA.w #NMIVector(NMI_TransferTextChars)
	JSR AddVectorAndWaitForNMI

	CLC
	LDA.b VWFV
	ADC.w #vma($0340)
	STA.b VWFV

	RTS

;===================================================================================================

DrawSpecialHintVWF:
	LDY.w #13

;===================================================================================================

DrawPauseVWF:
	JSR AddHelpChar

	INC
	DEY
	BNE DrawPauseVWF

	RTS

;===================================================================================================

HelpText:
	db "Clear the level by uncovering every", $FF
	db "hidden ", $56, "2 and ", $56, "3 multiplier card.", $FF
	db "Voltorb cards lose the game. 0 coins.", $FF
	db "Press SELECT to view your stats.", $FF
	db "Sum of row/column", $05, $04, "Voltorbs", $FF

;===================================================================================================

AddBlankHelpThen2Rows:
	PHA
	JSR AddBlankHelpRow
	PLA

;===================================================================================================

AddNext2VWFRows:
	JSR AddNextVWFRow

;===================================================================================================

AddNextVWFRow:
	PHA
	JSR AddHelpRowStartEdge
	PLA

	LDY.w #26
	JSR DrawPauseVWF

	PHA
	JSR AddHelpRowEndEdge
	PLA

	RTS

;===================================================================================================

PrepareStatsBox:
	REP #$30

	JSR DarkenGameBoard
	JSR WaitForNMI

	LDX.w #$0000

	JSR AddEmptyHelpRow
	JSR AddHelpTop

	LDA.w MAXLEVEL
	AND.w #$000F
	STA.w DUMB+6

	LDA.w #$0000

	STA.w DUMB+0
	STA.w DUMB+2
	STA.w DUMB+4

.next_row
	JSR AddNextStatRow

	INC
	CMP.w #12
	BCC .next_row

	JSR AddBlankHelpBottomRow
	JSR AddHelpBottom
	JSR AddEmptyHelpRow

	LDA.w #NMIVector(NMI_TransferPauseMenu)
	JSR AddNMIVector

;===================================================================================================

ConfigureForPause:
	LDA.w #$0100
	STA.b BG3HOFF

	LDA.w #$0707
	STA.b TMQ

	RTS

;===================================================================================================

AddNextStatRow:
	PHA

	ASL
	ASL
	TAY

	PHX

	LDA.w StatRowData,Y
	STA.w SCRATCH+12

	LDA.w StatRowData+2,Y
	JSR SplitBCD

	REP #$30

	STX.b SCRATCH+8

	PLX

	LDA.w #$0000
	TAY

	JSR AddHelpCharDouble

	LDA.w #$2041
	JSR AddHelpCharDouble

;---------------------------------------------------------------------------------------------------

	; draw blanks until the first digit
	LDA.w #$2C45

.next_blank_digit
	CPY.b SCRATCH+8
	BCS .draw_numbers

	JSR AddHelpCharDoubleINY
	BRA .next_blank_digit

.draw_numbers
	CPY.w #16
	BCS .done_numbers

	LDA.w BCDNUMS,Y
	AND.w #$000F
	ORA.w #$2C10
	JSR AddHelpCharStacked
	BRA .draw_numbers

.done_numbers
	LDA.w #$2C45
	JSR AddHelpCharDouble

	LDY.w #$0000

.next_label
	LDA.b (SCRATCH+12),Y
	AND.w #$00FF
	BEQ .fill_end

	ORA.w #$2C00
	JSR AddHelpCharStacked
	BRA .next_label

;---------------------------------------------------------------------------------------------------

.fill_end
	LDA.w #$2C45

.next_blank
	CPY.w #9
	BCS .done_end_fill

	JSR AddHelpCharDoubleINY
	BRA .next_blank

.done_end_fill
	TXA
	CLC
	ADC.w #64
	PHA

	JSR AddHelpRowEndEdge

	PLX
	JSR AddHelpRowEndEdge

	PLA

	RTS

;===================================================================================================

StatRowData:
	dw CoinsChars,         WINNINGS
	dw GamesPlayedChars,   GAMES
	dw GamesWonChars,      WINS
	dw GamesLostChars,     LOST
	dw GamesQuitChars,     QUIT
	dw CoinsLostChars,     COINSLOST
	dw Flipped1Chars,      FLIPPED1
	dw Flipped2Chars,      FLIPPED2
	dw Flipped3Chars,      FLIPPED3
	dw BestStreakChars,    STREAK
	dw MaxLevelChars,      DUMB
	dw BoldMoveChars,      RISKYMOVES

;---------------------------------------------------------------------------------------------------

CoinsChars:
	db $50, $51, $52, $53, $00

GamesPlayedChars:
	db $70, $71, $72, $73, $0A, $0B, $0C, $0D, $0E, $00

GamesWonChars:
	db $70, $71, $72, $73, $74, $75, $76, $00

GamesLostChars:
	db $70, $71, $72, $73, $77, $78, $79, $00

GamesQuitChars:
	db $70, $71, $72, $73, $7A, $7B, $7C, $00

CoinsLostChars:
	db $50, $51, $52, $54, $55, $56, $57, $00

Flipped1Chars:
	db $58, $59, $2A, $2B, $2C, $0D, $0E, $00

Flipped2Chars:
	db $5A, $5B, $2A, $2B, $2C, $0D, $0E, $00

Flipped3Chars:
	db $5C, $5D, $2A, $2B, $2C, $0D, $0E, $00

BestStreakChars:
	db $90, $91, $92, $93, $94, $95, $96, $97, $00

MaxLevelChars:
	db $98, $99, $9A, $9B, $9C, $9D, $00

BoldMoveChars:
	db $B0, $B1, $B2, $B3, $B4, $B5, $B6, $00

;===================================================================================================

AddHelpTop:
	LDA.w #$2031
	JSR AddHelpRowStart

	INC
	JSR AddHelpChar

	INC
	JSR FillHelpRow25

	INC
	JSR AddHelpChar

	INC
	JSR AddHelpChar

	LDA.w #$6031
	BRA AddHelpRowEnd

;===================================================================================================

AddBlankHelpBottomRow:
	JSR AddHelpRowStartEdge

	LDA.w #$2036
	JSR AddHelpChar

	LDA.w #$2C45
	JSR FillHelpRow25

	LDA.w #$2046
	BRA AddHelpRowEndEdgePiece

;===================================================================================================

Add2BlankHelpRows:
	JSR AddBlankHelpRow

AddBlankHelpRow:
	JSR AddHelpRowStartEdge

	LDA.w #$2C45
	LDY.w #26
	JSR FillHelpRow

;===================================================================================================

AddHelpRowEndEdge:
	LDA.w #$2044

;===================================================================================================

AddHelpRowEndEdgePiece:
	JSR AddHelpChar

	LDA.w #$2045
	JSR AddHelpChar

	LDA.w #$6041

;===================================================================================================

AddHelpRowEnd:
	JSR AddHelpChar

;===================================================================================================

AddEmptyHelpChar:
	STZ.w PAUSEMAP,X

	INX
	INX

	RTS

;===================================================================================================

AddHelpRowStartEdge:
	LDA.w #$2041

;===================================================================================================

AddHelpRowStart:
	JSR AddEmptyHelpChar

;===================================================================================================

AddHelpChar:
	STA.w PAUSEMAP,X

	INX
	INX

	RTS

;===================================================================================================

AddHelpBottom:
	LDA.w #$2442
	JSR AddHelpRowStart

	INC

	LDY.w #28
	JSR FillHelpRow

	LDA.w #$6442
	BRA AddHelpRowEnd

;===================================================================================================

AddHelpCharDoubleINY:
	INY

AddHelpCharDouble:
	STA.w PAUSEMAP+64,X
	BRA AddHelpChar

;===================================================================================================

AddHelpCharStacked:
	STA.w PAUSEMAP+0,X

	CLC
	ADC.w #$0010
	STA.w PAUSEMAP+64,X

	INX
	INX
	INY

	RTS

;===================================================================================================

AddEmptyHelpRow:
	LDY.w #32
	LDA.w #$0000

	BRA FillHelpRow

;===================================================================================================

FillHelpRow25:
	LDY.w #25

FillHelpRow:
	JSR AddHelpChar

	DEY
	BNE FillHelpRow

	RTS

;===================================================================================================
