;
; prgHeader.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; prgHeader routine
;
; The program header is the first code in the program's module. The linker
; puts the BASIC line, the runtime and the libraries before it and jumps
; to it (see rtlayout.inc). The addresses only the linker knows, such as
; the runtime's BSS and the top of the stack, are imports of linker symbols
; (linker.inc).

.include "asm.inc"
.include "asmlib.inc"
.include "linker.inc"
.include "rtlayout.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export writePrgHeader
.export tagBSS_ZPBACKUP, tagBSS_EXITHANDLER

.import runtimeStackSize, initLibraries, incCodeOffset

.bss

astRoot: .res 4

.data

tagBSS_ZPBACKUP: .asciiz "zpbackup"
tagBSS_HEAPBOTTOM: .asciiz "heapbottom"
tagBSS_INTBUF: .asciiz "intbuf"
tagBSS_TENSTABLE: .asciiz "tenstable"
tagBSS_INPUTBUF: .asciiz "inputbuf"
tagBSS_EXITHANDLER: .asciiz "exithandler"
tagStackTop: .asciiz "stacktop"
tagHeapTop: .asciiz "heaptop"
tagRtInit: .asciiz "rtinit"

prgHeader:

    PRG_HEADER_CODE_OFFSET_4 = 89
    PRG_HEADER_CODE_OFFSET_5 = 93
    PRG_HEADER_CODE_OFFSET_6 = 97
    PRG_HEADER_CODE_OFFSET_7 = 99
    PRG_HEADER_CODE_OFFSET_9 = 78
    PRG_HEADER_CODE_OFFSET_10 = 82
    PRG_HEADER_CODE_EXIT_HANDLER_L = 27
    PRG_HEADER_CODE_EXIT_HANDLER_H = 31
    PRG_HEADER_LENGTH = 109
    PRG_HEADER_RTINIT_L = 24

    ; Disable BASIC ROM
    .byte OC_LDA_ZEROPAGE, 1
    .byte OC_AND_IMMEDIATE, $f8
    .byte OC_ORA_IMMEDIATE, $06
    .byte OC_STA_ZEROPAGE, 1

    ; Make a backup copy of page zero
    .byte OC_LDX_IMMEDIATE, 0
    .byte OC_LDA_X_INDEXED_ZP, $04
    .assert * - prgHeader + 1 = PRG_HEADER_CODE_OFFSET_1, error, "header offset"
    .byte OC_STA_ABSOLUTEX, 0, 0   ; PRG_HEADER_CODE_OFFSET_1
    .byte OC_INX
    .byte OC_CPX_IMMEDIATE, $5d
    .byte OC_BNE, $f6

    ; Save the stack pointer
    .byte OC_TSX
    .byte OC_STX_ZEROPAGE, ZP_SAVEDSTACK

    ; The runtime's first call. A dynamic program calls the loader instead,
    ; which loads the runtime and then jumps to RT_RUNTIMEERRORINIT.
    .assert * - prgHeader + 1 = PRG_HEADER_RTINIT_L, error, "header offset"
    .byte OC_JSR, 0, 0          ; PRG_HEADER_RTINIT_L/H (rtinit)

    ; Set the exit handler
    .byte OC_LDA_IMMEDIATE, 0   ; PRG_HEADER_CODE_EXIT_HANDLER_L
    .byte OC_STA_ZEROPAGE, ZP_EXITHANDLER
    .byte OC_LDA_IMMEDIATE, 0   ; PRG_HEADER_CODE_EXIT_HANDLER_H
    .byte OC_STA_ZEROPAGE, ZP_EXITHANDLER + 1

    ; Initialize runtime stack
    .byte OC_LDA_IMMEDIATE, 0
    .byte OC_STA_ZEROPAGE, ZP_SPL
    .byte OC_STA_ZEROPAGE, ZP_STACKFRAMEL
    ; Runtime stack top at the ceiling, a page boundary (grows downward)
    .assert * - prgHeader + 1 = PRG_HEADER_STACKTOP_H, error, "header offset"
    .byte OC_LDA_IMMEDIATE, 0               ; PRG_HEADER_STACKTOP_H
    .byte OC_STA_ZEROPAGE, ZP_SPH
    .byte OC_STA_ZEROPAGE, ZP_STACKFRAMEH

    ; Set the runtime stack size and initialize the stack
    .assert * - prgHeader + 1 = PRG_HEADER_STACKSIZE1_L, error, "header offset"
    .byte OC_LDA_IMMEDIATE, 0   ; PRG_HEADER_STACKSIZE1_L
    .assert * - prgHeader + 1 = PRG_HEADER_STACKSIZE1_H, error, "header offset"
    .byte OC_LDX_IMMEDIATE, 0   ; PRG_HEADER_STACKSIZE1_H
    .byte OC_JSR, .LOBYTE(RT_STACKINIT), .HIBYTE(RT_STACKINIT)

    ; The heap's top, below the stack, and its bottom, after the program
    .assert * - prgHeader + 1 = PRG_HEADER_STACKSIZE2_L, error, "header offset"
    .byte OC_LDA_IMMEDIATE, 0   ; PRG_HEADER_STACKSIZE2_L
    .byte OC_STA_ZEROPAGE, ZP_PTR1L
    .assert * - prgHeader + 1 = PRG_HEADER_STACKSIZE2_H, error, "header offset"
    .byte OC_LDA_IMMEDIATE, 0   ; PRG_HEADER_STACKSIZE2_H
    .byte OC_STA_ZEROPAGE, ZP_PTR1H
    .assert * - prgHeader + 1 = PRG_HEADER_CODE_OFFSET_2, error, "header offset"
    .byte OC_LDA_IMMEDIATE, 0   ; PRG_HEADER_CODE_OFFSET_2
    .assert * - prgHeader + 1 = PRG_HEADER_CODE_OFFSET_3, error, "header offset"
    .byte OC_LDX_IMMEDIATE, 0   ; PRG_HEADER_CODE_OFFSET_3
    .byte OC_JSR, .LOBYTE(RT_HEAPINIT), .HIBYTE(RT_HEAPINIT)

    ; Current nesting level
    .byte OC_LDA_IMMEDIATE, 1
    .byte OC_STA_ZEROPAGE, ZP_NESTINGLEVEL

    ; Switch to upper/lower case character set
    .byte OC_LDA_IMMEDIATE, $0e
    .byte OC_JSR, .LOBYTE(CHROUT), .HIBYTE(CHROUT)

    ; Set the input buffer pointer
    ; PRG_HEADER_CODE_OFFSET_9
    .byte OC_LDA_IMMEDIATE, 0   ; BSS_INPUTBUF low
    .byte OC_STA_ZEROPAGE, ZP_INPUTBUFPTRL
    ; PRG_HEADER_CODE_OFFSET_10
    .byte OC_LDA_IMMEDIATE, 0   ; BSS_INPUTBUF high
    .byte OC_STA_ZEROPAGE, ZP_INPUTBUFPTRH

    ; Clear the input buffer
    .byte OC_JSR, .LOBYTE(RT_CLEARINPUTBUF), .HIBYTE(RT_CLEARINPUTBUF)

    ; Initialize the int buffer
    .byte OC_LDA_IMMEDIATE, 0    ; PRG_HEADER_CODE_OFFSET_4
    .byte OC_STA_ZEROPAGE, ZP_INTPTR
    .byte OC_LDA_IMMEDIATE, 0    ; PRG_HEADER_CODE_OFFSET_5
    .byte OC_STA_ZEROPAGE, ZP_INTPTR + 1

    ; Initialize the integer/ascii table
    ; PRG_HEADER_CODE_OFFSET_6
    .byte OC_LDA_IMMEDIATE, 0    ; BSS_TENSTABLE low
    ; PRG_HEADER_CODE_OFFSET_7
    .byte OC_LDX_IMMEDIATE, 0    ; BSS_TENSTABLE high
    .byte OC_JSR, .LOBYTE(RT_INITTENSTABLE32), .HIBYTE(RT_INITTENSTABLE32)

    ; Initialize file i/o
    .byte OC_JSR, .LOBYTE(RT_INITFILEIO), .HIBYTE(RT_INITFILEIO)

    ; Clear the keyboard buffer
    .byte OC_JSR, .LOBYTE(RT_CLEARKEYBUF), .HIBYTE(RT_CLEARKEYBUF)

    .assert * - prgHeader = PRG_HEADER_LENGTH, error, "header length"

