;
; prgCleanup.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; prgCleanup routine

.include "asm.inc"
.include "asmlib.inc"
.include "linker.inc"
.include "codegen.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"

.export prgCleanup

.import genOneInstruction, genTwoInstruction, incCodeOffset
.import tagBSS_ZPBACKUP, tagBSS_EXITHANDLER, chainPrgLength, writeChainCode

.data

PRG_CLEANUP_OFFSET = 15
PRG_CLEANUP_LENGTH = 24
prgCleanupData:
    .byte OC_JSR, .lobyte(RT_STACKCLEANUP), .hibyte(RT_STACKCLEANUP)

    ; Re-enable BASIC ROM
    .byte OC_LDA_ZEROPAGE, 1
    .byte OC_ORA_IMMEDIATE, 1
    .byte OC_STA_ZEROPAGE, 1

    ; Close all open files and clear I/O channels
    .byte OC_JSR, .lobyte(CLALL), .hibyte(CLALL)

    ; Copy the backup of zero page back
    .byte OC_LDX_IMMEDIATE, 0
    .byte OC_LDA_ABSOLUTEX, 0, 0
    .byte OC_STA_X_INDEXED_ZP, $04
    .byte OC_INX
    .byte OC_CPX_IMMEDIATE, $62
    .byte OC_BNE, $f6

.code

.proc prgCleanup
    lda #<tagBSS_EXITHANDLER
    ldx #>tagBSS_EXITHANDLER
    jsr linkAddressSet

    lda #<tagBSS_ZPBACKUP
    ldx #>tagBSS_ZPBACKUP
    ldy #LINKADDR_BOTH
    ldz #PRG_CLEANUP_OFFSET
    jsr linkAddressLookup

    ldx #1
    jsr CHKOUT

    ldx #0
:   lda prgCleanupData,x
    jsr CHROUT
    inx
    cpx #PRG_CLEANUP_LENGTH
    bne :-
    lda #PRG_CLEANUP_LENGTH
    jsr incCodeOffset

    lda chainPrgLength
    bne :+
    genTwoImmediate OC_LDA_IMMEDIATE, 0
    genOne OC_RTS
    rts

:   jsr writeChainCode
    rts
.endproc
