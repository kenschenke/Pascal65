;
; util.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; utility routines used in dumpsymtab

.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export level, indent, dumpString, printz, newLine, showPrefix, prefix
.export dumpChar, memBuf, dumpMemBuf, printNumber

.bss

buf: .res 1
level: .res 1
prefix: .res 2
memBuf: .res 4
intBuf: .res 10

.data

; 80 spaces - used by indent
spaces: .byte "                                                                                "

.code

.proc dumpMemBuf
    ldq memBuf
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos

L1: ldq memBuf
    jsr isMemBufAtEnd
    beq L2

    ldq memBuf
    stq ptr1
    lda #<buf
    sta ptr2
    lda #>buf
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr readFromMemBuf
    lda buf
    jsr CHROUT
    bra L1

L2: rts
.endproc

; This routine dumps a string to the membuf.
; The offset in the structure is passed in Z.
; The pointer to the structure is in ptr1.
; The routine is safe to call if the string is null.
.proc dumpString
    phz
    ldq ptr1
    jsr pushQ
    plz
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L3
    jsr pushQ
    lda #' '
    jsr dumpChar
    ldq memBuf
    stq ptr1
    jsr popQ
    stq ptr2
    ldz #0
L1: nop
    lda (ptr2),z
    beq L2
    inz
    bne L1
L2: tza
    ldx #0
    jsr writeToMemBuf
L3: jsr popQ
    stq ptr1
    rts
.endproc

; Char in A
; ptr1 is preserved
.proc dumpChar
    sta buf
    ldq ptr1
    jsr pushQ
    ldq memBuf
    stq ptr1
    lda #<buf
    stq ptr2
    lda #>buf
    stq ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr writeToMemBuf
    jsr popQ
    stq ptr1
    rts
.endproc

.proc newLine
    lda #13
    jmp dumpChar
.endproc

.proc indent
    ldq ptr1
    jsr pushQ
    ldq memBuf
    stq ptr1
    lda #<spaces
    sta ptr2
    lda #>spaces
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3

    lda level
    beq L2
    asl a
    ldx #0
    jsr writeToMemBuf
L2: jsr popQ
    stq ptr1
    rts
.endproc

.proc showPrefix
    pha
    ldq ptr1
    jsr pushQ
    pla

    jsr pushA
    jsr indent

    lda prefix
    ora prefix+1
    bne L1
    jsr popA
    jsr dumpChar
    bra L2
L1: jsr popA
    lda prefix
    ldx prefix+1
    jsr printz
    lda #0
    sta prefix
    sta prefix+1
L2: lda #':'
    jsr dumpChar
    jsr popQ
    stq ptr1
    rts
.endproc

.proc printz
    sta ptr2
    stx ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3

    ldq ptr1
    jsr pushQ
    ldq memBuf
    stq ptr1
    
    ldy #0
:   lda (ptr2),y
    beq :+
    iny
    bne :-
:   tya
    ldx #0
    jsr writeToMemBuf
    jsr popQ
    stq ptr1
    rts
.endproc

; Prefix in A, offset in Z
.proc printNumber
    pha
    nop
    lda (ptr1),z
    sta intOp1
    inz
    nop
    lda (ptr1),z
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    pla
    jsr dumpChar
    lda #':'
    jsr dumpChar
    lda #<intBuf
    ldx #>intBuf
    jsr printz
    rts
.endproc
