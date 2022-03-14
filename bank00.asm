Vector_Reset:
	SEI
	REP #$09
	XCE
	JML.l ++

E0Land:
	db $E0

++	ROL.w $420D
	STZ.w NMITIMEN

	PEA.w $2100
	PLD

	LDX.b #$80
	PHX
	PLB

	STX.b INIDISP
	STX.b VMAIN

	STZ.b $2182

	REP #$20

	STZ.b $2181
	STZ.b VMADDR

	LDA.w #$4300
	TCD

	LDA.w #ZeroLand
	STA.b DMA0ADDR
	STA.b DMA1ADDR

	STX.b DMA0ADDRB
	STX.b DMA1ADDRB

	STZ.b DMA0SIZE
	STZ.b DMA1SIZE

	LDA.w #$1809
	STA.b DMA0MODE

	LDA.w #$8008
	STA.b DMA1MODE

	LDX.b #$03
	STX.w MDMAEN

;---------------------------------------------------------------------------------------------------

	LDY.b #$00
	STY.w CGADD

	LDA.w #$2200
	STA.b DMA1MODE

	LDA.w #TheOnlyBGPalettes
	STA.b DMA1ADDR

	LDA.w #32*3
	STA.b DMA1SIZE

	DEX
	STX.w MDMAEN

	STA.b DMA1SIZE

	LDY.b #$80
	STY.w CGADD

	STX.w MDMAEN

;---------------------------------------------------------------------------------------------------

	LDA.w #$0800
	STA.b DMA0SIZE

	DEX
	STX.w MDMAEN

	STZ.w OAMADDR

	LDA.w #$0408
	STA.b DMA0MODE

	LDA.w #E0Land
	STA.b DMA0ADDR

	LDA.w #$0200
	STA.b DMA0SIZE

	STX.w MDMAEN

	LDA.w #$0020
	STA.b DMA0SIZE

	LDA.w #ZeroLand
	STA.b DMA0ADDR

	STX.w MDMAEN

;---------------------------------------------------------------------------------------------------

	LDA.w #$1801
	STA.b DMA0MODE

	LDA.w #BaseTileMap
	STA.b DMA0ADDR

	STZ.w VMADDR

	LDA.w #$0800
	STA.b DMA0SIZE

	STX.w MDMAEN

	LDY.b #TileGraphics>>16
	STY.w DMA0ADDRB

	ASL
	STA.w VMADDR

	LDA.w #TileGraphics
	STA.b DMA0ADDR

	LDA.w #SpriteGraphics-TileGraphics
	STA.b DMA0SIZE

	STX.w MDMAEN

	LDA.w #BG3Graphics-SpriteGraphics
	STA.b DMA0SIZE

	LDA.w #$4000
	STA.w VMADDR

	STX.w MDMAEN

	LDA.w #EndOfBG3-BG3Graphics
	STA.w DMA0SIZE

	LDA.w #$3000
	STA.w VMADDR

	STX.w MDMAEN

;===================================================================================================

	LDA.w #$1FFD
	TCS
	PLD

	LDA.w #$FFFF
	STA.b BG1VOFF
	STA.b BG2VOFF
	STA.b BG3VOFF

	LDA.l $7FBEBE
	STA.b SEEDX

	LDA.l $7FEBEB
	STA.b SEEDY

	LDA.b SEEDX
	ORA.b SEEDY
	BNE .initialfine

	LDA.w #$BEBE
	STA.b SEEDX

	LDA.w #$A3C6
	STA.b SEEDY

.initialfine
	JSR VerifySRAM

	LDA.w WINNINGS
	BEQ ++

	EOR.l SEEDY
	BEQ ++

	STA.l SEEDY

++	LDA.w WINNINGS+2
	BEQ ++

	EOR.l SEEDX
	BEQ ++

	STA.l SEEDX

++	SEP #$30

	LDA.b #$0F
	STA.b INIDQ

	STZ.b BG2SCQ

	LDA.b #$04
	STA.b BG1SCQ

;===================================================================================================

Module_StartScreen:
	LDA.b #$81
	STA.w NMITIMEN

	LDA.b #$17
	STA.w TMQ

	JSL ResetNMIVectors

	JSR DarkenGameBoard

	REP #$20

	STZ.b FRAME

.wait
	LDA.b FRAME
	AND.w #$001F
	BEQ .no_change

	LDA.b FRAME-1
	ASL
	ASL
	ASL

	LDA.w #NMI_DrawPressStart
	BCC ++

	LDA.w #NMI_DeletePressStart

++	JSL AddNMIVector

.no_change
	JSL WaitForNMI

	JSL Random
	JSL Random
	JSL Random

	LDA.b JOY1A
	AND.w #$0010

	BEQ .wait

	JML StartTheGame

;===================================================================================================

VerifySRAM:
	REP #$20
	SEP #$10

	LDA.w #$0000

	LDX.b #$7C

