;===================================================================================================
; Load A with 16bit vector in bank00 for an NMI routine to run
;===================================================================================================
AddNMIVector:
	DEC.b NMIVX

	STA.b (NMIVX)

	DEC.b NMIVX

	RTS

;===================================================================================================

Exit_NMI_Fast:
	PLA
	RTI

NMI:
	REP #$30

	PHA
	AND.l RDNMI-1

	LDA.l NMIWAIT
	BNE Exit_NMI_Fast

	JML .fast

.fast
	PHX
	PHY
	PHD
	PHB

	LDA.w #$0000
	TAY
	TCD
	DEC
	STA.b NMIWAIT

	SEP #$10

	STY.w HDMAEN ; Y = 0

	LDX.b #$80
	PHX
	PLB

	STX.w INIDISP
	STX.w VMAIN

;---------------------------------------------------------------------------------------------------

	TSC
	STA.b NMIVSC

	LDA.w #$210C : TCS
	PEA.w $3311
	PEA.w $6B6B
	PEI.b (BG1SCQ)
	PEA.w $0009

	LDA.w #$2131 : TCS
	LDA.w #$0000
	PEI.b (CGWSELQ)
	PHA ; PEA.w $0000
	PEI.b (TMQ)
	PHA ; PEA.w $0000
	PHA ; PEA.w $0000
	PHA ; PEA.w $0000
	PHA ; PEA.w $0000

	STY.w SETINI ; Y already 0
	LDY.b #$62   : STY.w OBSEL
	LDY.b FIXCOL : STY.w COLDATA

	LDY.b BG1HOFF+0 : STY.w BG1HOFS
	LDY.b BG1HOFF+1 : STY.w BG1HOFS

	LDY.b BG1VOFF+0 : STY.w BG1VOFS
	LDY.b BG1VOFF+1 : STY.w BG1VOFS

	LDY.b BG2HOFF+0 : STY.w BG2HOFS
	LDY.b BG2HOFF+1 : STY.w BG2HOFS

	LDY.b BG2VOFF+0 : STY.w BG2VOFS
	LDY.b BG2VOFF+1 : STY.w BG2VOFS

	LDY.b BG3HOFF+0 : STY.w BG3HOFS
	LDY.b BG3HOFF+1 : STY.w BG3HOFS

	LDY.b BG3VOFF+0 : STY.w BG3VOFS
	LDY.b BG3VOFF+1 : STY.w BG3VOFS

;---------------------------------------------------------------------------------------------------
; To minimize the overhead of simple updates,
; all vectorized NMI update routines should exit with:
;   16-bit accumulator
;   8-bit index registers
;   VMAIN set to $80
;   X = $80
;---------------------------------------------------------------------------------------------------
	REP #$20

	LDX.b #$80

	; set return point just to be safe
	LDA.w #NMIVectorsDone-1
	STA.w NMIVTop

	; get vector stack
	LDA.b NMIVX
	TCS

#NMI_Nothing:
	RTS

#NMIVectorsDone:
	LDA.w #NMIVTop-1
	STA.b NMIVX

	LDA.b NMIVSC
	TCS

;---------------------------------------------------------------------------------------------------

	SEP #$30

	LDA.b INIDQ
	STA.w INIDISP

;---------------------------------------------------------------------------------------------------

	PEI.b (JOY1)

	LDA.b #$01

	; wait for auto joypad read to finish
.wait_for_joypad
	BIT.w HVBJOY
	BNE .wait_for_joypad

	REP #$20

	LDA.w JOY1L
	STA.b JOY1

	PLA
	EOR.w #$FFFF
	AND.b JOY1
	STA.b JOY1NEW

;---------------------------------------------------------------------------------------------------

	REP #$F3
	PLB
	PLD
	PLY
	PLX
	PLA

;---------------------------------------------------------------------------------------------------

NoVector:
	RTI

;===================================================================================================

NMI_TransferTileQueue:
	LDA.w BRDUPDATEX
	BEQ .none

	LDA.w #$1604
	STA.w DMA7MODE

	LDA.w #BOARDUPDATES
	STA.w DMA7ADDR

	LDY.b #BOARDUPDATES>>16
	STY.w DMA7ADDRB

	LDA.w BRDUPDATEX
	STA.w DMA7SIZE

	STX.w MDMAEN

	STZ.w BRDUPDATEX

.none
	RTS

;===================================================================================================

NMI_WriteVoltorbHints:
	LDA.w #$1604
	STA.w DMA7MODE

	LDA.w #HINTSBUFFER
	STA.w DMA7ADDR

	STX.w DMA7ADDRB

	LDA.w #$00A0
	STA.w DMA7SIZE

	STX.w MDMAEN

	RTS

;===================================================================================================

NMI_DrawPressStart:
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
	LDA.w #ZeroLand
	STA.w DMA7ADDR

	LDA.w #$1809

;===================================================================================================

NMI_StartWords:
	STA.w DMA7MODE

	LDA.w #24
	STA.w DMA7SIZE

	LDA.w #vma(!BG3MAP+$03D4)
	STA.w VMADDR

	STX.w DMA7ADDRB
	STX.w VMAIN

	STX.w MDMAEN

	RTS

;===================================================================================================

NMI_DrawGameCursor:
	TXA
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
	LDA.w #$1604
	STA.w DMA7MODE

	LDA.w #VoltorbHintIconList
	STA.w DMA7ADDR

	STX.w DMA7ADDRB

	LDA.w #VoltorbHintIconList_end-VoltorbHintIconList
	STA.w DMA7SIZE

	STX.w MDMAEN

	RTS

;---------------------------------------------------------------------------------------------------

macro AddVoltorbIcon(vram)
	dw vma(<vram>+$40), $0835
	dw vma(<vram>+$42), $4835
	dw vma(<vram>+$80), $0845
	dw vma(<vram>+$82), $4845
endmacro
VoltorbHintIconList:
	%AddVoltorbIcon(!ROW1HINTAT)
	%AddVoltorbIcon(!ROW2HINTAT)
	%AddVoltorbIcon(!ROW3HINTAT)
	%AddVoltorbIcon(!ROW4HINTAT)
	%AddVoltorbIcon(!ROW5HINTAT)

	%AddVoltorbIcon(!COL1HINTAT)
	%AddVoltorbIcon(!COL2HINTAT)
	%AddVoltorbIcon(!COL3HINTAT)
	%AddVoltorbIcon(!COL4HINTAT)
	%AddVoltorbIcon(!COL5HINTAT)

.end

;===================================================================================================

NMI_UpdateCoinDisplay:
	STX.w DMA7ADDRB
	STX.w VMAIN

	LDA.w #$1801
	STA.w DMA7MODE

	LDA.w #COINCHARS0
	STA.w DMA7ADDR

	LDA.w #vma(!NOTESMAP+$05AC)
	STA.w VMADDR

	LDA.w #16
	STA.w DMA7SIZE

	STX.w MDMAEN

	STA.w DMA7SIZE

	LDA.w #vma(!NOTESMAP+$05EC)
	STA.w VMADDR

	STX.w MDMAEN

	LDA.w #vma(!NOTESMAP+$062C)
	STA.w VMADDR

	LDA.w #16
	STA.w DMA7SIZE

	STX.w MDMAEN

	RTS

;===================================================================================================

NMI_WriteLevelAndMemo:
	STA.w DMA7SIZE

	LDA.w #$1604
	STA.w DMA7MODE

	STX.w DMA7ADDRB
	STX.w MDMAEN

	LDA.w #.tiles
	STA.w DMA7ADDR

	LDA.w #.end-.tiles
	STA.w DMA7SIZE

	STX.w MDMAEN

	RTS

.tiles
	; (L] Memo
	dw vma(!NOTESMAP+$00B4), $250A
	dw vma(!NOTESMAP+$00B6), $250B
	dw vma(!NOTESMAP+$00B8), $250C
	dw vma(!NOTESMAP+$00BA), $250D
	dw vma(!NOTESMAP+$00BC), $250E

	dw vma(!NOTESMAP+$00F4), $251A
	dw vma(!NOTESMAP+$00F6), $251B
	dw vma(!NOTESMAP+$00F8), $251C
	dw vma(!NOTESMAP+$00FA), $251D
	dw vma(!NOTESMAP+$00FC), $251E

	; Level
	dw vma(!NOTESMAP+$04F4), $24AC
	dw vma(!NOTESMAP+$04FA), $24AD

	dw vma(!NOTESMAP+$0534), $24BB
	dw vma(!NOTESMAP+$0536), $24BC
	dw vma(!NOTESMAP+$0538), $24BD
	dw vma(!NOTESMAP+$053A), $24BE

	; Coin box
	dw vma(!NOTESMAP+$0678), $0C36
	dw vma(!NOTESMAP+$067A), $0C37
	dw vma(!NOTESMAP+$067C), $0C38

	dw vma(!NOTESMAP+$06B8), $0C46
	dw vma(!NOTESMAP+$06BA), $0C47
	dw vma(!NOTESMAP+$06BC), $0C48

.end

;===================================================================================================

NMI_WriteLevelAndControls:
	LDA.w #.tiles
	STA.w DMA7ADDR

	LDA.w #.end-.tiles

	JMP NMI_WriteLevelAndMemo

.tiles
	; (A) Flip
	dw vma(!NOTESMAP+$0134), $24CA
	dw vma(!NOTESMAP+$0136), $24CB
	dw vma(!NOTESMAP+$0138), $24CC
	dw vma(!NOTESMAP+$013A), $24CD
	dw vma(!NOTESMAP+$013C), $0000

	dw vma(!NOTESMAP+$0174), $24DA
	dw vma(!NOTESMAP+$0176), $24DB
	dw vma(!NOTESMAP+$0178), $24DC
	dw vma(!NOTESMAP+$017A), $24DD
	dw vma(!NOTESMAP+$017C), $0000

	; (B) Quit
	dw vma(!NOTESMAP+$01B4), $24EA
	dw vma(!NOTESMAP+$01B6), $24EB
	dw vma(!NOTESMAP+$01B8), $24EC
	dw vma(!NOTESMAP+$01BA), $24ED
	dw vma(!NOTESMAP+$01BC), $24EE

	dw vma(!NOTESMAP+$01F4), $24FA
	dw vma(!NOTESMAP+$01F6), $24FB
	dw vma(!NOTESMAP+$01F8), $24FC
	dw vma(!NOTESMAP+$01FA), $24FD
	dw vma(!NOTESMAP+$01FC), $24FE

