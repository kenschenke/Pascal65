;
; dumpStmt.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; dumpStmt routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export dumpStmt, dumpStmtMember

.import level, printz, dumpDecl, dumpExpr, newLine, showPrefix, prefix, dumpChar, indent
.import dumpExprKind, dumpExprValue

.data

strTrueBody: .asciiz "If True"
strFalseBody: .asciiz "If False"
strInitExpr: .asciiz "Init:"
strToExpr: .asciiz "To:"
strDownTo: .asciiz "DownTo: "
strCaseBody: .asciiz "Case Body:"
strYes: .asciiz "Yes"
strNo: .asciiz "No"
strSTMT_EXPR: .asciiz "STMT-EXPR"
strSTMT_IF_ELSE: .asciiz "STMT-IF-ELSE"
strSTMT_FOR: .asciiz "STMT-FOR"
strSTMT_WHILE: .asciiz "STMT-WHILE"
strSTMT_REPEAT: .asciiz "STMT-REPEAT"
strSTMT_CASE: .asciiz "STMT-CASE"
strSTMT_CASE_LABEL: .asciiz "STMT-CASE-LABEL"
strSTMT_BLOCK: .asciiz "STMT-BLOCK"

kinds: .byte .LOBYTE(strSTMT_EXPR), .HIBYTE(strSTMT_EXPR)
       .byte .LOBYTE(strSTMT_IF_ELSE), .HIBYTE(strSTMT_IF_ELSE)
       .byte .LOBYTE(strSTMT_FOR), .HIBYTE(strSTMT_FOR)
       .byte .LOBYTE(strSTMT_WHILE), .HIBYTE(strSTMT_WHILE)
       .byte .LOBYTE(strSTMT_REPEAT), .HIBYTE(strSTMT_REPEAT)
       .byte .LOBYTE(strSTMT_CASE), .HIBYTE(strSTMT_CASE)
       .byte .LOBYTE(strSTMT_CASE_LABEL), .HIBYTE(strSTMT_CASE_LABEL)
       .byte .LOBYTE(strSTMT_BLOCK), .HIBYTE(strSTMT_BLOCK)

.code

.proc dumpStmtMember
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

    jsr dumpStmt

:   jsr popQ
    stq ptr1
    rts
.endproc

.proc dumpStmt
    stq ptr1

    lda #'S'
    jsr showPrefix
    inc level

    ldz #stmt::kind
    nop
    lda (ptr1),z
    asl a
    tay
    lda kinds,y
    ldx kinds+1,y
    jsr printz

    ldz #stmt::kind
    nop
    lda (ptr1),z
    cmp #STMT_CASE_LABEL
    bne :+
    jmp dumpCaseLabels

:   ldq ptr1
    jsr pushQ
    ldz #stmt::expr
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    stq ptr1
    jsr newLine
    ldq ptr1
    jsr dumpExpr

:   jsr popQ
    stq ptr1

    jsr newLine

    jsr dumpInterfaceDecls
    jsr dumpDecls

    ldz #stmt::kind
    nop
    lda (ptr1),z
    cmp #STMT_FOR
    bne :+
    jsr dumpForLoop
    ldz #stmt::kind
    nop
    lda (ptr1),z
:   cmp #STMT_IF_ELSE
    bne :+
    lda #<strTrueBody
    sta prefix
    lda #>strTrueBody
    sta prefix+1
    jsr showPrefix
    lda #13
    jsr dumpChar
    inc level
:   ldq ptr1
    jsr pushQ
    ldz #stmt::body
    neg
    neg
    nop
    lda (ptr1),z
    jsr dumpBody
    jsr popQ
    stq ptr1
    ldz #stmt::kind
    nop
    lda (ptr1),z
    cmp #STMT_IF_ELSE
    bne :+
    dec level

:   ldz #stmt::kind
    nop
    lda (ptr1),z
    cmp #STMT_IF_ELSE
    bne L1
    ldq ptr1
    jsr pushQ
    ldz #stmt::else_body
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    jsr pushQ
    lda #<strFalseBody
    sta prefix
    lda #>strFalseBody
    sta prefix+1
    jsr showPrefix
    lda #13
    jsr dumpChar
    inc level
    jsr popQ
    jsr dumpBody
    dec level
:   jsr popQ
    stq ptr1

L1: dec level
    rts
.endproc

.proc dumpCaseLabels
    ldq ptr1
    jsr pushQ

    ldz #stmt::expr
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1

L1: ldq ptr1
    jsr isQZero
    beq L2

    jsr newLine
    jsr indent

    jsr dumpExprKind
    jsr dumpExprValue

    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    bra L1

L2: jsr popQ
    stq ptr1
    jsr pushQ
    
    ; Case label body
    jsr newLine
    jsr indent
    lda #<strCaseBody
    ldx #>strCaseBody
    jsr printz
    jsr newLine
    inc level
    ldq ptr1
    ldz #stmt::body
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jsr dumpBody
    jsr popQ
    stq ptr1
    dec level
    dec level
    rts
.endproc

.proc dumpForLoop
    ldq ptr1
    jsr pushQ
    jsr indent
    lda #<strInitExpr
    ldx #>strInitExpr
    jsr printz
    jsr newLine
    inc level
    ldz #stmt::init_expr
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jsr dumpExpr
    jsr newLine
    jsr popQ
    stq ptr1
    jsr pushQ
    dec level
    jsr indent
    lda #<strToExpr
    ldx #>strToExpr
    jsr printz
    inc level
    jsr newLine
    ldz #stmt::to_expr
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jsr dumpExpr
    jsr newLine
    jsr popQ
    stq ptr1
    dec level
    jsr indent
    lda #<strDownTo
    ldx #>strDownTo
    jsr printz
    ldz #stmt::isDownTo
    nop
    lda (ptr1),z
    beq :+
    lda #<strYes
    ldx #>strYes
    bra L1
:   lda #<strNo
    ldx #>strNo
L1: jsr printz
    jsr newLine
    rts
.endproc

.proc dumpDecls
    ldq ptr1
    jsr pushQ

    ldz #stmt::decl
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L9
    stq ptr1

L1: ldq ptr1
    jsr isQZero
    beq L9
    ldq ptr1
    jsr dumpDecl
    ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    bra L1

L9: jsr popQ
    stq ptr1
    rts
.endproc

.proc dumpInterfaceDecls
    ldq ptr1
    jsr pushQ

    ldz #stmt::interfaceDecl
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L9
    stq ptr1

L1: ldq ptr1
    jsr isQZero
    beq L9
    ldq ptr1
    jsr dumpDecl
    ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    bra L1

L9: jsr popQ
    stq ptr1
    rts
.endproc

.proc dumpBody
    stq ptr1

L1: ldq ptr1
    jsr isQZero
    beq L9
    ldq ptr1
    jsr dumpStmt
    ldz #stmt::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    bra L1

L9: rts
.endproc
