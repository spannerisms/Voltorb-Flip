cleartable

org $00FFB0
db "HB"
db "FLIP"
db $00, $00, $00, $00, $00, $00
db $00
db $00
db $00

ZeroLand:
db $00

org $00FFC0
db "kan's Voltorb Flip   "
db $31
db $02
db $07
db $01
db $01
db $33
db $00
dw #$FFFF
dw #$0000

FFLand:
dw $FFFF
dw $FFFF
dw NoVector
dw NoVector
dw NoVector
dw NMI
dw Reset
dw NoVector

dw $FFFF
dw $FFFF
dw NoVector
dw $FFFF
dw NoVector
dw NMI
dw Reset
dw NoVector