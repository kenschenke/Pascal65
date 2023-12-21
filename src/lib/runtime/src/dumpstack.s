.include "runtime.inc"
.include "cbm_kernal.inc"

.export dumpStack

.import printz, printlnz

.data

digits: .asciiz "0123456789abcdef"
retval: .asciiz "retval: $"
retaddr: .asciiz "retaddr: $"
staticlink: .asciiz "static link: $"
dynlink: .asciiz "dyn link: $"
stackbase: .asciiz "stack base: $"

.code

; Prints the hex number in A
.proc dumpByte
    pha
    lsr
    lsr
    lsr
    lsr
    ldx #<digits
    stx ptr1
    ldx #>digits
    stx ptr1 + 1
    and #$0f
    tay
    lda (ptr1),y
    jsr CHROUT
    pla
    and #$0f
    tay
    lda (ptr1),y
    jmp CHROUT
.endproc

; Dumps the stack frame pointed to by stackP
; (base of the current scope's stack frame)
.proc dumpStack
    lda #<stackbase
    ldx #>stackbase
    jsr printz
    lda stackP + 1
    jsr dumpByte
    lda stackP
    jsr dumpByte
    lda #13
    jsr CHROUT

    lda stackP
    sta ptr4
    lda stackP + 1
    sta ptr4 + 1

    ; Return value
    jsr dec4
    lda #<retval
    ldx #>retval
    jsr printz
    ldy #1
    lda (ptr4),y
    jsr dumpByte
    ldy #0
    lda (ptr4),y
    jsr dumpByte
    lda #13
    jsr CHROUT

    ; Return address
    jsr dec4
    lda #<retaddr
    ldx #>retaddr
    jsr printz
    ldy #1
    lda (ptr4),y
    jsr dumpByte
    ldy #0
    lda (ptr4),y
    jsr dumpByte
    lda #13
    jsr CHROUT

    ; Static link
    jsr dec4
    lda #<staticlink
    ldx #>staticlink
    jsr printz
    ldy #1
    lda (ptr4),y
    jsr dumpByte
    ldy #0
    lda (ptr4),y
    jsr dumpByte
    lda #13
    jsr CHROUT

    ; Dynamic link
    jsr dec4
    lda #<dynlink
    ldx #>dynlink
    jsr printz
    ldy #1
    lda (ptr4),y
    jsr dumpByte
    ldy #0
    lda (ptr4),y
    jsr dumpByte
    lda #13
    jmp CHROUT
.endproc

; Decrement ptr4 by 4
.proc dec4
    lda ptr4
    sec
    sbc #4
    sta ptr4
    lda ptr4 + 1
    sbc #0
    sta ptr4 + 1
    rts
.endproc
