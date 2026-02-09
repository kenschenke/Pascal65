;
; dumpExpr.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; dumpExpr routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export dumpExpr, dumpExprMember, dumpExprValue, dumpExprKind

.import level, printz, dumpString, newLine, prefix, showPrefix, dumpChar, dumpHex, indent
.import dumpTypeKind

.bss

intBuf: .res 10

.data

strLeft: .asciiz "Left"
strRight: .asciiz "Right"
strTrue: .asciiz " true"
strFalse: .asciiz " false"
strEXPR_ADD: .asciiz "EXPR-ADD"
strEXPR_SUB: .asciiz "EXPR-SUB"
strEXPR_MUL: .asciiz "EXPR-MUL"
strEXPR_DIV: .asciiz "EXPR-DIV"
strEXPR_DIVINT: .asciiz "EXPR-DIVINT"
strEXPR_MOD: .asciiz "EXPR-MOD"
strEXPR_NAME: .asciiz "EXPR-NAME"
strEXPR_CALL: .asciiz "EXPR-CALL"
strEXPR_ARG: .asciiz "EXPR-ARG"
strEXPR_LT: .asciiz "EXPR-LT"
strEXPR_LTE: .asciiz "EXPR-LTE"
strEXPR_GT: .asciiz "EXPR-GT"
strEXPR_GTE: .asciiz "EXPR-GTE"
strEXPR_EQ: .asciiz "EXPR-EQ"
strEXPR_NE: .asciiz "EXPR-NE"
strEXPR_OR: .asciiz "EXPR-OR"
strEXPR_AND: .asciiz "EXPR-AND"
strEXPR_NOT: .asciiz "EXPR-NOT"
strEXPR_SUBSCRIPT: .asciiz "EXPR-SUBSCRIPT"
strEXPR_FIELD: .asciiz "EXPR-FIELD"
strEXPR_ASSIGN: .asciiz "EXPR-ASSIGN"
strEXPR_BOOLEAN_LITERAL: .asciiz "EXPR-BOOLEAN-LITERAL"
strEXPR_BYTE_LITERAL: .asciiz "EXPR-BYTE-LITERAL"
strEXPR_WORD_LITERAL: .asciiz "EXPR-WORD-LITERAL"
strEXPR_DWORD_LITERAL: .asciiz "EXPR-DWORD-LITERAL"
strEXPR_STRING_LITERAL: .asciiz "EXPR-STRING-LITERAL"
strEXPR_CHARACTER_LITERAL: .asciiz "EXPR-CHARACTER-LITERAL"
strEXPR_REAL_LITERAL: .asciiz "EXPR-REAL-LITERAL"
strEXPR_ARRAY_LITERAL: .asciiz "EXPR-ARRAY-LITERAL"
strEXPR_BITWISE_AND: .asciiz "EXPR-BITWISE-AND"
strEXPR_BITWISE_OR: .asciiz "EXPR-BITWISE-OR"
strEXPR_BITWISE_LSHIFT: .asciiz "EXPR-BITWISE-LSHIFT"
strEXPR_BITWISE_RSHIFT: .asciiz "EXPR-BITWISE-RSHIFT"
strEXPR_BITWISE_XOR: .asciiz "EXPR-BITWISE-XOR"
strEXPR_ADDRESS_OF: .asciiz "EXPR-ADDRESS-OF"
strEXPR_POINTER: .asciiz "EXPR-POINTER"

exprKinds: .byte .LOBYTE(strEXPR_ADD), .HIBYTE(strEXPR_ADD)
           .byte .LOBYTE(strEXPR_SUB), .HIBYTE(strEXPR_SUB)
           .byte .LOBYTE(strEXPR_MUL), .HIBYTE(strEXPR_MUL)
           .byte .LOBYTE(strEXPR_DIV), .HIBYTE(strEXPR_DIV)
           .byte .LOBYTE(strEXPR_DIVINT), .HIBYTE(strEXPR_DIVINT)
           .byte .LOBYTE(strEXPR_MOD), .HIBYTE(strEXPR_MOD)
           .byte .LOBYTE(strEXPR_NAME), .HIBYTE(strEXPR_NAME)
           .byte .LOBYTE(strEXPR_CALL), .HIBYTE(strEXPR_CALL)
           .byte .LOBYTE(strEXPR_ARG), .HIBYTE(strEXPR_ARG)
           .byte .LOBYTE(strEXPR_LT), .HIBYTE(strEXPR_LT)
           .byte .LOBYTE(strEXPR_LTE), .HIBYTE(strEXPR_LTE)
           .byte .LOBYTE(strEXPR_GT), .HIBYTE(strEXPR_GT)
           .byte .LOBYTE(strEXPR_GTE), .HIBYTE(strEXPR_GTE)
           .byte .LOBYTE(strEXPR_EQ), .HIBYTE(strEXPR_EQ)
           .byte .LOBYTE(strEXPR_NE), .HIBYTE(strEXPR_NE)
           .byte .LOBYTE(strEXPR_OR), .HIBYTE(strEXPR_OR)
           .byte .LOBYTE(strEXPR_AND), .HIBYTE(strEXPR_AND)
           .byte .LOBYTE(strEXPR_NOT), .HIBYTE(strEXPR_NOT)
           .byte .LOBYTE(strEXPR_SUBSCRIPT), .HIBYTE(strEXPR_SUBSCRIPT)
           .byte .LOBYTE(strEXPR_FIELD), .HIBYTE(strEXPR_FIELD)
           .byte .LOBYTE(strEXPR_ASSIGN), .HIBYTE(strEXPR_ASSIGN)
           .byte .LOBYTE(strEXPR_BOOLEAN_LITERAL), .HIBYTE(strEXPR_BOOLEAN_LITERAL)
           .byte .LOBYTE(strEXPR_BYTE_LITERAL), .HIBYTE(strEXPR_BYTE_LITERAL)
           .byte .LOBYTE(strEXPR_WORD_LITERAL), .HIBYTE(strEXPR_WORD_LITERAL)
           .byte .LOBYTE(strEXPR_DWORD_LITERAL), .HIBYTE(strEXPR_DWORD_LITERAL)
           .byte .LOBYTE(strEXPR_STRING_LITERAL), .HIBYTE(strEXPR_STRING_LITERAL)
           .byte .LOBYTE(strEXPR_CHARACTER_LITERAL), .HIBYTE(strEXPR_CHARACTER_LITERAL)
           .byte .LOBYTE(strEXPR_REAL_LITERAL), .HIBYTE(strEXPR_REAL_LITERAL)
           .byte .LOBYTE(strEXPR_ARRAY_LITERAL), .HIBYTE(strEXPR_ARRAY_LITERAL)
           .byte .LOBYTE(strEXPR_BITWISE_AND), .HIBYTE(strEXPR_BITWISE_AND)
           .byte .LOBYTE(strEXPR_BITWISE_OR), .HIBYTE(strEXPR_BITWISE_OR)
           .byte .LOBYTE(strEXPR_BITWISE_LSHIFT), .HIBYTE(strEXPR_BITWISE_LSHIFT)
           .byte .LOBYTE(strEXPR_BITWISE_RSHIFT), .HIBYTE(strEXPR_BITWISE_RSHIFT)
           .byte .LOBYTE(strEXPR_BITWISE_XOR), .HIBYTE(strEXPR_BITWISE_XOR)
           .byte .LOBYTE(strEXPR_ADDRESS_OF), .HIBYTE(strEXPR_ADDRESS_OF)
           .byte .LOBYTE(strEXPR_POINTER), .HIBYTE(strEXPR_POINTER)

.code

.proc dumpExprMember
    phz
    ldq ptr1
    jsr pushQ
    plz
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+

    jsr dumpExpr

:   jsr popQ
    stq ptr1
    rts
.endproc

.proc dumpExpr
    stq ptr1

    lda #'E'
    jsr showPrefix

    jsr dumpExprKind

    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_ARRAY_LITERAL
    bne :+
    jmp dumpArrayLiteral
:   cmp #EXPR_ARG
    bne :+
    jmp dumpArgList

:   ldq ptr1
    jsr pushQ
    jsr dumpExprValue

    jsr popQ
    stq ptr1
    jsr pushQ
    jsr dumpExprType

    jsr popQ
    stq ptr1
    jsr pushQ
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    stq ptr1
    inc level
    jsr newLine
    lda #<strLeft
    sta prefix
    lda #>strLeft
    sta prefix+1
    ldq ptr1
    jsr dumpExpr
    dec level

:   jsr popQ
    stq ptr1
    jsr pushQ
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    stq ptr1
    inc level
    jsr newLine
    lda #<strRight
    sta prefix
    lda #>strRight
    sta prefix+1
    ldq ptr1
    jsr dumpExpr
    dec level

:   jsr popQ
    rts
.endproc

.proc dumpExprKind
    ldz #expr::kind
    nop
    lda (ptr1),z
    asl a
    tay
    lda exprKinds,y
    ldx exprKinds+1,y
    jmp printz
.endproc

.proc dumpExprType
    ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    stq ptr1
    lda #' '
    jsr dumpChar
    lda #'T'
    jsr dumpChar
    lda #':'
    jsr dumpChar
    jsr dumpTypeKind
:   rts
.endproc

.proc dumpArrayLiteral
    jsr newLine
    inc level

    ldq ptr1
    jsr pushQ

    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1

L1: ldq ptr1
    jsr isQZero
    beq L2

    jsr indent
    jsr dumpExprKind
    jsr dumpExprValue

    ldq ptr1
    jsr pushQ
    jsr dumpExprType
    jsr popQ
    stq ptr1

    jsr newLine

    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    bra L1

L2: jsr popQ
    stq ptr1
    dec level
    rts
.endproc

.proc dumpArgList
    inc level

    ldq ptr1
    jsr pushQ

L1: ldq ptr1
    jsr isQZero
    beq L2

    jsr newLine
    jsr indent
    ldq ptr1
    jsr pushQ
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jsr dumpExprKind
    jsr dumpExprValue
    jsr popQ
    stq ptr1
    jsr pushQ
    jsr dumpExprType
    jsr popQ
    stq ptr1

    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    bra L1

L2: jsr popQ
    stq ptr1
    dec level
    rts
.endproc

.proc dumpBoolean
    ldz #expr::value
    nop
    lda (ptr1),z
    bne L1

    lda #<strFalse
    ldx #>strFalse
    bra L2

L1: lda #<strTrue
    ldx #>strTrue

L2: jmp printz
.endproc

.proc dumpExprValue
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_STRING_LITERAL
    bne :+
    ldz #expr::value
    jmp dumpString
:   cmp #EXPR_NAME
    bne :+
    ldz #expr::name
    jmp dumpString
:   cmp #EXPR_REAL_LITERAL
    bne :+
    ldz #expr::value
    jmp dumpString
:   cmp #EXPR_BOOLEAN_LITERAL
    bne :+
    jmp dumpBoolean
:   cmp #EXPR_BYTE_LITERAL
    bne :+
    jmp showNumberValue
:   cmp #EXPR_WORD_LITERAL
    bne :+
    jmp showNumberValue
:   cmp #EXPR_DWORD_LITERAL
    bne :+
    jmp showNumberValue
:   cmp #EXPR_CHARACTER_LITERAL
    bne :+
    jmp showCharValue
:   rts
.endproc

.proc showCharValue
    lda #' '
    jsr dumpChar
    lda #'''
    jsr dumpChar
    ldz #expr::value
    nop
    lda (ptr1),z
    jsr dumpChar
    lda #'''
    jmp dumpChar
.endproc

.proc showNumberValue
    lda #' '
    jsr dumpChar
    ldz #expr::value
    neg
    neg
    nop
    lda (ptr1),z
    jmp dumpHex
.endproc
