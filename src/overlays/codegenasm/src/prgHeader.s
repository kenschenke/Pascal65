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

.include "asm.inc"
.include "asmlib.inc"
.include "linker.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

STA_ZEROPAGE = 1
AND_IMMEDIATE = 2
ORA_IMMEDIATE = 3
LDA_ZEROPAGE = 4

CODESEG_CEIL = $c000

.export writePrgHeader
.export tagBSS_ZPBACKUP, tagBSS_EXITHANDLER, tagBSS_TENSTABLE, tagBSS_INPUTBUF
.export tagBSS_HEAPBOTTOM, tagBSS_INTBUF

.import genThreeAddr
.import loadLibraries, genRuntime, runtimeStackSize, initLibraries, incCodeOffset

.bss

intBuf: .res 10
astRoot: .res 4

.data

tagInit: .asciiz "init"
tagBSS_ZPBACKUP: .asciiz "zpbackup"
tagBSS_HEAPBOTTOM: .asciiz "heapbottom"
tagBSS_INTBUF: .asciiz "intbuf"
tagBSS_TENSTABLE: .asciiz "tenstable"
tagBSS_INPUTBUF: .asciiz "inputbuf"
tagBSS_EXITHANDLER: .asciiz "exithandler"

prgHeader:

    PRG_HEADER_CODE_OFFSET_1 = 13
    PRG_HEADER_CODE_OFFSET_2 = 62
    PRG_HEADER_CODE_OFFSET_3 = 64
    PRG_HEADER_CODE_OFFSET_4 = 89
    PRG_HEADER_CODE_OFFSET_5 = 93
    PRG_HEADER_CODE_OFFSET_6 = 97
    PRG_HEADER_CODE_OFFSET_7 = 99
    PRG_HEADER_CODE_OFFSET_9 = 78
    PRG_HEADER_CODE_OFFSET_10 = 82
    PRG_HEADER_CODE_EXIT_HANDLER_L = 27
    PRG_HEADER_CODE_EXIT_HANDLER_H = 31
    PRG_HEADER_LENGTH = 109
    PRG_HEADER_STACKSIZE1_L = 47
    PRG_HEADER_STACKSIZE1_H = 49
    PRG_HEADER_STACKSIZE2_L = 54
    PRG_HEADER_STACKSIZE2_H = 58

    ; Disable BASIC ROM
    .byte OC_LDA_ZEROPAGE, 1
    .byte OC_AND_IMMEDIATE, $f8
    .byte OC_ORA_IMMEDIATE, $06
    .byte OC_STA_ZEROPAGE, 1

    ; Make a backup copy of page zero
    .byte OC_LDX_IMMEDIATE, 0
    .byte OC_LDA_X_INDEXED_ZP, $04
    .byte OC_STA_ABSOLUTEX, 0, 0   ; PRG_HEADER_CODE_OFFSET_1
    .byte OC_INX
    .byte OC_CPX_IMMEDIATE, $5d
    .byte OC_BNE, $f6

    ; Save the stack pointer
    .byte OC_TSX
    .byte OC_STX_ZEROPAGE, ZP_SAVEDSTACK

    .byte OC_JSR, .LOBYTE(RT_RUNTIMEERRORINIT), .HIBYTE(RT_RUNTIMEERRORINIT)

    ; Set the exit handler
    .byte OC_LDA_IMMEDIATE, 0   ; PRG_HEADER_CODE_EXIT_HANDLER_L
    .byte OC_STA_ZEROPAGE, ZP_EXITHANDLER
    .byte OC_LDA_IMMEDIATE, 0   ; PRG_HEADER_CODE_EXIT_HANDLER_H
    .byte OC_STA_ZEROPAGE, ZP_EXITHANDLER + 1

    ; Initialize runtime stack
    .byte OC_LDA_IMMEDIATE, 0
    .byte OC_STA_ZEROPAGE, ZP_SPL
    .byte OC_STA_ZEROPAGE, ZP_STACKFRAMEL
    .byte OC_LDA_IMMEDIATE, $c0             ; Runtime stack top at $c000
    .byte OC_STA_ZEROPAGE, ZP_SPH           ; (grows downward)
    .byte OC_STA_ZEROPAGE, ZP_STACKFRAMEH

    ; Set the runtime stack size and initialize the stack
    .byte OC_LDA_IMMEDIATE, 0   ; PRG_HEADER_STACKSIZE1_L
    .byte OC_LDX_IMMEDIATE, 0   ; PRG_HEADER_STACKSIZE1_H
    .byte OC_JSR, .LOBYTE(RT_STACKINIT), .HIBYTE(RT_STACKINIT)

    .byte OC_LDA_IMMEDIATE, 0   ; PRG_HEADER_STACKSIZE2_L
    .byte OC_STA_ZEROPAGE, ZP_PTR1L
    .byte OC_LDA_IMMEDIATE, 0   ; PRG_HEADER_STACKSIZE2_H
    .byte OC_STA_ZEROPAGE, ZP_PTR1H
    .byte OC_LDA_IMMEDIATE, 0   ; PRG_HEADER_CODE_OFFSET_2
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

.code

codeBase = $2001

