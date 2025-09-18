.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "tokenizer.inc"

.export runCompiler

.import loadfile

.data

compilingMsg: .asciiz "Compiling "
tokenizer: .byte "tokenizer"
tokenizerLen:

.code

; This routine loads the compiler modules, one by one, and runs them.
; The null-terminated filename is passed in A/X.
.proc runCompiler
    sta ptr1
    stx ptr1+1
    ; Print a couple CRs
    lda #13
    jsr CHROUT
    jsr CHROUT
    ; Print the compiling message
    ldx #0
:   lda compilingMsg,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   ; Print the filename
    ldy #0
:   lda (ptr1),y
    beq :+
    jsr CHROUT
    iny
    bne :-
:   lda #13
    jsr CHROUT

    ; Load the tokenizer overlay
    ldx #<tokenizer
    ldy #>tokenizer
    lda #tokenizerLen-tokenizer
    jsr loadfile
    lda ptr1
    ldx ptr1+1
    jsr tokenize
    rts
.endproc
