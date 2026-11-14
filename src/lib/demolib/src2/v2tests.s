;
; v2tests.s
; Ken Schenke (kenschenke@gmail.com)
;
; Routines that test the v2 library format (relocation table)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"

.export demo2Init, pageBytes, bssCounter

; The bytes in the library's own page range ($30-$34, the library is
; linked at $3000). A v1 loader would take them for the high bytes of
; addresses and change them.
.rodata

pageTable: .byte $30, $31, $32, $33, $34

; Not in the file. The loader writes zeros in its place.
.bss

initRan: .res 1
bssBuf: .res 200
counter: .res 2

.code

; The library's init routine, run before the program
.proc demo2Init
    lda #1
    sta initRan
    rts
.endproc

; Returns 250, the sum of pageTable, if its bytes and the immediate
; operands below are unchanged. Otherwise 0.
.proc pageBytes
    lda #$32
    cmp pageTable+2
    bne BD
    lda #$34
    cmp pageTable+4
    bne BD
    lda #0
    ldx #4
:   clc
    adc pageTable,x
    dex
    bpl :-
    ldx #0
    jmp RT
BD: lda #0
    tax
RT: ldy #0
    sty sreg
    sty sreg+1
    jmp rtLibReturnValue
.endproc

; Adds 1 to counter and returns it. Returns -1 if bssBuf isn't all zero
; and -2 if the init routine didn't run.
.proc bssCounter
    lda initRan
    cmp #1
    bne NI
    ldx #0
:   lda bssBuf,x
    bne BD
    inx
    cpx #200
    bne :-
    inc counter
    bne :+
    inc counter+1
:   lda counter
    ldx counter+1
    ldy #0
    jmp RT
NI: lda #$fe
    bne :+
BD: lda #$ff
:   ldx #$ff
    ldy #$ff
RT: sty sreg
    sty sreg+1
    jmp rtLibReturnValue
.endproc
