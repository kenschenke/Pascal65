;
; runtimeBss.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; The linker symbols
;
; The program header and cleanup use addresses that only the linker knows.
; They import them by name (see linker.inc). The runtime's BSS follows the
; last module, and the heap starts after it.

.include "asm.inc"
.include "rtlayout.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"

ZPINTBUF_LEN = 15
ZPBACKUP_LEN = 97
TENSTABLE_LEN = 40
INPUTBUF_LEN = 80
HEAPBOTTOM_LEN = 2
RTBSS_BUFS = ZPINTBUF_LEN + ZPBACKUP_LEN + TENSTABLE_LEN + INPUTBUF_LEN
RTBSS_LEN = RTBSS_BUFS + HEAPBOTTOM_LEN

LFN_PRG = 3

.export defineLinkerSymbols, writeRuntimeBss, RTBSS_LEN

.import defineSymbol, symName, objMode, stackSize, codeCeiling

.data

; The runtime's BSS, in order, each a name and its length
bssSymbols:
    .asciiz "intbuf"
    .byte ZPINTBUF_LEN
    .asciiz "zpbackup"
    .byte ZPBACKUP_LEN
    .asciiz "tenstable"
    .byte TENSTABLE_LEN
    .asciiz "inputbuf"
    .byte INPUTBUF_LEN
    .asciiz "heapbottom"
    .byte HEAPBOTTOM_LEN
    .byte 0
strStackTop: .asciiz "stacktop"
strHeapTop: .asciiz "heaptop"
strRtInit: .asciiz "rtinit"

.bss

symAddr: .res 2

.code

; This routine defines the linker symbols. The runtime's BSS starts at the
; address in A/X, and the address after it is returned in A/X.
.proc defineLinkerSymbols
    sta symAddr
    stx symAddr+1

    ; The runtime's BSS
    ldy #0
L1: lda bssSymbols,y
    beq L3
    ldx #0
L2: lda bssSymbols,y
    sta symName,x
    iny
    inx
    cmp #0
    bne L2
    phy
    lda symAddr
    ldx symAddr+1
    jsr defineSymbol
    ply
    lda bssSymbols,y            ; Its length
    iny
    clc
    adc symAddr
    sta symAddr
    bcc L1
    inc symAddr+1
    bra L1

    ; The stack's top, at the ceiling
L3: lda #<strStackTop
    ldx #>strStackTop
    jsr copyName
    lda codeCeiling
    ldx codeCeiling+1
    jsr defineSymbol

    ; The heap's top, four bytes below the stack
    lda #<strHeapTop
    ldx #>strHeapTop
    jsr copyName
    lda codeCeiling
    sec
    sbc stackSize
    tay
    lda codeCeiling+1
    sbc stackSize+1
    tax
    tya
    sec
    sbc #4
    bcs :+
    dex
:   jsr defineSymbol

    ; The runtime's first call
    lda #<strRtInit
    ldx #>strRtInit
    jsr copyName
    lda objMode
    cmp #RT_MODE_STATIC
    beq :+
    lda #<LOADER_ADDR
    ldx #>LOADER_ADDR
    bra :++
:   lda #<RT_RUNTIMEERRORINIT
    ldx #>RT_RUNTIMEERRORINIT
:   jsr defineSymbol

    lda symAddr
    ldx symAddr+1
    rts
.endproc

; This routine copies the null-terminated name in A/X to symName
.proc copyName
    sta ptr2
    stx ptr2+1
    ldy #0
:   lda (ptr2),y
    sta symName,y
    beq :+
    iny
    bne :-
:   rts
.endproc

; This routine writes the runtime's BSS, zeros, to the PRG
.proc writeRuntimeBss
    ldx #LFN_PRG
    jsr CHKOUT
    ldx #<RTBSS_LEN
    lda #0
:   jsr CHROUT
    dex
    bne :-
    .assert RTBSS_LEN < 256, error, "the runtime's BSS is a page or more"
    rts
.endproc
