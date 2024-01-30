.include "cbm_kernal.inc"
.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp exit

; end of exports
.byte $00, $00, $00

; imports

printlnz: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

exiting: .asciiz "exiting."

.proc exit
    lda #13
    jsr CHROUT
    lda #13
    jsr CHROUT
    ldx #0
:   lda exiting,x
    beq :+
    jsr CHROUT
    inx
    bne :-
    ; restore the stack pointer
:   ldx savedStackPtr
    txs
    ; call the exit handler
    jmp (exitHandler)
.endproc
