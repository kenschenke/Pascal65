;
; tokenizeAndParseUnits.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; tokenizeAndParseUnits routine

.include "ast.inc"
.include "asmlib.inc"
.include "parser.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "4510macros.inc"

.export tokenizeAndParseUnits

.import unitList, initTokenizer, initParser

.data

strPas: .asciiz ".pas"

.bss

any: .res 1
currentUnit: .res 4
filename: .res 13
tokenHeap: .res 4

.code

.proc tokenizeAndParseUnits
L1: lda #0
    sta any

    ldq unitList
    stq currentUnit

L2: ldq currentUnit
    jsr isQZero
    bne :+
    jmp L4
:   stq ptr1

    ldz #unit::astRoot
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    bne L3

    lda #1
    sta any

    ldq ptr1
    jsr formatFilename

    jsr initTokenizer
    lda #<filename
    ldx #>filename
    jsr tokenize
    stq tokenHeap

    jsr initParser
    ldq unitList
    jsr setParserUnitsList
    ldq tokenHeap
    jsr parse
    stq ptr2
    ldq currentUnit
    stq ptr1
    ldz #unit::astRoot
    ldx #0
:   lda ptr2,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    jsr getParserUnitsList
    stq unitList

    ldq tokenHeap
    jsr freeMemBuf

L3: ldq currentUnit
    stq ptr1
    ldz #unit::next
    neg
    neg
    nop
    lda (ptr1),z
    stq currentUnit
    jmp L2

L4: lda any
    beq L5
    jmp L1

L5: rts
.endproc

; Null-terminated system name passed in Q
.proc formatFilename
    stq ptr2

    ldy #0
    ldz #0
L1: nop
    lda (ptr2),z
    beq L2
    sta filename,y
    iny
    inz
    bne L1

L2: ldx #0
L3: lda strPas,x
    beq L4
    sta filename,y
    inx
    iny
    bne L3

L4: lda #0
    sta filename,y
    rts
.endproc
