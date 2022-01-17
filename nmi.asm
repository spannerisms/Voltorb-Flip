;===================================================================================================
; Load A with 16bit vector in bank00 for an NMI routine to run
;===================================================================================================
AddNMIVector:
	STA.b (NMIVV)

	INC.b NMIVC
	INC.b NMIVV
	INC.b NMIVV

	RTL

;===================================================================================================

Exit_NMI_Fast:
	PLA
	RTI

Vector_NMI:
	SEI

	REP #$30

	PHA
	AND.l $420F ; get RDNMI in 16 bit mode

	LDA.l NMIWAIT
	BNE Exit_NMI_Fast

	JML ++

++	PHX
	PHY
	PHD
	PHB

	LDA.w #$0000
	TCD
	DEC
	STA.b NMIWAIT

	SEP #$31

	STZ.w $420C

	LDA.b #$80
	PHA
	PLB

	STA.w INIDISP
	STA.w VMAIN

	JSR NMI_Registers

	LDA.b NMIVC
	ASL
	TAX
	STX.b NMIVC
	BEQ .done_vectors

.next_vector
	JSR.w (NMIV-2,X)

	SEP #$30
	LDX.b NMIVC
	DEX
	DEX
	STX.b NMIVC
	BNE .next_vector

.done_vectors
	REP #$20
	LDA.w #NMIV
	STA.b NMIVV
	STZ.b NMIVC

	SEP #$20
	LDA.b INIDQ
	STA.w INIDISP

	JSR ReadJoyPad

	REP #$F3
	PLB
	PLD
	PLY
	PLX
	PLA

Vector_None:
	RTI

;===================================================================================================

ReadJoyPad:
	SEP #$20

	PEI.b (JOY1)

	LDA.b #$01

	; wait for auto joypad read to finish
--	BIT.w $4212
	BNE --

	REP #$20

	LDA.w $4218
	STA.b JOY1

	PLA
	EOR.w #$FFFF
	AND.b JOY1
	STA.b JOY1NEW

	RTS

;===================================================================================================

NMI_Registers:
	REP #$30

	TSX

	LDA.w #$210C : TCS
	PEA.w $3311
	PEA.w $6B6B
	PEI.b (BG1SCQ)
	PEA.w $0009

	LDA.w #$2131 : TCS
	PEI.b (CGWSELQ)
	PEA.w $0000
	PEI.b (TMQ)
	PEA.w $0000
	PEA.w $0000
	PEA.w $0000
	PEA.w $0000

	SEP #$20

	LDA.b #$00
	PHA

	TXS

	SEP #$30

	LDA.b #$62 : STA.w $2101 ; OBSEL
	LDA.b FIXCOL : STA.w $2132 ; COLDATA
	STZ.w $2133 ; SETINI

	LDA.b BG1HOFF+0 : STA.w $210D
	LDA.b BG1HOFF+1 : STA.w $210D

	LDA.b BG1VOFF+0 : STA.w $210E
	LDA.b BG1VOFF+1 : STA.w $210E

	LDA.b BG2HOFF+0 : STA.w $210F
	LDA.b BG2HOFF+1 : STA.w $210F

	LDA.b BG2VOFF+0 : STA.w $2110
	LDA.b BG2VOFF+1 : STA.w $2110

	LDA.b BG3HOFF+0 : STA.w $2111
	LDA.b BG3HOFF+1 : STA.w $2111

	LDA.b BG3VOFF+0 : STA.w $2112
	LDA.b BG3VOFF+1 : STA.w $2112

	RTS

;===================================================================================================

NMI_Nothing:
	RTS

;===================================================================================================

NMI_TransferTileQueue:
	SEP #$30

	LDY.b #$80
	STY.w VMAIN

	LDY.b #24

.next_box
	SEP #$30

	LDA.w TILEDISP,Y
	BPL .no_tile_change

	AND.b #$0F
	STA.w TILEDISP,Y

	ASL
	TAX

	REP #$30
	TYA
	ASL

	JSR (.vectors,X)

	SEP #$30