; The header's addresses: the label, the part of it and the offset
.macro hdrTag label, kind, offset
    .addr label
    .byte kind, offset
.endmacro
hdrTags:
    hdrTag tagBSS_ZPBACKUP, LINKADDR_BOTH, PRG_HEADER_CODE_OFFSET_1
    hdrTag tagRtInit, LINKADDR_BOTH, PRG_HEADER_RTINIT_L
    hdrTag tagBSS_EXITHANDLER, LINKADDR_LOW, PRG_HEADER_CODE_EXIT_HANDLER_L
    hdrTag tagBSS_EXITHANDLER, LINKADDR_HIGH, PRG_HEADER_CODE_EXIT_HANDLER_H
    hdrTag tagStackTop, LINKADDR_HIGH, PRG_HEADER_STACKTOP_H
    hdrTag tagHeapTop, LINKADDR_LOW, PRG_HEADER_STACKSIZE2_L
    hdrTag tagHeapTop, LINKADDR_HIGH, PRG_HEADER_STACKSIZE2_H
    hdrTag tagBSS_HEAPBOTTOM, LINKADDR_LOW, PRG_HEADER_CODE_OFFSET_2
    hdrTag tagBSS_HEAPBOTTOM, LINKADDR_HIGH, PRG_HEADER_CODE_OFFSET_3
    hdrTag tagBSS_INPUTBUF, LINKADDR_LOW, PRG_HEADER_CODE_OFFSET_9
    hdrTag tagBSS_INPUTBUF, LINKADDR_HIGH, PRG_HEADER_CODE_OFFSET_10
    hdrTag tagBSS_INTBUF, LINKADDR_LOW, PRG_HEADER_CODE_OFFSET_4
    hdrTag tagBSS_INTBUF, LINKADDR_HIGH, PRG_HEADER_CODE_OFFSET_5
    hdrTag tagBSS_TENSTABLE, LINKADDR_LOW, PRG_HEADER_CODE_OFFSET_6
    hdrTag tagBSS_TENSTABLE, LINKADDR_HIGH, PRG_HEADER_CODE_OFFSET_7
hdrTagsEnd:

.code

; This routine writes the program header, then the calls to the
; libraries' initialization.
; AST root passed in Q
.proc writePrgHeader
    stq astRoot

    ; The header's addresses
    ldx #0
L1: phx
    lda hdrTags+2,x
    tay
    lda hdrTags+3,x
    taz
    lda hdrTags+1,x
    pha
    lda hdrTags,x
    plx
    jsr linkAddressLookup
    pla
    clc
    adc #4
    tax
    cpx #hdrTagsEnd-hdrTags
    bne L1

    ; The runtime stack's size
    lda runtimeStackSize
    sta prgHeader + PRG_HEADER_STACKSIZE1_L
    lda runtimeStackSize+1
    sta prgHeader + PRG_HEADER_STACKSIZE1_H

    ; Write the program header
    ldx #1
    jsr CHKOUT
    ldx #0
:   lda prgHeader,x
    jsr CHROUT
    inx
    cpx #PRG_HEADER_LENGTH
    bne :-

    lda #PRG_HEADER_LENGTH
    jsr incCodeOffset

    ldq astRoot
    jmp initLibraries
.endproc
