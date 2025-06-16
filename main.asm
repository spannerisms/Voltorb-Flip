hirom

math pri on

arch 65816

org $808000
incsrc "registers.asm"
incsrc "defines.asm"
incsrc "ram.asm"
table "charmap.txt"

org $C10000
TileGraphics:
incbin "background.4bpp"

SpriteGraphics:
incbin "sprites.4bpp"

BG3Graphics:
incbin "bg3.2bpp"

EndOfBG3:

org $808000
incsrc "bank00.asm"
incsrc "nmi.asm"
incsrc "pause.asm"
incsrc "text.asm"
incsrc "game.asm"
incsrc "animation.asm"

print "Code end: ", pc

incsrc "header.asm"

org $83FFFF
db 0