;---------------------------------------------------------------------------------------------------

.no_tile_change
	LDA.w TILEMEMO,Y
	BPL .no_note_change

	AND.b #$0F
	STA.w TILEMEMO,Y
	STA.b NMISCRATCH

	REP #$30

	TYA
	ASL
	TAX

	LDA.w DrawAtAnnotation,X
	STA.w VMADDR

	LSR.b NMISCRATCH
	BCC .no_voltorb_note	

	LDX.w #$2446
	STX.w VMDATA

	BRA .done_voltorb_note

.no_voltorb_note
	STZ.w VMDATA

.done_voltorb_note
	INC
	INC
	STA.w VMADDR

	LSR.b NMISCRATCH
	BCC .no_1_note

	LDX.w #$2447
	STX.w VMDATA

	BRA .done_1_note

.no_1_note
	STZ.w VMDATA

.done_1_note
	CLC
	ADC.w #$003E
	STA.w VMADDR

	LSR.b NMISCRATCH
	BCC .no_2_note

	LDX.w #$2448
	STX.w VMDATA

	BRA .done_2_note

.no_2_note
	STZ.w VMDATA

.done_2_note
	INC
	INC
	STA.w VMADDR

	LSR.b NMISCRATCH
	BCC .no_3_note

	LDX.w #$2449
	STX.w VMDATA

	BRA .no_note_change

.no_3_note
	STZ.w VMDATA

.no_note_change
	DEY
	BPL .next_box

	RTS

;---------------------------------------------------------------------------------------------------

.vectors
	dw Tile_Empty  ; 00
	dw Tile_FlipA  ; 01
	dw Tile_FlipB  ; 02
	dw Tile_Empty  ; 03
	dw Tile_Empty  ; 04
	dw Tile_Empty  ; 05
	dw Tile_Empty  ; 06
	dw Tile_Empty  ; 07
	dw Tile_FlipV  ; 08
	dw Tile_Flip1  ; 09
	dw Tile_Flip2  ; 0A
	dw Tile_Flip3  ; 0B
	dw Tile_ScoreV ; 0C
	dw Tile_Score1 ; 0D
	dw Tile_Score2 ; 0E
	dw Tile_Score3 ; 0F

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

Tile_Empty:
	LDX.w #EmptyTile
	BRA DrawAt9x9Address

Tile_FlipA:
	LDX.w #FlipATile
	BRA DrawAt9x9Address

Tile_FlipB:
	LDX.w #FlipBTile
	BRA DrawAt9x9Address

Tile_Flip1:
	LDX.w #Flip1Tile
	BRA DrawAt9x9Address

Tile_Flip2:
	LDX.w #Flip2Tile
	BRA DrawAt9x9Address

Tile_Flip3:
	LDX.w #Flip3Tile
	BRA DrawAt9x9Address

Tile_FlipV:
	LDX.w #FlipVTile
	BRA DrawAt9x9Address

Tile_Score1:
	LDX.w #Score1Tile
	BRA DrawAt9x9Address

Tile_Score2:
	LDX.w #Score2Tile
	BRA DrawAt9x9Address

Tile_Score3:
	LDX.w #Score3Tile
	BRA DrawAt9x9Address

Tile_ScoreV:
	LDX.w #ScoreVTile
	BRA DrawAt9x9Address

;===================================================================================================

DrawAt9x9Address:
	STX.b NMISCRATCH

	TAX

	LDA.w DrawAtMain,X
	PHA

	ADC.w #$0020
	PHA

	ADC.w #$0020
	STA.w VMADDR

	LDX.b NMISCRATCH

	LDA.w $800000+$0C,X
	STA.w VMDATA

	LDA.w $800000+$0E,X
	STA.w VMDATA

	LDA.w $800000+$10,X
	STA.w VMDATA

	PLA
	STA.w VMADDR

	LDA.w $800000+$06,X
	STA.w VMDATA

	LDA.w $800000+$08,X
	STA.w VMDATA

	LDA.w $800000+$0A,X
	STA.w VMDATA

	PLA
	STA.w VMADDR

	LDA.w $800000+$00,X
	STA.w VMDATA

	LDA.w $800000+$02,X
	STA.w VMDATA

	LDA.w $800000+$04,X
	STA.w VMDATA

	RTS

