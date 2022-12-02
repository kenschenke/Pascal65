.include "cbm_kernal.inc"

.import getline, printlnz, promptUser
.export savedStackPtr

.bss

savedStackPtr: .res 1

.data

quitMsg: .asciiz "Quitting"

.code

; save the stack pointer
tsx
stx savedStackPtr

; switch to upper/lower case
lda #14
jsr CHROUT

MainLoop:
    jsr promptUser
    cmp #0
    beq MainLoop

lda #<quitMsg
ldx #>quitMsg
jsr printlnz
rts
