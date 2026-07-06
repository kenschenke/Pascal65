;
; showDecl.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; showDecl routine

.include "ast.inc"
.include "asmlib.inc"
.include "4510macros.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"

CH_BACKARROW = 95

.export showDecl

.import printz, printzLong, printStructAddr, printNamePtr
.import printStructBool, printStructNumber, showStmt, getKey, loadPtr
.import showType, showSubExpr, showAddr, showExpr, showTypeKind, showSymtab

.data

kindLabel: .asciiz "kind: "
nameLabel: .asciiz "name: "
typeLabel: .asciiz "type: "
valueLabel: .asciiz "value: "
nodeLabel: .asciiz "node: "
symtabLabel: .asciiz "symtab: "
codeLabel: .asciiz "code: "
nextLabel: .asciiz "next: "
unitSymtabLabel: .asciiz "unitSymtab: "
isLibraryLabel: .asciiz "isLibrary: "
lineNumberLabel: .asciiz "line: "
prompt: .byte "T:type  V:value  C:code  S:symtab  N:next  ", $5f, ":back", $0d, $0d, $0

strDECL_CONST: .asciiz "DECL_CONST"
strDECL_TYPE: .asciiz "DECL_TYPE"
strDECL_USES: .asciiz "DECL_USES"
strDECL_VARIABLE: .asciiz "DECL_VARIABLE"

declKinds: .byte .LOBYTE(strDECL_CONST), .HIBYTE(strDECL_CONST)
           .byte .LOBYTE(strDECL_TYPE), .HIBYTE(strDECL_TYPE)
           .byte .LOBYTE(strDECL_USES), .HIBYTE(strDECL_USES)
           .byte .LOBYTE(strDECL_VARIABLE), .HIBYTE(strDECL_VARIABLE)

.code

.proc showDecl
    stq ptr2

    ; Kind
    lda #<kindLabel
    ldx #>kindLabel
    jsr printz
    ldz #decl::kind
    nop
    lda (ptr2),z
    asl a
    tay
    lda declKinds,y
    ldx declKinds+1,y
    jsr printz
    lda #13
    jsr CHROUT

    ; Name
    lda #<nameLabel
    ldx #>nameLabel
    ldz #decl::name
    jsr printNamePtr

    ; Type
    lda #<typeLabel
    ldx #>typeLabel
    jsr printz
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr2),z
    jsr showAddr
    ldq ptr2
    jsr pushQ
    ldz #decl::type
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
    ldz #decl::value
    neg
    neg
    nop
    lda (ptr2),z
    jsr showAddr
    ldz #decl::value
    jsr showSubExpr

    ; Symtab
    lda #<symtabLabel
    ldx #>symtabLabel
    ldz #decl::symtab
    jsr printStructAddr

    ; Code
    lda #<codeLabel
    ldx #>codeLabel
    ldz #decl::code
    jsr printStructAddr

    ; Next
    lda #<nextLabel
    ldx #>nextLabel
    ldz #decl::next
    jsr printStructAddr

    ; unitSymbab
    lda #<unitSymtabLabel
    ldx #>unitSymtabLabel
    ldz #decl::unitSymtab
    jsr printStructAddr

    ; isLibrary
    lda #<isLibraryLabel
    ldx #>isLibraryLabel
    ldz #decl::isLibrary
    jsr printStructBool

    ; lineNumber
    lda #<lineNumberLabel
    ldx #>lineNumberLabel
    jsr printz
    ldz #decl::lineNumber
    jsr printStructNumber

    lda #13
    jsr CHROUT

    lda #<prompt
    ldx #>prompt
    jsr printz

L1: jsr getKey
    cmp #'c'
    bne L2
    ldq ptr2
    jsr pushQ
    ldz #decl::code
    jsr loadPtr
    beq :+
    jsr showStmt
:   jsr popQ
    jmp showDecl
L2: cmp #'t'
    bne L3
    ldq ptr2
    jsr pushQ
    ldz #decl::type
    jsr loadPtr
    beq :+
    jsr showType
:   jsr popQ
    jmp showDecl
L3: cmp #'n'
    bne L4
    ldq ptr2
    jsr pushQ
    ldz #decl::next
    jsr loadPtr
    beq :+
    jsr showDecl
:   jsr popQ
    jmp showDecl
L4: cmp #'v'
    bne L5
    ldq ptr2
    jsr pushQ
    ldz #decl::value
    jsr loadPtr
    beq :+
    jsr showExpr
:   jsr popQ
    jmp showDecl
L5: cmp #'s'
    bne L6
    ldq ptr2
    jsr pushQ
    ldz #decl::symtab
    jsr loadPtr
    beq :+
    jsr showSymtab
:   jsr popQ
    jmp showDecl
L6: cmp #CH_BACKARROW
    bne L7
    rts
L7: jmp L1
.endproc