;---------------------------------------------------------------------------------------------------

DrawAtMain:
	dw (BOARDMAP>>1)+(($20*$02)+$02)
	dw (BOARDMAP>>1)+(($20*$02)+$06)
	dw (BOARDMAP>>1)+(($20*$02)+$0A)
	dw (BOARDMAP>>1)+(($20*$02)+$0E)
	dw (BOARDMAP>>1)+(($20*$02)+$12)

	dw (BOARDMAP>>1)+(($20*$06)+$02)
	dw (BOARDMAP>>1)+(($20*$06)+$06)
	dw (BOARDMAP>>1)+(($20*$06)+$0A)
	dw (BOARDMAP>>1)+(($20*$06)+$0E)
	dw (BOARDMAP>>1)+(($20*$06)+$12)

	dw (BOARDMAP>>1)+(($20*$0A)+$02)
	dw (BOARDMAP>>1)+(($20*$0A)+$06)
	dw (BOARDMAP>>1)+(($20*$0A)+$0A)
	dw (BOARDMAP>>1)+(($20*$0A)+$0E)
	dw (BOARDMAP>>1)+(($20*$0A)+$12)

	dw (BOARDMAP>>1)+(($20*$0E)+$02)
	dw (BOARDMAP>>1)+(($20*$0E)+$06)
	dw (BOARDMAP>>1)+(($20*$0E)+$0A)
	dw (BOARDMAP>>1)+(($20*$0E)+$0E)
	dw (BOARDMAP>>1)+(($20*$0E)+$12)

	dw (BOARDMAP>>1)+(($20*$12)+$02)
	dw (BOARDMAP>>1)+(($20*$12)+$06)
	dw (BOARDMAP>>1)+(($20*$12)+$0A)
	dw (BOARDMAP>>1)+(($20*$12)+$0E)
	dw (BOARDMAP>>1)+(($20*$12)+$12)

;---------------------------------------------------------------------------------------------------

DrawAtAnnotation:
	dw (NOTESMAP>>1)+(($20*$02)+$02)
	dw (NOTESMAP>>1)+(($20*$02)+$06)
	dw (NOTESMAP>>1)+(($20*$02)+$0A)
	dw (NOTESMAP>>1)+(($20*$02)+$0E)
	dw (NOTESMAP>>1)+(($20*$02)+$12)

	dw (NOTESMAP>>1)+(($20*$06)+$02)
	dw (NOTESMAP>>1)+(($20*$06)+$06)
	dw (NOTESMAP>>1)+(($20*$06)+$0A)
	dw (NOTESMAP>>1)+(($20*$06)+$0E)
	dw (NOTESMAP>>1)+(($20*$06)+$12)

	dw (NOTESMAP>>1)+(($20*$0A)+$02)
	dw (NOTESMAP>>1)+(($20*$0A)+$06)
	dw (NOTESMAP>>1)+(($20*$0A)+$0A)
	dw (NOTESMAP>>1)+(($20*$0A)+$0E)
	dw (NOTESMAP>>1)+(($20*$0A)+$12)

	dw (NOTESMAP>>1)+(($20*$0E)+$02)
	dw (NOTESMAP>>1)+(($20*$0E)+$06)
	dw (NOTESMAP>>1)+(($20*$0E)+$0A)
	dw (NOTESMAP>>1)+(($20*$0E)+$0E)
	dw (NOTESMAP>>1)+(($20*$0E)+$12)

	dw (NOTESMAP>>1)+(($20*$12)+$02)
	dw (NOTESMAP>>1)+(($20*$12)+$06)
	dw (NOTESMAP>>1)+(($20*$12)+$0A)
	dw (NOTESMAP>>1)+(($20*$12)+$0E)
	dw (NOTESMAP>>1)+(($20*$12)+$12)

;===================================================================================================

