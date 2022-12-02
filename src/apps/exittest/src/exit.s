.include "cbm_kernal.inc"

.import savedStackPtr, printlnz
.export exit

.data

exiting: .asciiz "Exiting from STOP"

.code

.proc exit
    lda #13
    jsr CHROUT
    lda #13
    jsr CHROUT
    lda #<exiting
    ldx #>exiting
    jsr printlnz
    ; restore the stack pointer
    ldx savedStackPtr
    txs
    ; exit back to BASIC
    rts
.endproc