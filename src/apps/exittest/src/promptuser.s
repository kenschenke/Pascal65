.include "cbm_kernal.inc"

.import printz, printlnz, getline, _getlineUsed, _getlineBuf, exit
.importzp ptr1
.export promptUser

.data

prompt: .asciiz "Enter string (X to quit): "
resp: .asciiz "You entered "
never: .asciiz "Should never see this!"

.code

.proc promptUser
L1:
    lda #<prompt
    ldx #>prompt
    jsr printz
    jsr getline
    cmp #0
    bne stopPressed
    ; did the user type one character?
    lda _getlineUsed
    cmp #1
    bne L2
    ; was it X?
    lda _getlineBuf
    cmp #'x'
    beq Quit
    cmp #'X'
    bne L2
    ; user wants to quit
Quit:
    lda #1
    rts
L2:
    lda #<resp
    ldx #>resp
    jsr printz
    lda #<_getlineBuf
    sta ptr1
    lda #>_getlineBuf
    sta ptr1 + 1
    ldy _getlineUsed
    lda #0
    sta (ptr1),y
    lda #<_getlineBuf
    ldx #>_getlineBuf
    jsr printlnz
    lda #0
    rts

stopPressed:
    jsr exit
    lda #<never
    ldx #>never
    jsr printlnz
    lda #1
    rts

.endproc
