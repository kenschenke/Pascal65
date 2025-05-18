;
; dumpheap.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Dump the heap allocation table to the console
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"
.include "cbm_kernal.inc"

.export dumpHeap

.data

header1: .asciiz "Addr  Size  Used"
header2: .asciiz "----  ----  ----"
hexStr: .asciiz "0123456789abcdef"
yes: .asciiz "Yes"
no: .asciiz "No"
summary1: .asciiz " entr"
suffixSingle: .asciiz "y "
suffixPlural: .asciiz "ies "
summary2: .asciiz "in heap table"
summary3: .asciiz "too many entries in heap table"

.code

.proc incHeapCount
    inc intOp1
    bne :+
    inc intOp1 + 1
:   rts
.endproc

.proc printGap
    lda #' '
    jsr CHROUT
    jmp CHROUT
.endproc

.proc dumpNibble
    tax
    bne :+
    lda tmp1
    bne :+
    lda #' '
    jmp CHROUT
:   lda #1
    sta tmp1
    lda hexStr,x
    jmp CHROUT
.endproc

.proc dumpByte
    pha
    lsr
    lsr
    lsr
    lsr
    jsr dumpNibble
    pla
    and #$0f
    jsr dumpNibble
    rts
.endproc

.proc dumpAddr
    lda #0
    sta tmp1            ; is a 1 after first non-zero digit printed
    ldy #3
    lda (ptr1),y
    jsr dumpByte
    ldy #2
    lda (ptr1),y
    jmp dumpByte
.endproc

.proc dumpSize
    lda #0
    sta tmp1            ; is a 1 after first non-zero digit printed
    ldy #1
    lda (ptr1),y
    and #$7f
    jsr dumpByte
    ldy #0
    lda (ptr1),y
    jmp dumpByte
.endproc

.proc dumpUsed
    ldy #1
    lda (ptr1),y
    and #$80
    beq NO
    ldx #0
:   lda yes,x
    beq DN
    jsr CHROUT
    inx
    bne :-
NO: ldx #0
:   lda no,x
    beq DN
    jsr CHROUT
    inx
    bne :-
DN: lda #13
    jmp CHROUT
.endproc

.proc printSummary
    lda intOp1 + 1          ; Were there more then 255 entries?
    beq CL                  ; Branch if not
    ldx #0
:   lda summary3,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #13
    jmp CHROUT
CL: lda intOp1
    cmp #100                ; Were there 100 or more entries?
    bcc PF                  ; Branch if not
    ldx #0
:   lda summary3,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #13
    jmp CHROUT
PF: lda #0
    sta tmp1
    lda intOp1
:   cmp #10                 ; Is intOp1 > 10?
    bcc :+                  ; Branch if not
    inc tmp1
    sec
    sbc #10
    ldy #1
    bne :-
:   pha
    lda tmp1
    beq :+
    lda #'0'
    clc
    adc tmp1
    jsr CHROUT
:   pla
    clc
    adc #'0'
    jsr CHROUT
    ldx #0
:   lda summary1,x
    beq PP
    jsr CHROUT
    inx
    bne :-
PP: lda intOp1
    cmp #1
    beq SS
    ldx #0
:   lda suffixPlural,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #0
    beq S3
SS: ldx #0
:   lda suffixSingle,x
    beq S3
    jsr CHROUT
    inx
    bne :-
S3: ldx #0
:   lda summary2,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #13
    jmp CHROUT
.endproc

.proc dumpHeap
    ; Initialize things
    lda #0
    sta intOp1
    sta intOp1 + 1
    lda #$ff
    tax
    jsr rtHeapAlloc
    sta ptr1
    stx ptr1 + 1
    ; Print the header
    ldx #0
:   lda header1,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #13
    jsr CHROUT
    ldx #0
:   lda header2,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #13
    jsr CHROUT

    ; Loop through the MAT

    ; Is this entry the end?
LP: ldy #3
:   lda (ptr1),y
    bne :+
    dey
    bpl :-
    bmi DN
:   jsr dumpAddr
    jsr printGap
    jsr dumpSize
    jsr printGap
    jsr dumpUsed
    jsr incHeapCount
    ; Move ptr1 to the next entry
    lda ptr1
    sec
    sbc #4
    sta ptr1
    lda ptr1 + 1
    sbc #0
    sta ptr1 + 1
    jmp LP

    ; Done looping. Print the summary
DN: lda #13
    jsr CHROUT
    jmp printSummary
.endproc
