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

	LDA.w #$2CCC

	LDX.w #$0554
	JSR DrawSpecialHintVWF

	LDX.w #$0614
	JSR DrawSpecialHintVWF

	LDX.w #$0594
	JSR DrawSpecialHintVWF

	LDX.w #$0654
	JSR DrawSpecialHintVWF

	LDA.w #$6C1C
	STA.w PAUSEMAP+$552

	LDA.w #$2C1C
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

	LDA.w #$2C1F
	STA.w PAUSEMAP+$592

	LDA.w #$AC1F
	STA.w PAUSEMAP+$612

	LDA.w #$6C1E
	STA.w PAUSEMAP+$5D2

	LDA.w #$EC1C
	STA.w PAUSEMAP+$652

	LDA.w #$AC1C
	STA.w PAUSEMAP+$64A

	INC
	STA.w PAUSEMAP+$64C
	STA.w PAUSEMAP+$64E
	STA.w PAUSEMAP+$650

	LDA.w #$0100
	STA.b BG3HOFF

	LDA.w #$0707
	STA.b TMQ

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

	BRA DrawNextVWFText

;===================================================================================================

DrawSpecialHintVWF:
	LDY.w #13

.next
	STA.w PAUSEMAP,X
	INC

	INX
	INX

	DEY
	BNE .next

	RTS

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

AddNext2VWFRows:
	JSR AddNextVWFRow

AddNextVWFRow:
	PHA

	JSR AddEmptyHelpChar

	LDA.w #$2016
	JSR AddHelpChar

	PLA

	LDY.w #26

.next
	JSR AddHelpChar

	INC

	DEY
	BNE .next

	PHA

	LDA.w #$2019
	JSR AddHelpChar

	INC
	JSR AddHelpChar

	LDA.w #$6016
	JSR AddHelpChar

	JSR AddEmptyHelpChar

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

	LDA.w #$2016
	JSR AddHelpCharDouble

;---------------------------------------------------------------------------------------------------

	; draw blanks until the first digit
	LDA.w #$2C1A

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
	ORA.w #$2C20
	JSR AddHelpCharStacked

	INY
	BRA .draw_numbers

.done_numbers
	LDA.w #$2C1A
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
	LDA.w #$2C1A

.next_blank
	CPY.w #9
	BCS .done_end_fill

	JSR AddHelpCharDouble

	INY
	BRA .next_blank

.done_end_fill
	LDA.w #$2019
	JSR AddHelpCharDouble

	INC
	JSR AddHelpCharDouble

	LDA.w #$6016
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
	dw BoldMoveChars, RISKYMOVES

;---------------------------------------------------------------------------------------------------

pushtable

table "fixedwidthmap.txt"


CoinsChars:
	db "Coins", $00

GamesPlayedChars:
	db "Games played", $00

GamesWonChars:
	db "Games won", $00

GamesLostChars:
	db "Games lost", $00

GamesQuitChars:
	db "Games quit". $00

CoinsLostChars:
	db "Coins lost". $00

Flipped1Chars:
	db "*1 flipped". $00

Flipped2Chars:
	db "*2 flipped". $00

Flipped3Chars:
	db "*3 flipped". $00

BestStreakChars:
	db "Best streak". $00

MaxLevelChars:
	db "Max level". $00

BoldMoveChars:
	db "". $00

;===================================================================================================

AddHelpTop:
	JSR AddEmptyHelpChar

	LDA.w #$2010
	JSR AddHelpChar

	INC
	JSR AddHelpChar

	INC

	LDY.w #25

.next
	JSR AddHelpChar

	DEY
	BNE .next

	INC
	JSR AddHelpChar

	INC
	JSR AddHelpChar

	LDA.w #$6010
	JSR AddHelpChar

	BRA AddEmptyHelpChar

;===================================================================================================

Add2BlankHelpRows:
	JSR AddBlankHelpRow

AddBlankHelpRow:
	JSR AddEmptyHelpChar

	LDA.w #$2016
	JSR AddHelpChar

	LDA.w #$2C1A

	LDY.w #26

.next
	JSR AddHelpChar

	DEY
	BNE .next

	LDA.w #$2019
	JSR AddHelpChar

	INC
	JSR AddHelpChar

	LDA.w #$6016
	JSR AddHelpChar

	BRA AddEmptyHelpChar

;===================================================================================================

AddBlankHelpBottomRow:
	JSR AddEmptyHelpChar

	LDA.w #$2016
	JSR AddHelpChar

	LDA.w #$2015
	JSR AddHelpChar

	LDA.w #$2C1A

	LDY.w #25

.next
	JSR AddHelpChar

	DEY
	BNE .next

	LDA.w #$201B
	JSR AddHelpChar

	DEC
	JSR AddHelpChar

	LDA.w #$6016
	JSR AddHelpChar

	BRA AddEmptyHelpChar

;===================================================================================================

AddEmptyHelpRow:
	LDY.w #32

	LDA.w #$0000

.next
	JSR AddHelpChar

	DEY
	BNE .next

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

	LDA.w #$2417
	JSR AddHelpChar

	INC

	LDY.w #28

.next
	JSR AddHelpChar

	DEY
	BNE .next

	LDA.w #$6417
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

;===================================================================================================
