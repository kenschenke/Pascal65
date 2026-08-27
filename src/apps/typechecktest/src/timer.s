; Routines to time tests

.include "c64.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export getTicks, resetTicks, printMilliseconds

.import printLine

VIC_PAL = $d06f

.bss

intBuf: .res 14

.code

; 32-bit ticks returned in Q
.proc getTicks
    jsr startTimer
    lda #$ff
    tax
    tay
    taz

L1: bit CIA2_TA
    bvs L2
    bpl L1

L2: sbcq CIA2_TA
    rts
.endproc

.proc resetTicks
    lda VIC_PAL
    and #%10000000
    eor #%10000000
    ora #%01000000
    sta CIA2_CRA
    lda #$40
    sta CIA2_CRB
    ldx #3
    lda #$ff
L1: sta CIA2_TA,x
    dex
    bpl L1
    lda #$10
    tsb CIA2_CRA
    tsb CIA2_CRB

    ; Fall through to startTimer
.endproc

.proc startTimer
    lda VIC_PAL
    and #%10000000
    eor #%10000000
    ora #%01000001
    sta CIA2_CRA
    lda #$41
    sta CIA2_CRB
    rts
.endproc

; Prints milliseconds. Microseconds in intOp1.
.proc printMilliseconds
    ; Load $3e8 (1000) into intOp32
    lda #3
    sta intOp32+1
    lda #$e8
    sta intOp32
    lda #0
    sta intOp32+2
    sta intOp32+3
    jsr divInt32            ; Divide by 1000 (convert microseconds to milliseconds)
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt32
    lda #' '
    jsr CHROUT
    lda #<intBuf
    ldx #>intBuf
    jsr printLine
    rts
.endproc