NMI_WriteVoltorbHints:
	REP #$31

	PHD
	LDA.w #$2100
	TCD

	; do all voltorb counts first, because vertical writes
	LDA.w #$0081
	STA.b VMAIN

	; rows
	LDX.w #((NOTESMAP>>1)+(($20*$03)+$18))
	STX.b VMADDR
	LDA.w VOLTNUMTILES+0
	STA.b VMDATA
	ORA.w #$0010
	STA.b VMDATA

	LDX.w #((NOTESMAP>>1)+(($20*$07)+$18))
	STX.b VMADDR
	LDA.w VOLTNUMTILES+2
	STA.b VMDATA
	ORA.w #$0010
	STA.b VMDATA

	LDX.w #((NOTESMAP>>1)+(($20*$0B)+$18))
	STX.b VMADDR
	LDA.w VOLTNUMTILES+4
	STA.b VMDATA
	ORA.w #$0010
	STA.b VMDATA

	LDX.w #((NOTESMAP>>1)+(($20*$0F)+$18))
	STX.b VMADDR
	LDA.w VOLTNUMTILES+6
	STA.b VMDATA
	ORA.w #$0010
	STA.b VMDATA

	LDX.w #((NOTESMAP>>1)+(($20*$13)+$18))
	STX.b VMADDR
	LDA.w VOLTNUMTILES+8
	STA.b VMDATA
	ORA.w #$0010
	STA.b VMDATA

	; columns
	LDX.w #((NOTESMAP>>1)+(($20*$17)+$04))
	STX.b VMADDR
	LDA.w VOLTNUMTILES+10
	STA.b VMDATA
	ORA.w #$0010
	STA.b VMDATA

	LDX.w #((NOTESMAP>>1)+(($20*$17)+$08))
	STX.b VMADDR
	LDA.w VOLTNUMTILES+12
	STA.b VMDATA
	ORA.w #$0010
	STA.b VMDATA

	LDX.w #((NOTESMAP>>1)+(($20*$17)+$0C))
	STX.b VMADDR
	LDA.w VOLTNUMTILES+14
	STA.b VMDATA
	ORA.w #$0010
	STA.b VMDATA

	LDX.w #((NOTESMAP>>1)+(($20*$17)+$10))
	STX.b VMADDR
	LDA.w VOLTNUMTILES+16
	STA.b VMDATA
	ORA.w #$0010
	STA.b VMDATA

	LDX.w #((NOTESMAP>>1)+(($20*$17)+$14))
	STX.b VMADDR
	LDA.w VOLTNUMTILES+18
	STA.b VMDATA
	ORA.w #$0010
	STA.b VMDATA

;---------------------------------------------------------------------------------------------------

	; now do score hints
	LDA.w #$0080
	STA.b VMAIN

	; rows first
	LDX.w #((NOTESMAP>>1)+(($20*$02)+$17))
	STX.b VMADDR

	LDA.w HINTNUMTILES+0
	STA.b VMDATA

	LDA.w HINTNUMTILES+2
	STA.b VMDATA

	LDX.w #((NOTESMAP>>1)+(($20*$06)+$17))
	STX.b VMADDR

	LDA.w HINTNUMTILES+4
	STA.b VMDATA

	LDA.w HINTNUMTILES+6
	STA.b VMDATA

	LDX.w #((NOTESMAP>>1)+(($20*$0A)+$17))
	STX.b VMADDR

	LDA.w HINTNUMTILES+8
	STA.b VMDATA

	LDA.w HINTNUMTILES+10
	STA.b VMDATA

	LDX.w #((NOTESMAP>>1)+(($20*$0E)+$17))
	STX.b VMADDR

	LDA.w HINTNUMTILES+12
	STA.b VMDATA

	LDA.w HINTNUMTILES+14
	STA.b VMDATA

	LDX.w #((NOTESMAP>>1)+(($20*$12)+$17))
	STX.b VMADDR

	LDA.w HINTNUMTILES+16
	STA.b VMDATA

	LDA.w HINTNUMTILES+18
	STA.b VMDATA

	; now columns
	LDX.w #((NOTESMAP>>1)+(($20*$16)+$03))
	STX.b VMADDR

	LDA.w HINTNUMTILES+20
	STA.b VMDATA

	LDA.w HINTNUMTILES+22
	STA.b VMDATA

	LDX.w #((NOTESMAP>>1)+(($20*$16)+$07))
	STX.b VMADDR

	LDA.w HINTNUMTILES+24
	STA.b VMDATA

	LDA.w HINTNUMTILES+26
	STA.b VMDATA

	LDX.w #((NOTESMAP>>1)+(($20*$16)+$0B))
	STX.b VMADDR

	LDA.w HINTNUMTILES+28
	STA.b VMDATA

	LDA.w HINTNUMTILES+30
	STA.b VMDATA

	LDX.w #((NOTESMAP>>1)+(($20*$16)+$0F))
	STX.b VMADDR

	LDA.w HINTNUMTILES+32
	STA.b VMDATA

	LDA.w HINTNUMTILES+34
	STA.b VMDATA

	LDX.w #((NOTESMAP>>1)+(($20*$16)+$13))
	STX.b VMADDR

	LDA.w HINTNUMTILES+36
	STA.b VMDATA

	LDA.w HINTNUMTILES+38
	STA.b VMDATA

	PLD

	SEP #$30
	RTS

