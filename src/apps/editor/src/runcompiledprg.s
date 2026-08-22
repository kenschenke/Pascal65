;
; runcompiledprg.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; runCompiledPrg routine

.include "asm.inc"
.include "editor.inc"
.include "cbm_kernal.inc"

.export runCompiledPrg

.data

CHAIN_CODE_LENGTH = 42
prgChainCall:
    .byte OC_LDA_IMMEDIATE, CH_CLRSCR
    .byte OC_JSR, .lobyte(CHROUT), .hibyte(CHROUT)

    .byte OC_LDA_IMMEDIATE, 0
    .byte OC_LDX_IMMEDIATE, 8   ; device
    .byte OC_LDY_IMMEDIATE, $ff
    .byte OC_JSR, .lobyte(SETLFS), .hibyte(SETLFS)

    .byte OC_LDA_IMMEDIATE, 9   ; strlen(name)
    .byte OC_LDX_IMMEDIATE, $21 ; lower name address
    .byte OC_LDY_IMMEDIATE, $90 ; upper name address
    .byte OC_JSR, .lobyte(SETNAM), .hibyte(SETNAM)

    .byte OC_LDA_IMMEDIATE, 0
    .byte OC_TAX
    .byte OC_TAY
    .byte OC_JSR, .lobyte(LOAD), .hibyte(LOAD)

    .byte OC_JMP, $11, $20      ; Entry point for loaded program

    .byte "zzprg.prg"

.code

; This routine copies the prgChainCall code to $9000 then jmps to it.
.proc runCompiledPrg
    ldx #0
:   lda prgChainCall,x
    sta $9000,x
    inx
    cpx #CHAIN_CODE_LENGTH
    bne :-
    jmp $9000
.endproc
