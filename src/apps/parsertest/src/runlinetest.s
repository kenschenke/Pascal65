;
; runlinetest.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; runLineTest routine
;
; This test checks the line numbers the parser puts in declarations.
; It parses lines.pas and walks the program's declarations, and the
; values of each enumeration, comparing each decl::lineNumber with the
; expected table. The uses declaration (System) is skipped.

.include "ast.inc"
.include "asmlib.inc"
.include "parser.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export runLineTest

.import testFail, initTokenizer, initParser, printLine
.import freeUnits, unitList

.data

strFn: .asciiz "lines.pas"
strTitle: .asciiz "Running declaration line test : "
strBadLine: .asciiz "Wrong line for declaration "
strGot: .asciiz ", got "
strCount: .asciiz "Wrong number of declarations"
strPass: .asciiz "Pass"

; Expected lines, in the order the declarations are walked:
;   a, b, c (constants), E (type), r, g, b2 (enumeration values), v
expected: .word 6, 7, 9, 12, 12, 13, 13, 16
NUM_EXPECTED = (* - expected) / 2

.bss

tokens: .res 4
astRoot: .res 4
declPtr: .res 4
enumPtr: .res 4
index: .res 1
intBuf: .res 10

.code

.proc runLineTest
    lda #<strTitle
    ldx #>strTitle
    jsr printLine

    ; Tokenize and parse lines.pas
    jsr initTokenizer
    lda #<strFn
    ldx #>strFn
    jsr tokenize
    stq tokens
    jsr initParser
    jsr parserInit
    lda #0
    tax
    tay
    taz
    stq unitList
    jsr setParserUnitsList
    ldq tokens
    jsr parse
    stq astRoot
    jsr getParserUnitsList
    stq unitList
    ldq tokens
    jsr freeMemBuf

    lda #0
    sta index

    ; The first declaration is in the program's statement block
    ldq astRoot
    stq ptr1
    ldz #decl::code
    jsr loadPtr1
    stq ptr1
    ldz #stmt::decl
    jsr loadPtr1
    stq declPtr

L1: ldq declPtr
    jsr isQZero
    bne :+
    jmp DN
:   stq ptr1
    ldz #decl::kind
    nop
    lda (ptr1),z
    cmp #DECL_USES
    beq NX
    jsr checkLine
    bcs FL

    ; An enumeration's values are declarations too
    ldq declPtr
    stq ptr1
    ldz #decl::type
    jsr loadPtr1
    jsr isQZero
    beq NX
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ENUMERATION
    bne NX
    ldz #type::paramFields
    jsr loadPtr1
    stq enumPtr
L2: ldq enumPtr
    jsr isQZero
    beq NX
    stq ptr1
    jsr checkLine
    bcs FL
    ldq enumPtr
    stq ptr1
    ldz #decl::next
    jsr loadPtr1
    stq enumPtr
    bra L2

NX: ldq declPtr
    stq ptr1
    ldz #decl::next
    jsr loadPtr1
    stq declPtr
    jmp L1

DN: lda index
    cmp #NUM_EXPECTED
    beq :+
    lda #<strCount
    ldx #>strCount
    jsr printLine
FL: lda #13
    jsr CHROUT
    jmp testFail

:   ldq astRoot
    jsr astFree
    jsr freeUnits
    lda #<strPass
    ldx #>strPass
    jsr printLine
    lda #13
    jsr CHROUT
    rts
.endproc

; This routine loads the pointer at offset Z in the structure in ptr1
; and returns it in Q.
.proc loadPtr1
    neg
    neg
    nop
    lda (ptr1),z
    rts
.endproc

; This routine compares the line number of the declaration in ptr1
; with the next expected line. On a mismatch it prints a message and
; returns with the carry set.
.proc checkLine
    lda index
    cmp #NUM_EXPECTED
    bcc :+
    lda #<strCount
    ldx #>strCount
    jsr printLine
    sec
    rts

:   asl a
    tax
    ldz #decl::lineNumber
    nop
    lda (ptr1),z
    cmp expected,x
    bne ER
    inz
    nop
    lda (ptr1),z
    cmp expected+1,x
    bne ER
    inc index
    clc
    rts

ER: ldz #decl::lineNumber
    nop
    lda (ptr1),z
    pha
    inz
    nop
    lda (ptr1),z
    pha
    lda #<strBadLine
    ldx #>strBadLine
    jsr printLine
    lda index
    clc
    adc #1
    sta intOp1
    lda #0
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    lda #<intBuf
    ldx #>intBuf
    jsr printLine
    lda #<strGot
    ldx #>strGot
    jsr printLine
    pla
    sta intOp1+1
    pla
    sta intOp1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    lda #<intBuf
    ldx #>intBuf
    jsr printLine
    sec
    rts
.endproc