;===================================================================================================

NMI_DrawPressStart:
	REP #$20

	LDA.w #.start
	STA.w DMA7ADDR

	LDA.w #$1801

	BRA NMI_StartWords

.start
	dw $3C01
	dw $3C02
	dw $3C03
	dw $3C04
	dw $3C04
	dw $0000
	dw $0000
	dw $3C04
	dw $3C05
	dw $3C06
	dw $3C02
	dw $3C05

;===================================================================================================

NMI_DeletePressStart:
	REP #$20

	LDA.w #ZeroLand
	STA.w DMA7ADDR

	LDA.w #$1809

;===================================================================================================

NMI_StartWords:
	STA.w DMA7MODE

	LDA.w #24
	STA.w DMA7SIZE

	LDA.w #$D3D4>>1
	STA.w VMADDR

	LDX.b #$80
	STX.w DMA7ADDRB
	STX.w VMAIN

	STX.w MDMAEN

	RTS


;===================================================================================================

NMI_DrawGameCursor:
	REP #$20

	LDA.w #$80
	STA.w OAMADDR

	LDY.b CURX
	STY.w OAMDATA

	LDY.b CURY
	STY.w OAMDATA

	LDY.b CURTILE
	STY.w OAMDATA

	LDY.b CURPROP
	STY.w OAMDATA

	LDA.w #$0108
	STA.w OAMADDR

	LDY.b CURSX
	STY.w OAMDATA

	RTS

;===================================================================================================

NMI_DrawVoltorbIcons:
	REP #$30

	LDX.w #20

.next
	LDY.w .address-2,X
	TYA
	CLC
	ADC.w #$0020
	STA.w VMADDR

	LDA.w #$0845
	STA.w VMDATA

	ORA.w #$4000
	STA.w VMDATA

	STY.w VMADDR

	LDA.w #$0835
	STA.w VMDATA

	ORA.w #$4000
	STA.w VMDATA

	DEX
	DEX
	BNE .next

	RTS

.address
	dw (NOTESMAP>>1)+(($20*$03)+$16)
	dw (NOTESMAP>>1)+(($20*$07)+$16)
	dw (NOTESMAP>>1)+(($20*$0B)+$16)
	dw (NOTESMAP>>1)+(($20*$0F)+$16)
	dw (NOTESMAP>>1)+(($20*$13)+$16)

	dw (NOTESMAP>>1)+(($20*$17)+$02)
	dw (NOTESMAP>>1)+(($20*$17)+$06)
	dw (NOTESMAP>>1)+(($20*$17)+$0A)
	dw (NOTESMAP>>1)+(($20*$17)+$0E)
	dw (NOTESMAP>>1)+(($20*$17)+$12)

;===================================================================================================

