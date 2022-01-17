
;===================================================================================================

ResetVWF:
	REP #$30

	STZ.b VWFL
	STZ.b VWFD
	STZ.b VWFP
	STZ.b VWFX

	LDX.w #$1A0
	LDA.w #$FFFF

--	STA.w VWFB1-2,X
	STA.w VWFB2-2,X

	DEX
	DEX
	BNE --

	RTL

;===================================================================================================

DrawOneCharFrame:
	JSL DrawLetterToVWF

	LDA.w #$7000>>1
	STA.b VWFV

	LDA.w #NMI_TransferTextChars
	JSL AddNMIVector
	JML WaitForNMI

;===================================================================================================

DrawLetterToVWF:
	PHB
	PHK
	PLB

	PHP

	REP #$30
	PHY
	PHX

	AND.w #$00FF
	STA.b VWFL
	STA.b SCRATCH+8

	TAX

	; for spaces, which are 0-7, just use first char always
	CMP.w #$0008
	BCS ++

	LDA.w #$0000
	BRA .add

++	SBC.w #$0007

	ASL
	ASL
	ASL
	ASL

.add
	ADC.w #VWFGFX
	STA.b SCRATCH+8

	ADC.w #(VWFGFXEnd-VWFGFX)/2
	STA.b SCRATCH+10

;---------------------------------------------------------------------------------------------------

	LDA.w LetterWidths,X
	AND.w #$00FF
	PHA

	STA.b SCRATCH+6

	CLC
	LDA.w VWFP
	STA.w VWFD

	ADC.b SCRATCH+6
	STA.w VWFP

	PLA
	ASL
	TAX
	LDA.w .size_masks,X
	STA.b VWFM
	STA.b VWFMSA
	STZ.b VWFMSB

	LDA.b VWFD
	AND.w #$FFF8
	ASL
	STA.b VWFX

	LDA.w VWFD
	AND.w #$0007
	STA.w VWFS
	BEQ .no_mask_shift

	TAX

	SEP #$20

.shift_mask
	LSR.b VWFMSA+0
	ROR.b VWFMSB+0

	LSR.b VWFMSA+1
	ROR.b VWFMSB+1

	DEX
	BNE .shift_mask

	REP #$20

.no_mask_shift
	LDA.b VWFMSA
	EOR.w #$FFFF
	STA.b VWFMSA

	LDA.b VWFMSB
	EOR.w #$FFFF
	STA.b VWFMSB

;---------------------------------------------------------------------------------------------------

	LDY.w #$0000

.next_row
	LDA.b (SCRATCH+8),Y
	AND.b VWFM
	STA.b VWF1A
	STZ.b VWF1B

	LDA.b (SCRATCH+10),Y
	AND.b VWFM
	STA.b VWF2A
	STZ.b VWF2B

	LDX.b VWFS
	BEQ ++

	SEP #$20

.shift
	LSR.b VWF1A+0
	ROR.b VWF1B+0

	LSR.b VWF1A+1
	ROR.b VWF1B+1

	LSR.b VWF2A+0
	ROR.b VWF2B+0

	LSR.b VWF2A+1
	ROR.b VWF2B+1

	DEX
	BNE .shift

	REP #$20

++	LDX.w VWFX

	LDA.w VWFB1+16,X
	AND.b VWFMSB
	ORA.b VWF1B
	STA.w VWFB1+16,X

	LDA.w VWFB1+0,X
	AND.b VWFMSA
	ORA.b VWF1A
	STA.w VWFB1+0,X

	LDA.w VWFB2+16,X
	AND.b VWFMSB
	ORA.b VWF2B
	STA.w VWFB2+16,X

	LDA.w VWFB2+0,X
	AND.b VWFMSA
	ORA.b VWF2A
	STA.w VWFB2+0,X

	INX
	INX
	STX.w VWFX

	INY
	INY
	CPY.w #$0010
	BCC .next_row

	REP #$30
	PLX : PLY
	PLP
	PLB

	RTL

.size_masks
	dw $0000
	dw $8080
	dw $C0C0
	dw $E0E0
	dw $F0F0
	dw $F8F8
	dw $FCFC
	dw $FEFE
	dw $FFFF

;===================================================================================================

LetterWidths:
	;  [space]
	db 0, 1, 2, 3, 4, 5, 6, 7

	;  0  1  2  3  4  5  6  7  8  9
	db 6, 6, 6, 6, 6, 6, 6, 6, 6, 6

	;  A  B  C  D  E  F  G  H  I  J  K  L  M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z
	db 6, 6, 6, 6, 6, 6, 6, 6, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6

	;  a  b  c  d  e  f  g  h  i  j  k  l  m  n  o  p  q  r  s  t  u  v  w  x  y  z
	db 6, 6, 6, 6, 6, 5, 6, 6, 3, 5, 6, 4, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6

	;  A  B  X  Y  .  !  ?  ,  :  ;  …  /  (  )  +  -  ⨯  ÷  =  #
	db 7, 7, 7, 7, 5, 5, 5, 5, 5, 5, 6, 6, 4, 4, 6, 6, 6, 6, 6, 6

;===================================================================================================

VWFGFX:
incbin "font.2bpp"

VWFGFXEnd:
