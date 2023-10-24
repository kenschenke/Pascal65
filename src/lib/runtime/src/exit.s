.include "cbm_kernal.inc"
.include "runtime.inc"

.import printlnz
.export exit

.data

exiting: .asciiz "exiting."

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
    ; call the exit handler
    jmp (exitHandler)
.endproc
