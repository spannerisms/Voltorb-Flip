PrepareHelpBox:
	REP #$30

	LDA.w #NMI_DeleteAllTextChars
	JSL AddNMIVector
	JSL WaitForNMI

	LDX.w #$0000

	LDA.w #10
	STA.w SCRATCH

.next_empty
	JSR AddEmptyHelpRow
	DEC.b SCRATCH
	BNE .next_empty

	JSR AddHelpTop

	LDA.w #$2D00
	JSR AddNextVWFRow
	JSR AddNextVWFRow
	JSR AddNextVWFRow
	JSR AddNextVWFRow

	PHA
	JSR AddBlankHelpRow
	PLA

	JSR AddNextVWFRow
	JSR AddNextVWFRow

	PHA
	JSR AddBlankHelpRow
	PLA

	JSR AddNextVWFRow
	JSR AddNextVWFRow

	JSR AddBlankHelpRow
	JSR AddBlankHelpRow
	JSR AddBlankHelpRow
	JSR AddBlankHelpRow
	JSR AddBlankHelpBottomRow

	JSR AddHelpBottom
	JSR AddEmptyHelpRow

	LDA.w #$2CCC

	LDX.w #$0554
	JSR DrawSpecialHintVWF

	LDX.w #$0614
	JSR DrawSpecialHintVWF

	LDX.w #$0594
	JSR DrawSpecialHintVWF

	LDX.w #$0654
	JSR DrawSpecialHintVWF

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

	LDA.w #NMI_TransferPauseMenu
	JSL AddNMIVector

	LDA.w #$0100
	STA.b BG3HOFF

	LDA.w #$0707
	STA.b TMQ

	JSL WaitForNMI

	LDA.w #$7000>>1
	STA.b VWFV

	LDA.w #HelpText
	STA.b SAFESCRATCH

	JSR DrawNextVWFText
	JSR DrawNextVWFText
	JSR DrawNextVWFText
	JSR DrawNextVWFText

	LDA.w #$6CC0>>1
	STA.b VWFV
	BRA DrawNextVWFText

;===================================================================================================

DrawSpecialHintVWF:
	LDY.w #13

--	STA.w PAUSEMAP,X
	INC

	INX
	INX

	DEY
	BNE --

	RTS

;===================================================================================================

DrawNextVWFText:
	JSL ResetVWF

	LDA.w #3

.next_char
	JSL DrawLetterToVWF

	LDA.b (SAFESCRATCH)
	INC.b SAFESCRATCH

	AND.w #$00FF
	CMP.w #$0080
	BCC .next_char

	LDA.w #NMI_TransferTextChars
	JSL AddNMIVector

	JSL WaitForNMI

	CLC
	LDA.b VWFV
	ADC.w #$0340>>1
	STA.b VWFV

	RTS

;===================================================================================================

HelpText:
	db "Clear the level by uncovering every", $FF
	db "hidden ", $56, "2 and ", $56, "3 multiplier card.", $FF
	db "Voltorb cards lose the game. 0 coins.", $FF
	db "Press SELECT to view your stats.", $FF
	db "Sum of row/column", $05, $04, "Voltorbs", $FF

;===================================================================================================

AddNextVWFRow:
	PHA

	JSR AddEmptyHelpChar

	LDA.w #$2041
	JSR AddHelpChar

	PLA

	LDY.w #26

--	JSR AddHelpChar

	INC

	DEY
	BNE --

	PHA

	LDA.w #$2044
	JSR AddHelpChar

	INC
	JSR AddHelpChar

	LDA.w #$6041
	JSR AddHelpChar

	JSR AddEmptyHelpChar

	PLA

	RTS

;===================================================================================================

PrepareStatsBox:
	REP #$30

	JSR DarkenGameBoard
	JSL WaitForNMI

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
	CMP.w #11
	BCC .next_row

	JSR AddBlankHelpRow
	JSR AddBlankHelpBottomRow
	JSR AddHelpBottom
	JSR AddEmptyHelpRow

	LDA.w #NMI_TransferPauseMenu
	JSL AddNMIVector

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

	JSR AddHelpCharDouble

	INY
	BRA .next_blank_digit

.draw_numbers
	CPY.w #16
	BCS .done_numbers

	LDA.w BCDNUMS,Y
	AND.w #$000F
	ORA.w #$2C10
	JSR AddHelpCharStacked

	INY
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

	INY
	BRA .next_label

;---------------------------------------------------------------------------------------------------

.fill_end
	LDA.w #$2C45

.next_blank
	CPY.w #9
	BCS .done_end_fill

	JSR AddHelpCharDouble

	INY
	BRA .next_blank

.done_end_fill
	LDA.w #$2044
	JSR AddHelpCharDouble

	INC
	JSR AddHelpCharDouble

	LDA.w #$6041
	JSR AddHelpCharDouble

	LDA.w #$0000
	JSR AddHelpCharDouble

	TXA
	CLC
	ADC.w #64
	TAX

	PLA

	RTS

;===================================================================================================

StatRowData:
	dw CoinsChars, WINNINGS
	dw GamesPlayedChars, GAMES
	dw GamesWonChars, WINS
	dw GamesLostChars, LOST
	dw GamesQuitChars, QUIT
	dw CoinsLostChars, COINSLOST
	dw Flipped1Chars, FLIPPED1
	dw Flipped2Chars, FLIPPED2
	dw Flipped3Chars, FLIPPED3
	dw BestStreakChars, STREAK
	dw MaxLevelChars, DUMB

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

;===================================================================================================

AddHelpTop:
	JSR AddEmptyHelpChar

	LDA.w #$2031
	JSR AddHelpChar

	INC
	JSR AddHelpChar

	INC

	LDY.w #25

--	JSR AddHelpChar

	DEY
	BNE --

	INC
	JSR AddHelpChar

	INC
	JSR AddHelpChar

	LDA.w #$6031
	JSR AddHelpChar

	BRA AddEmptyHelpChar

;===================================================================================================

AddBlankHelpRow:
	JSR AddEmptyHelpChar

	LDA.w #$2041
	JSR AddHelpChar

	LDA.w #$2C45

	LDY.w #26

--	JSR AddHelpChar

	DEY
	BNE --

	LDA.w #$2044
	JSR AddHelpChar

	INC
	JSR AddHelpChar

	LDA.w #$6041
	JSR AddHelpChar

	BRA AddEmptyHelpChar

;===================================================================================================

AddBlankHelpBottomRow:
	JSR AddEmptyHelpChar

	LDA.w #$2041
	JSR AddHelpChar

	LDA.w #$2036
	JSR AddHelpChar

	LDA.w #$2C45

	LDY.w #25

--	JSR AddHelpChar

	DEY
	BNE --

	LDA.w #$2046
	JSR AddHelpChar

	DEC
	JSR AddHelpChar

	LDA.w #$6041
	JSR AddHelpChar

	BRA AddEmptyHelpChar

;===================================================================================================

AddEmptyHelpRow:
	LDY.w #32

	LDA.w #$0000

--	JSR AddHelpChar

	DEY
	BNE --

	RTS

;===================================================================================================

AddEmptyHelpChar:
	LDA.w #$0000

;===================================================================================================

AddHelpChar:
	STA.w PAUSEMAP,X

	INX
	INX

	RTS

;===================================================================================================

AddHelpBottom:
	JSR AddEmptyHelpChar

	LDA.w #$2442
	JSR AddHelpChar

	INC

	LDY.w #28

--	JSR AddHelpChar

	DEY
	BNE --

	LDA.w #$6442
	JSR AddHelpChar

	BRA AddEmptyHelpChar

;===================================================================================================

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

	RTS
