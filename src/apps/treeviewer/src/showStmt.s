.include "ast.inc"
.include "asmlib.inc"
.include "4510macros.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"

CH_BACKARROW = 95

.export showStmt

.import printz, printzLong, printStructAddr, printStructName
.import printStructBool, printStructNumber, getKey, showDecl, loadPtr, showExpr

.data

kindLabel: .asciiz "kind: "
declLabel: .asciiz "decl: "
interfaceDeclLabel: .asciiz "interfaceDecl: "
init_exprLabel: .asciiz "init_expr: "
exprLabel: .asciiz "expr: "
to_exprLabel: .asciiz "to_expr: "
isDownToLabel: .asciiz "isDownTo: "
bodyLabel: .asciiz "body: "
else_bodyLabel: .asciiz "else_body: "
nextLabel: .asciiz "next: "
lineNumberLabel: .asciiz "lineNumber: "
prompt: .byte "D:decl  F:ifaceDecl  I:init_expr  E:expr  B:body  L:else_body  N:next  ", $5f, ":back", $0d, $0d, $0

strSTMT_EXPR: .asciiz "STMT_EXPR"
strSTMT_IF_ELSE: .asciiz "STMT_IF_ELSE"
strSTMT_FOR: .asciiz "STMT_FOR"
strSTMT_WHILE: .asciiz "STMT_WHILE"
strSTMT_REPEAT: .asciiz "STMT_REPEAT"
strSTMT_CASE: .asciiz "STMT_CASE"
strSTMT_CASE_LABEL: .asciiz "STMT_CASE_LABEL"
strSTMT_BLOCK: .asciiz "STMT_BLOCK"

stmtKinds: .byte .LOBYTE(strSTMT_EXPR), .HIBYTE(strSTMT_EXPR)
           .byte .LOBYTE(strSTMT_IF_ELSE), .HIBYTE(strSTMT_IF_ELSE)
           .byte .LOBYTE(strSTMT_FOR), .HIBYTE(strSTMT_FOR)
           .byte .LOBYTE(strSTMT_WHILE), .HIBYTE(strSTMT_WHILE)
           .byte .LOBYTE(strSTMT_REPEAT), .HIBYTE(strSTMT_REPEAT)
           .byte .LOBYTE(strSTMT_CASE), .HIBYTE(strSTMT_CASE)
           .byte .LOBYTE(strSTMT_CASE_LABEL), .HIBYTE(strSTMT_CASE_LABEL)
           .byte .LOBYTE(strSTMT_BLOCK), .HIBYTE(strSTMT_BLOCK)

.code

.proc showStmt
    stq ptr2

    ; Kind
    lda #<kindLabel
    ldx #>kindLabel
    jsr printz
    ldz #stmt::kind
    nop
    lda (ptr2),z
    asl a
    tay
    lda stmtKinds,y
    ldx stmtKinds+1,y
    jsr printz
    lda #13
    jsr CHROUT

    ; Decl
    lda #<declLabel
    ldx #>declLabel
    ldz #stmt::decl
    jsr printStructAddr

    ; interfaceDecl
    lda #<interfaceDeclLabel
    ldx #>interfaceDeclLabel
    ldz #stmt::interfaceDecl
    jsr printStructAddr

    ; init_expr
    lda #<init_exprLabel
    ldx #>init_exprLabel
    ldz #stmt::init_expr
    jsr printStructAddr

    ; expr
    lda #<exprLabel
    ldx #>exprLabel
    ldz #stmt::expr
    jsr printStructAddr

    ; isDownTo
    lda #<isDownToLabel
    ldx #>isDownToLabel
    ldz #stmt::isDownTo
    jsr printStructBool

    ; body
    lda #<bodyLabel
    ldx #>bodyLabel
    ldz #stmt::body
    jsr printStructAddr

    ; else_body
    lda #<else_bodyLabel
    ldx #>else_bodyLabel
    ldz #stmt::else_body
    jsr printStructAddr

    ; next
    lda #<nextLabel
    ldx #>nextLabel
    ldz #stmt::next
    jsr printStructAddr

    ; lineNumber
    lda #<lineNumberLabel
    ldx #>lineNumberLabel
    jsr printz
    ldz #stmt::lineNumber
    jsr printStructNumber

    lda #13
    jsr CHROUT

    lda #<prompt
    ldx #>prompt
    jsr printz

L1: jsr getKey
    cmp #'d'
    bne L2
    ldq ptr2
    jsr pushQ
    ldz #stmt::decl
    jsr loadPtr
    beq :+
    jsr showDecl
:   jsr popQ
    jmp showStmt
L2: cmp #'f'
    bne L3
    ldq ptr2
    jsr pushQ
    ldz #stmt::interfaceDecl
    jsr loadPtr
    beq :+
    jsr showDecl
:   jsr popQ
    jmp showStmt
L3: cmp #'b'
    bne L4
    ldq ptr2
    jsr pushQ
    ldz #stmt::body
    jsr loadPtr
    beq :+
    jsr showStmt
:   jsr popQ
    jmp showStmt
L4: cmp #'e'
    bne L5
    ldq ptr2
    jsr pushQ
    ldz #stmt::expr
    jsr loadPtr
    beq :+
    jsr showExpr
:   jsr popQ
    jmp showStmt
L5: cmp #CH_BACKARROW
    bne L6
    rts
L6: bra L1
.endproc