; This routine writes the BASIC header to the PRG file
; then writes initialization code.
; AST root passed in Q
.proc writePrgHeader
    stq astRoot

    ; Link to next BASIC line
    lda #.LOBYTE(codeBase+14)
    jsr CHROUT
    lda #.HIBYTE(codeBase+14)
    jsr CHROUT

    ; BASIC line number
    lda #10
    jsr CHROUT
    lda #0
    jsr CHROUT

    ; BANK token
    lda #$fe
    jsr CHROUT
    lda #2
    jsr CHROUT

    ; BANK argument
    lda #'0'
    jsr CHROUT

    ; Colon to continue line
    lda #':'
    jsr CHROUT

    ; SYS token
    lda #$9e
    jsr CHROUT

    ; Starting address of code
    lda #.LOBYTE(codeBase+16)
    sta intOp1
    lda #.HIBYTE(codeBase+16)
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    ldx #0
:   lda intBuf,x
    beq :+
    jsr CHROUT
    inx
    bne :-

    ; End of BASIC line
:   lda #0
    jsr CHROUT

    ; End of BASIC program marker
    lda #0
    jsr CHROUT
    jsr CHROUT

    lda #16
    sta codeOffset

    lda #<tagInit
    ldx #>tagInit
    ldy #LINKADDR_BOTH
    ldz #1
    jsr linkAddressLookup

    lda #OC_JMP
    ldx #0
    ldy #0
    jsr genThreeAddr

    ; Dedicate 20 bytes for the Mega65 DMA command block
    ldx #20
    lda #0
:   jsr CHROUT
    dex
    bne :-
    lda #20
    jsr incCodeOffset

    jsr genRuntime

    ldq astRoot
    jsr loadLibraries

    lda #<tagInit
    ldx #>tagInit
    jsr linkAddressSet

    lda #<tagBSS_ZPBACKUP
    ldx #>tagBSS_ZPBACKUP
    ldy #LINKADDR_BOTH
    ldz #PRG_HEADER_CODE_OFFSET_1
    jsr linkAddressLookup

    lda #<tagBSS_HEAPBOTTOM
    ldx #>tagBSS_HEAPBOTTOM
    ldy #LINKADDR_LOW
    ldz #PRG_HEADER_CODE_OFFSET_2
    jsr linkAddressLookup

    lda #<tagBSS_HEAPBOTTOM
    ldx #>tagBSS_HEAPBOTTOM
    ldy #LINKADDR_HIGH
    ldz #PRG_HEADER_CODE_OFFSET_3
    jsr linkAddressLookup

    lda #<tagBSS_INTBUF
    ldx #>tagBSS_INTBUF
    ldy #LINKADDR_LOW
    ldz #PRG_HEADER_CODE_OFFSET_4
    jsr linkAddressLookup

    lda #<tagBSS_INTBUF
    ldx #>tagBSS_INTBUF
    ldy #LINKADDR_HIGH
    ldz #PRG_HEADER_CODE_OFFSET_5
    jsr linkAddressLookup

    lda #<tagBSS_TENSTABLE
    ldx #>tagBSS_TENSTABLE
    ldy #LINKADDR_LOW
    ldz #PRG_HEADER_CODE_OFFSET_6
    jsr linkAddressLookup

    lda #<tagBSS_TENSTABLE
    ldx #>tagBSS_TENSTABLE
    ldy #LINKADDR_HIGH
    ldz #PRG_HEADER_CODE_OFFSET_7
    jsr linkAddressLookup

    lda #<tagBSS_INPUTBUF
    ldx #>tagBSS_INPUTBUF
    ldy #LINKADDR_LOW
    ldz #PRG_HEADER_CODE_OFFSET_9
    jsr linkAddressLookup

    lda #<tagBSS_INPUTBUF
    ldx #>tagBSS_INPUTBUF
    ldy #LINKADDR_HIGH
    ldz #PRG_HEADER_CODE_OFFSET_10
    jsr linkAddressLookup

    lda #<tagBSS_EXITHANDLER
    ldx #>tagBSS_EXITHANDLER
    ldy #LINKADDR_LOW
    ldz #PRG_HEADER_CODE_EXIT_HANDLER_L
    jsr linkAddressLookup

    lda #<tagBSS_EXITHANDLER
    ldx #>tagBSS_EXITHANDLER
    ldy #LINKADDR_HIGH
    ldz #PRG_HEADER_CODE_EXIT_HANDLER_H
    jsr linkAddressLookup

    lda runtimeStackSize
    ldx #PRG_HEADER_STACKSIZE1_L
    sta prgHeader,x
    lda runtimeStackSize+1
    ldx #PRG_HEADER_STACKSIZE1_H
    sta prgHeader,x

    lda #.LOBYTE(CODESEG_CEIL)
    sta intOp1
    lda #.HIBYTE(CODESEG_CEIL)
    sta intOp1+1
    lda runtimeStackSize
    sta intOp2
    lda runtimeStackSize+1
    sta intOp2+1
    jsr subInt16
    lda #4
    sta intOp2
    lda #0
    sta intOp2+1
    jsr subInt16
    lda intOp1
    ldx #PRG_HEADER_STACKSIZE2_L
    sta prgHeader,x
    lda intOp1+1
    ldx #PRG_HEADER_STACKSIZE2_H
    sta prgHeader,x

    ; Write the program header
    ldx #0
:   lda prgHeader,x
    jsr CHROUT
    inx
    cpx #PRG_HEADER_LENGTH
    bne :-

    lda #PRG_HEADER_LENGTH
    jsr incCodeOffset

    ldq astRoot
    jsr initLibraries

    rts
.endproc
