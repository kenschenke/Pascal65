;
; dumpDecl.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; dumpDecl routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export dumpDecl

.import dumpPtrString, printz, dumpTypeMember, dumpStmtMember, level, newLine, showPrefix, dumpExpr

.data

strDECL_CONST: .asciiz "DECL-CONST"
strDECL_TYPE: .asciiz "DECL-TYPE"
strDECL_USES: .asciiz "DECL-USES"
strDECL_VARIABLE: .asciiz "DECL-VARIABLE"

kinds: .byte .LOBYTE(strDECL_CONST), .HIBYTE(strDECL_CONST)
       .byte .LOBYTE(strDECL_TYPE), .HIBYTE(strDECL_TYPE)
       .byte .LOBYTE(strDECL_USES), .HIBYTE(strDECL_USES)
       .byte .LOBYTE(strDECL_VARIABLE), .HIBYTE(strDECL_VARIABLE)

.code

.proc dumpDecl
    stq ptr1
    lda #'D'
    jsr showPrefix

    ldz #decl::kind
    nop
    lda (ptr1),z
    asl a
    tay
    lda kinds,y
    ldx kinds+1,y
    jsr printz

    ldz #decl::name
    jsr dumpPtrString

    jsr newLine
    ldz #decl::type
    jsr dumpTypeMember

    ldq ptr1
    jsr pushQ

    ldz #decl::value
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+
    inc level
    jsr dumpExpr
    dec level
    jsr newLine

:   jsr popQ
    stq ptr1
   
    inc level
    ldz #decl::code
    jsr dumpStmtMember
    dec level

    rts
.endproc
