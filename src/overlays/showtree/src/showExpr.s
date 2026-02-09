;
; showExpr.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; showExpr routine

.include "ast.inc"
.include "4510macros.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "symtab.inc"
.include "asmlib.inc"

CH_BACKARROW = 95

.export showExpr, showSubExpr

.import showAddr, printz, printzLong, printStructAddr, printStructName
.import printStructBool, printStructNumber, getKey, loadPtr, printzLong, showTypeKind

.bss

intBuf: .res 10

.data

kindLabel: .asciiz "kind: "
leftLabel: .asciiz "left: "
rightLabel: .asciiz "right: "
nameLabel: .asciiz "name: "
nodeLabel: .asciiz "node: "
negLabel: .asciiz "neg: "
widthLabel: .asciiz "width: "
precisionLabel: .asciiz "precision: "
evalTypeLabel: .asciiz "evalType: "
valueLabel: .asciiz "value: "
lineNumberLabel: .asciiz "lineNumber: "
prompt: .byte "L:left  R:right  S:symtab  ", $5f, ":back", $0d, $0d, $0
strTRUE: .asciiz "true"
strFALSE: .asciiz "false"

strEXPR_ADD: .asciiz "EXPR_ADD"
strEXPR_SUB: .asciiz "EXPR_SUB"
strEXPR_MUL: .asciiz "EXPR_MUL"
strEXPR_DIV: .asciiz "EXPR_DIV"
strEXPR_DIVINT: .asciiz "EXPR_DIVINT"
strEXPR_MOD: .asciiz "EXPR_MOD"
strEXPR_NAME: .asciiz "EXPR_NAME"
strEXPR_CALL: .asciiz "EXPR_CALL"
strEXPR_ARG: .asciiz "EXPR_ARG"
strEXPR_LT: .asciiz "EXPR_LT"
strEXPR_LTE: .asciiz "EXPR_LTE"
strEXPR_GT: .asciiz "EXPR_GT"
strEXPR_GTE: .asciiz "EXPR_GTE"
strEXPR_EQ: .asciiz "EXPR_EQ"
strEXPR_NE: .asciiz "EXPR_NE"
strEXPR_OR: .asciiz "EXPR_OR"
strEXPR_AND: .asciiz "EXPR_AND"
strEXPR_NOT: .asciiz "EXPR_NOT"
strEXPR_SUBSCRIPT: .asciiz "EXPR_SUBSCRIPT"
strEXPR_FIELD: .asciiz "EXPR_FIELD"
strEXPR_ASSIGN: .asciiz "EXPR_ASSIGN"
strEXPR_BOOLEAN_LITERAL: .asciiz "EXPR_BOOLEAN_LITERAL"
strEXPR_BYTE_LITERAL: .asciiz "EXPR_BYTE_LITERAL"
strEXPR_WORD_LITERAL: .asciiz "EXPR_WORD_LITERAL"
strEXPR_DWORD_LITERAL: .asciiz "EXPR_DWORD_LITERAL"
strEXPR_STRING_LITERAL: .asciiz "EXPR_STRING_LITERAL"
strEXPR_CHARACTER_LITERAL: .asciiz "EXPR_CHARACTER_LITERAL"
strEXPR_REAL_LITERAL: .asciiz "EXPR_REAL_LITERAL"
strEXPR_ARRAY_LITERAL: .asciiz "EXPR_ARRAY_LITERAL"
strEXPR_BITWISE_AND: .asciiz "EXPR_BITWISE_AND"
strEXPR_BITWISE_OR: .asciiz "EXPR_BITWISE_OR"
strEXPR_BITWISE_LSHIFT: .asciiz "EXPR_BITWISE_LSHIFT"
strEXPR_BITWISE_RSHIFT: .asciiz "EXPR_BITWISE_RSHIFT"
strEXPR_BITWISE_XOR: .asciiz "EXPR_BITWISE_XOR"
strEXPR_ADDRESS_OF: .asciiz "EXPR_ADDRESS_OF"
strEXPR_POINTER: .asciiz "EXPR_POINTER"

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