NMI_UpdateCoinDisplay:
	REP #$20
	SEP #$10

	LDY.b #$80
	STY.w DMA7ADDRB
	STY.w VMAIN

	LDA.w #$1801
	STA.w DMA7MODE

	LDA.w #COINCHARS0
	STA.w DMA7ADDR

	LDA.w #$0DAC>>1
	STA.w VMADDR

	LDA.w #16
	STA.w DMA7SIZE

	STY.w MDMAEN

	STA.w DMA7SIZE

	LDA.w #$0DEC>>1
	STA.w VMADDR

	STY.w MDMAEN

	LDA.w #$0E2C>>1
	STA.w VMADDR

	LDA.w #16
	STA.w DMA7SIZE

	STY.w MDMAEN

	RTS

;===================================================================================================

NMI_WriteLevelAndControls:
	REP #$20
	SEP #$10

	LDX.b #$08
	LDY.b #$80

	LDA.w #$1801
	STA.w DMA7MODE

	LDA.w #$0CF4>>1
	STA.w VMADDR

	LDA.w #.tiles
	STA.w DMA7ADDR

	STY.w DMA7ADDRB

	TXA
	STA.w DMA7SIZE

	STY.w MDMAEN

	STA.w DMA7SIZE

	LDA.w #$0D34>>1
	STA.w VMADDR

	STY.w MDMAEN

	LDA.w #$08B4>>1
	STA.w VMADDR

	TXA
	INC
	INC
	TAX
	STA.w DMA7SIZE

	STY.w MDMAEN

	STA.w DMA7SIZE

	LDA.w #$08F4>>1
	STA.w VMADDR

	STY.w MDMAEN

	LDA.w #$0934>>1
	STA.w VMADDR

	TXA
	STA.w DMA7SIZE

	STY.w MDMAEN

	STA.w DMA7SIZE

	LDA.w #$0974>>1
	STA.w VMADDR

	STY.w MDMAEN

	LDA.w #$09B4>>1
	STA.w VMADDR

	TXA
	STA.w DMA7SIZE

	STY.w MDMAEN

	STA.w DMA7SIZE

	LDA.w #$09F4>>1
	STA.w VMADDR

	STY.w MDMAEN

	RTS

;---------------------------------------------------------------------------------------------------

.tiles
	dw $24AC, $0000, $0000, $24AD
	dw $24BB, $24BC, $24BD, $24BE

	dw $24CA, $24CB, $24CC, $24CD, $24CE
	dw $24DA, $24DB, $24DC, $24DD, $24DE

	dw $24EA, $24EB, $24EC, $24ED, $24EE
	dw $24FA, $24FB, $24FC, $24FD, $24FE

	dw $250A, $250B, $250C, $250D, $250E
	dw $251A, $251B, $251C, $251D, $251E

;===================================================================================================

NMI_WriteLevelNumber:
	REP #$30

	LDA.b LEVEL
	AND.w #$0F
	ORA.w #$24E0

	LDX.w #$0CFC>>1
	STX.w VMADDR
	STA.w VMDATA

	ORA.w #$24F0
	LDX.w #$0D3C>>1
	STX.w VMADDR
	STA.w VMDATA

	RTS

;===================================================================================================

NMI_DrawExplosion:
	REP #$20

	LDA.w #$0100
	STA.w OAMADDR

	LDY.w EXPLSX
	STY.w OAMDATA

	STZ.w OAMADDR

	LDA.w #16
	STA.w DMA7SIZE

	LDY.b #$80
	STY.w DMA7ADDRB

	LDA.w #EXPLOSIONOAM
	STA.w DMA7ADDR

	LDA.w #$0400
	STA.w DMA7MODE

	STY.w MDMAEN

	RTS

;===================================================================================================

NMI_CreateTextBox:
	REP #$20

	LDA.w #$1801
	STA.w DMA7MODE

	LDA.w #$D580>>1
	STA.w VMADDR

	LDA.w #$0140
	STA.w DMA7SIZE

	LDA.w #.textbox
	STA.w DMA7ADDR

	LDY.b #$80
	STY.w VMAIN
	STY.w DMA7ADDRB
	STY.w MDMAEN

	RTS

;---------------------------------------------------------------------------------------------------

.textbox
	dw $0000, $2031, $2032, $2033, $2033, $2033, $2033, $2033
	dw $2033, $2033, $2033, $2033, $2033, $2033, $2033, $2033
	dw $2033, $2033, $2033, $2033, $2033, $2033, $2033, $2033
	dw $2033, $2033, $2033, $2033, $2034, $2035, $6031, $0000

	dw $0000, $2041, $2D00, $2D01, $2D02, $2D03, $2D04, $2D05
	dw $2D06, $2D07, $2D08, $2D09, $2D0A, $2D0B, $2D0C, $2D0D
	dw $2D0E, $2D0F, $2D10, $2D11, $2D12, $2D13, $2D14, $2D15
	dw $2D16, $2D17, $2D18, $2D19, $2044, $2045, $6041, $0000

	dw $0000, $2041, $2D1A, $2D1B, $2D1C, $2D1D, $2D1E, $2D1F
	dw $2D20, $2D21, $2D22, $2D23, $2D24, $2D25, $2D26, $2D27
	dw $2D28, $2D29, $2D2A, $2D2B, $2D2C, $2D2D, $2D2E, $2D2F
	dw $2D30, $2D31, $2D32, $2D33, $2044, $2045, $6041, $0000

	dw $0000, $2041, $2036, $203F, $203F, $203F, $203F, $203F
	dw $203F, $203F, $203F, $203F, $203F, $203F, $203F, $203F
	dw $203F, $203F, $203F, $203F, $203F, $203F, $203F, $203F
	dw $203F, $203F, $203F, $203F, $2046, $2045, $6041, $0000

	dw $0000, $2442, $2443, $2443, $2443, $2443, $2443, $2443
	dw $2443, $2443, $2443, $2443, $2443, $2443, $2443, $2443
	dw $2443, $2443, $2443, $2443, $2443, $2443, $2443, $2443
	dw $2443, $2443, $2443, $2443, $2443, $2443, $6442, $0000

;===================================================================================================

NMI_DeleteAllTextChars:
	REP #$20

	LDA.w #FFLand
	STA.w DMA7ADDR

	LDA.w #$1809
	STA.w DMA7MODE

	LDA.w #$1340
	STA.w DMA7SIZE

	LDA.w #$6CC0>>1
	STA.w VMADDR

	LDX.b #$80
	STX.w DMA7ADDRB

	STX.w MDMAEN

	RTS

;===================================================================================================

NMI_TransferTextChars:
	REP #$20

	LDA.b VWFV
	STA.w VMADDR

	LDA.w #VWFB1
	STA.w DMA7ADDR

	LDA.w #$1801
	STA.w DMA7MODE

	LDA.w #$1A0*2
	STA.w DMA7SIZE

	LDY.b #$80
	STY.w DMA7ADDRB
	STY.w VMAIN
	STY.w MDMAEN

	RTS

;===================================================================================================

NMI_TransferPauseMenu:
	REP #$20

	LDA.w #$D800>>1
	STA.w VMADDR

	LDA.w #PAUSEMAP
	STA.w DMA7ADDR

	LDA.w #$1801
	STA.w DMA7MODE

	LDA.w #$0800
	STA.w DMA7SIZE

	LDY.b #$80
	STY.w DMA7ADDRB
	STY.w VMAIN
	STY.w MDMAEN

	RTS

;===================================================================================================

NMI_DrawTotalCoins:
	REP #$20

	LDA.w #$0E5C>>1
	STA.w VMADDR

	LDA.w #TOTALTILESA
	STA.w DMA7ADDR

	LDA.w #$1801
	STA.w DMA7MODE

	LDA.w #32
	STA.w DMA7SIZE

	LDY.b #$80
	STY.w DMA7ADDRB
	STY.w VMAIN
	STY.w MDMAEN

	STA.w DMA7SIZE

	LDA.w #$0E9C>>1
	STA.w VMADDR

	STY.w MDMAEN

	RTS
