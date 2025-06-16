;===================================================================================================
;===================================================================================================
; General
;===================================================================================================
;===================================================================================================
function bitn(x) = (1<<x)
function argBit(arg, b) = select(arg, 1<<b, 0)

function lohi(a, b) = a|(b<<8)

;===================================================================================================
; PPU
;===================================================================================================
function vma(addr) = addr>>1

function charprop(char, prop) = (prop<<8)|char

function bgsc(addr, h, v) = ((addr>>9)&$FE)|argBit(h,0)|argBit(v,1)

function bgnba(addra, addrb) = (addra>>13)|(addrb>>9)

function obsel(addr, s) = (addr>>14)|(s<<5)

function hexto555(h) = ((h&$0000F8)<<7)|((h&$00F800)>>6)|((h&$F80000)>>19)

function bgpalx(i) = (i<<4)
function sppalx(i) = $80|(i<<4)

!PAL0 #= $0000
!PAL1 #= $0400
!PAL2 #= $0800
!PAL3 #= $0C00
!PAL4 #= $1000
!PAL5 #= $1400
!PAL6 #= $1800
!PAL7 #= $1C00

!SPAL0 #= $00
!SPAL1 #= $02
!SPAL2 #= $04
!SPAL3 #= $06
!SPAL4 #= $08
!SPAL5 #= $0A
!SPAL6 #= $0C
!SPAL7 #= $0E

!SPRI0 #= $00
!SPRI1 #= $10
!SPRI2 #= $20
!SPRI3 #= $30


;===================================================================================================
; Instructions
;===================================================================================================
macro MVN(src, dest)
	MVN <dest>, <src>
endmacro

macro MVP(src, dest)
	MVP <dest>, <src>
endmacro

macro OperandLabel(name)
	skip 1
	#<name>:
	skip -1
endmacro

function dponly(label) = label&$0000FF
function pageonly(label) = label&$00FF00
function bankonly(label) = label&$FF0000

function NMIVector(n) = n-1

;===================================================================================================

!BAR = "--------------------------------------------------------------------------------"

!PRETTY_ADDR = hex(?here>>16,2),":",hex((?here&$FFFF),4)

!MAXWIDTH = 14
!MAXHEIGHT = 14
!MAXTILES #= !MAXWIDTH*!MAXHEIGHT

!FORALLTILES #= (!MAXTILES*2)-2

!UP = 0
!DOWN = 2
!LEFT = 4
!RIGHT = 6

!FLAG_UP = 1
!FLAG_DOWN = 2
!FLAG_LEFT = 4
!FLAG_RIGHT = 8

;===================================================================================================

!BOARDMAP = $0000
!NOTESMAP = $0800
!BG3MAP = $D000

!BG1CHR = $2000
!BG3CHR = $6000
!VWFCHR #= !BG3CHR+$1000
!OAMCHR = $8000


!ROW1HINTAT #= !NOTESMAP+$00AC
!ROW2HINTAT #= !NOTESMAP+$01AC
!ROW3HINTAT #= !NOTESMAP+$02AC
!ROW4HINTAT #= !NOTESMAP+$03AC
!ROW5HINTAT #= !NOTESMAP+$04AC
!COL1HINTAT #= !NOTESMAP+$0584
!COL2HINTAT #= !NOTESMAP+$058C
!COL3HINTAT #= !NOTESMAP+$0594
!COL4HINTAT #= !NOTESMAP+$059C
!COL5HINTAT #= !NOTESMAP+$05A4


;===================================================================================================

macro endofgfx()
	%endofbank("gfx")
endmacro

macro endofcode()
	%endofbank("code")
endmacro

macro endofdata()
	%endofbank("data")
endmacro

macro endofbank(type)
?here:
	print ""
	print "==== End of <type> bank: $", hex(?here>>16), ":", hex(max((?here&$FFFF)-1, 0), 4)
	print "!BAR"
endmacro

;===================================================================================================