.proc showExpr
    stq ptr2

    ; Kind
    lda #<kindLabel
    ldx #>kindLabel
    jsr printz
    jsr showKind
    lda #13
    jsr CHROUT

    ; Left
    lda #<leftLabel
    ldx #>leftLabel
    jsr printz
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr2),z
    jsr showAddr
    ldz #expr::left
    jsr showSubExpr

    ; Right
    lda #<rightLabel
    ldx #>rightLabel
    jsr printz
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr2),z
    jsr showAddr
    ldz #expr::right
    jsr showSubExpr

    ; Name
    lda #<nameLabel
    ldx #>nameLabel
    ldz #expr::name
    jsr printStructName

    ; Node
    lda #<nodeLabel
    ldx #>nodeLabel
    ldz #expr::node
    jsr printStructAddr

    ; Neg
    lda #<negLabel
    ldx #>negLabel
    ldz #expr::neg
    jsr printStructBool

    ; Width
    lda #<widthLabel
    ldx #>widthLabel
    ldz #expr::width
    jsr printStructAddr

    ; Precision
    lda #<precisionLabel
    ldx #>precisionLabel
    ldz #expr::precision
    jsr printStructAddr

    ; EvalType
    lda #<evalTypeLabel
    ldx #>evalTypeLabel
    jsr printz
    ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr2),z
    jsr showAddr
    ldq ptr2
    jsr pushQ
    ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    lda #' '
    jsr CHROUT
    jsr showTypeKind
    jsr popQ
    stq ptr2
    lda #13
    jsr CHROUT

    ; Value
    lda #<valueLabel
    ldx #>valueLabel
    jsr printz
    jsr showValue

    ; lineNumber
    lda #<lineNumberLabel
    ldx #>lineNumberLabel
    jsr printz
    ldz #type::lineNumber
    jsr printStructNumber

    lda #13
    jsr CHROUT

    lda #<prompt
    ldx #>prompt
    jsr printz

L1: jsr getKey
    cmp #'l'
    bne L2
    ldq ptr2
    jsr pushQ
    ldz #expr::left
    jsr loadPtr
    beq :+
    jsr showExpr
:   jsr popQ
    jmp showExpr
L2: cmp #'r'
    bne L3
    ldq ptr2
    jsr pushQ
    ldz #expr::right
    jsr loadPtr
    beq :+
    jsr showExpr
:   jsr popQ
    jmp showExpr
L3: cmp #CH_BACKARROW
    bne L4
    rts
L4: bra L1
.endproc

.proc showSubExpr
    phz
    ldq ptr2
    jsr pushQ
    plz
    neg
    neg
    nop
    lda (ptr2),z
    jsr isQZero
    bne :+
    lda #13
    jsr CHROUT
    jsr popQ
    rts
:   stq ptr2
    lda #' '
    jsr CHROUT
    jsr showKind
    lda #' '
    jsr CHROUT
    jsr showValue
    jsr popQ
    stq ptr2
    rts
.endproc

.proc showKind
    ldz #expr::kind
    nop
    lda (ptr2),z
    asl a
    tay
    lda exprKinds,y
    ldx exprKinds+1,y
    jsr printz
    rts
.endproc

.proc showValue
    ldz #expr::kind
    nop
    lda (ptr2),z
    cmp #EXPR_WORD_LITERAL
    bne :+
    ldz #expr::value
    jmp printStructNumber
:   cmp #EXPR_BYTE_LITERAL
    bne :+
    ldz #expr::value
    jmp printStructNumber
:   cmp #EXPR_CHARACTER_LITERAL
    bne :+
    jmp showCharValue
:   cmp #EXPR_STRING_LITERAL
    bne :+
    jmp showStringValue
:   cmp #EXPR_REAL_LITERAL
    bne :+
    jmp showRealValue
:   cmp #EXPR_BOOLEAN_LITERAL
    bne :+
    jmp showBooleanValue
:   cmp #EXPR_NAME
    bne :+
    ldz #expr::name
    neg
    neg
    nop
    lda (ptr2),z
    jsr printzLong
    ; Fall through to next line
:   lda #13
    jsr CHROUT
    rts
.endproc

.proc showRealValue
    ldz #expr::value
    neg
    neg
    nop
    lda (ptr2),z
    jsr printzLong
    lda #13
    jsr CHROUT
    rts
.endproc

.proc showStringValue
    lda #'''
    jsr CHROUT
    ldz #expr::value
    neg
    neg
    nop
    lda (ptr2),z
    jsr printzLong
    lda #'''
    jsr CHROUT
    lda #13
    jsr CHROUT
    rts
.endproc

.proc showCharValue
    lda #'''
    jsr CHROUT
    ldz #expr::value
    nop
    lda (ptr2),z
    jsr CHROUT
    lda #'''
    jsr CHROUT
    lda #13
    jsr CHROUT
    rts
.endproc

.proc showBooleanValue
    ldz #expr::value
    nop
    lda (ptr2),z
    beq L1
    lda #<strTRUE
    ldx #>strTRUE
    jsr printz
    bra L2
L1: lda #<strFALSE
    ldx #>strFALSE
    jsr printz
L2: lda #13
    jsr CHROUT
    rts
.endproc