.next
	CLC
	ADC.l SRAMBASE+2,X

	DEX
	DEX
	BNE .next

	CMP.l SRAMBASE+0
	BNE DeleteSRAM

	EOR.w #$FFFF
	CMP.l SRAMBASE+2
	BNE DeleteSRAM

	LDA.w #$6562
	CMP.l SRAMBASE+4
	BNE DeleteSRAM

	LDA.w #$6562
	CMP.l SRAMBASE+6
	BNE DeleteSRAM

;===================================================================================================

LoadSRAM:
	LDX.b #$80

.next
	LDA.l SRAMBASE-2,X
	STA.w SMIRROR-2,X

	DEX
	DEX
	BNE .next

;===================================================================================================

UpdateSRAM:
	REP #$20
	SEP #$10

	LDA.w #$6562
	STA.w BBBB+0
	STA.w BBBB+2

	LDA.w #$FFFF
	STA.w CKSM2

	INC
	STA.w CKSM1

	LDX.b #$7C

.next
	CLC
	ADC.w SMIRROR+2,X

	DEX
	DEX
	BNE .next

	STA.w CKSM1

	EOR.w #$FFFF
	STA.w CKSM2

	LDX.b #$80

.copy
	LDA.w SMIRROR-2,X
	STA.l SRAMBASE-2,X

	DEX
	DEX
	BNE .copy

	RTS

;===================================================================================================

DeleteSRAM:
	LDX.b #$80

	LDA.w #$0000

.next
	STA.l SRAMBASE-2,X

	DEX
	DEX
	BNE .next

	BRA LoadSRAM

;===================================================================================================

WaitForNMI_x_times:
--	JSL WaitForNMI

	DEX
	BNE --

;---------------------------------------------------------------------------------------------------

ResetNMIVectors:
	PHP

	REP #$20

	STZ.b NMIVC

	LDA.w #NMIV
	STA.b NMIVV

	PLP
	RTL

;===================================================================================================

WaitForNMI:
	PHP

	REP #$20
	PHA

	STZ.b NMIWAIT

--	LDA.b NMIWAIT
	JSL Random
	BEQ --

	INC.b FRAME

	LDA.w #$FFFF
	STA.b NMIWAIT

	PLA
	PLP

	RTL

;===================================================================================================

Random:
	PHP

	REP #$20

	LDA.b SEEDX
	ASL
	ROL
	ROL
	ROL
	ROL
	EOR.b SEEDX
	STA.b SEEDZ

	LDA.b SEEDY
	STA.b SEEDX

	LDA.b SEEDZ
	LSR
	ROR
	ROR
	EOR.b SEEDZ
	STA.b SEEDZ

	LDA.b SEEDY
	ROR
	EOR.b SEEDY
	EOR.b SEEDZ
	STA.b SEEDY

	PLP

WaitForDivision:
	RTL

;===================================================================================================

function hexto555(h) = ((((h&$FF)/8)<<10)|(((h>>8&$FF)/8)<<5)|(((h>>16&$FF)/8)<<0))

TheOnlyBGPalettes:
; HUD
dw hexto555($28A068), hexto555($484040), hexto555($F8F8F8), hexto555($F84868)
dw hexto555($28A068), hexto555($484040), hexto555($B8B8B8), hexto555($B80030)
dw hexto555($28A068), hexto555($484040), hexto555($F8F8F8), hexto555($F84868)
dw hexto555($28A068), hexto555($A0A0A8), hexto555($505058), hexto555($F8F8F8)

; background
dw hexto555($28A068), hexto555($28A068), hexto555($188060), hexto555($282828)
dw hexto555($404040), hexto555($D0E8E0), hexto555($E07050), hexto555($40A840)
dw hexto555($E8A038), hexto555($3090F8), hexto555($C060E0), hexto555($F8F8F8)
dw hexto555($F8E018), hexto555($A8C8B8), hexto555($F8F8F8), hexto555($000000)

dw hexto555($28A068), hexto555($28A068), hexto555($686870), hexto555($282828)
dw hexto555($404040), hexto555($D0E8E0), hexto555($E07050), hexto555($A05850)
dw hexto555($B88880), hexto555($808080), hexto555($A0B0A8), hexto555($F8F8F8)
dw hexto555($F8E018), hexto555($A8C8B8), hexto555($F8F8F8), hexto555($A8C8B8)

;===================================================================================================

TheOnlySPPalettes:
dw hexto555($28A068), hexto555($28A068), hexto555($686870), hexto555($282828)
dw hexto555($404040), hexto555($D0E8E0), hexto555($785820), hexto555($F8B830)
dw hexto555($683028), hexto555($F84030), hexto555($000000), hexto555($000000)
dw hexto555($F8E018), hexto555($000000), hexto555($000000), hexto555($000000)

dw hexto555($28A068), hexto555($000000), hexto555($B84018), hexto555($804050)
dw hexto555($404040), hexto555($F85070), hexto555($F8D890), hexto555($F8C840)
dw hexto555($F88858), hexto555($000000), hexto555($000000), hexto555($000000)
dw hexto555($000000), hexto555($A8B8A8), hexto555($000000), hexto555($000000)