.end

;===================================================================================================

NMI_WriteLevelAndMemoing:
	LDA.w #.tiles
	STA.w DMA7ADDR

	LDA.w #.end-.tiles

	JMP NMI_WriteLevelAndMemo

.tiles
	; Face buttons
	dw vma(!NOTESMAP+$0134), $0000
	dw vma(!NOTESMAP+$0136), $2500
	dw vma(!NOTESMAP+$0138), $2501
	dw vma(!NOTESMAP+$013A), $2502
	dw vma(!NOTESMAP+$013C), $0000

	dw vma(!NOTESMAP+$0174), $2510
	dw vma(!NOTESMAP+$0176), $2511
	dw vma(!NOTESMAP+$0178), $2512
	dw vma(!NOTESMAP+$017A), $2513
	dw vma(!NOTESMAP+$017C), $2514

	dw vma(!NOTESMAP+$01B4), $2503
	dw vma(!NOTESMAP+$01B6), $2504
	dw vma(!NOTESMAP+$01B8), $2505
	dw vma(!NOTESMAP+$01BA), $2506
	dw vma(!NOTESMAP+$01BC), $2507

	dw vma(!NOTESMAP+$01F4), $0000
	dw vma(!NOTESMAP+$01F6), $2515
	dw vma(!NOTESMAP+$01F8), $2516
	dw vma(!NOTESMAP+$01FA), $2517
	dw vma(!NOTESMAP+$01FC), $0000

.end


;===================================================================================================

NMI_WriteLevelNumber:
	REP #$10

	LDA.b LEVEL
	AND.w #$0F
	ORA.w #$24E0

	LDY.w #vma(!NOTESMAP+$04FC)
	STY.w VMADDR
	STA.w VMDATA

	ORA.w #$24F0
	LDY.w #vma(!NOTESMAP+$053C)
	STY.w VMADDR
	STA.w VMDATA

	SEP #$10

	RTS

;===================================================================================================

NMI_DrawExplosion:
	LDA.w #$0100
	STA.w OAMADDR

	LDY.w EXPLSX
	STY.w OAMDATA

	STZ.w OAMADDR

	LDA.w #16
	STA.w DMA7SIZE

	STX.w DMA7ADDRB

	LDA.w #EXPLOSIONOAM
	STA.w DMA7ADDR

	LDA.w #$0400
	STA.w DMA7MODE

	STX.w MDMAEN

	RTS

;===================================================================================================

NMI_CreateTextBox:
	LDA.w #$1801
	STA.w DMA7MODE

	LDA.w #vma(!BG3MAP+$0580)
	STA.w VMADDR

	LDA.w #$0140
	STA.w DMA7SIZE

	LDA.w #.textbox
	STA.w DMA7ADDR

	STX.w VMAIN
	STX.w DMA7ADDRB
	STX.w MDMAEN

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
	LDA.w #FFLand
	STA.w DMA7ADDR

	LDA.w #$1809
	STA.w DMA7MODE

	LDA.w #$1340
	STA.w DMA7SIZE

	LDA.w #vma(!BG3CHR+$0CC0)
	STA.w VMADDR

	STX.w DMA7ADDRB

	STX.w MDMAEN

	RTS

;===================================================================================================

NMI_TransferTextChars:
	LDA.b VWFV
	STA.w VMADDR

	LDA.w #VWFB1
	STA.w DMA7ADDR

	LDA.w #$1801
	STA.w DMA7MODE

	LDA.w #$01A0*2
	STA.w DMA7SIZE

	LDX.b #$80
	STX.w DMA7ADDRB
	STX.w VMAIN
	STX.w MDMAEN

	RTS

;===================================================================================================

NMI_TransferPauseMenu:
	LDA.w #vma(!BG3MAP+$0800)
	STA.w VMADDR

	LDA.w #PAUSEMAP
	STA.w DMA7ADDR

	LDA.w #$1801
	STA.w DMA7MODE

	LDA.w #$0800
	STA.w DMA7SIZE

	LDX.b #$80
	STX.w DMA7ADDRB
	STX.w VMAIN
	STX.w MDMAEN

	RTS

;===================================================================================================

NMI_DrawTotalCoins:
	LDA.w #vma(!NOTESMAP+$0658)
	STA.w VMADDR

	LDA.w #TOTALTILESA
	STA.w DMA7ADDR

	LDA.w #$1801
	STA.w DMA7MODE

	LDA.w #32
	STA.w DMA7SIZE

	LDX.b #$80
	STX.w DMA7ADDRB
	STX.w VMAIN
	STX.w MDMAEN

	STA.w DMA7SIZE

	LDA.w #vma(!NOTESMAP+$0698)
	STA.w VMADDR

	STX.w MDMAEN

	RTS

;===================================================================================================
