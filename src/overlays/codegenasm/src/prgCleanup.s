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
.import tagBSS_ZPBACKUP, chainPrgLength, writeChainCode

.data

PRG_CLEANUP_OFFSET = 9
PRG_CLEANUP_LENGTH = 18
prgCleanupData:
    .byte OC_JSR, .lobyte(RT_STACKCLEANUP), .hibyte(RT_STACKCLEANUP)

    ; Close all open files and clear I/O channels
    .byte OC_JSR, .lobyte(CLALL), .hibyte(CLALL)

    ; Copy the backup of zero page back
    .byte OC_LDX_IMMEDIATE, 0
    .assert * - prgCleanupData + 1 = PRG_CLEANUP_OFFSET, error, "offset"
    .byte OC_LDA_ABSOLUTEX, 0, 0
    .byte OC_STA_X_INDEXED_ZP, $04
    .byte OC_INX
    .byte OC_CPX_IMMEDIATE, $62
    .byte OC_BNE, $f6
    .assert * - prgCleanupData = PRG_CLEANUP_LENGTH, error, "length"

; The header switches the BASIC ROM out of $A000-$BFFF, and a program that
; returns to BASIC switches it back in. A large program's cleanup is under
; the ROM itself, so the instruction after the switch would be read from
; the ROM. The cleanup writes this stub below it, at the chain loader's
; address (free for program use, see prgChain.s), and switches the ROM in
; from there. A program that chains to another leaves the ROM out: the
; next program's header switches it out anyway.
EXIT_STUB = $1600
.macro stubByte offset, value
    .byte OC_LDA_IMMEDIATE, value
    .byte OC_STA_ABSOLUTE, .lobyte(EXIT_STUB+offset), .hibyte(EXIT_STUB+offset)
.endmacro
prgExitData:
    stubByte 0, OC_STA_ZEROPAGE     ; sta $01
    stubByte 1, 1
    stubByte 2, OC_LDA_IMMEDIATE    ; lda #0
    stubByte 3, 0
    stubByte 4, OC_RTS              ; rts
    ; Re-enable BASIC ROM
    .byte OC_LDA_ZEROPAGE, 1
    .byte OC_ORA_IMMEDIATE, 1
    .byte OC_JMP, .lobyte(EXIT_STUB), .hibyte(EXIT_STUB)
PRG_EXIT_LENGTH = * - prgExitData

.code

.proc prgCleanup
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
    ldx #0
L1: lda prgExitData,x
    jsr CHROUT
    inx
    cpx #PRG_EXIT_LENGTH
    bne L1
    lda #PRG_EXIT_LENGTH
    jmp incCodeOffset

:   jsr writeChainCode
    rts
.endproc
