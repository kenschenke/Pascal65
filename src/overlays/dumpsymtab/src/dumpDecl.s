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

.import dumpSymtab, dumpStmt, newLine, printz, dumpString, level, indent
.import dumpType, dumpChar, printNumber

.data

strDecl: .asciiz "decl"
strSymtab: .byte "symtab", $0d, $00
strUnitSymtab: .byte "unitSymtab", $0d, $00

.code

; This routine dumps the symbol table for the decl in Q.
; It also recurses down the tree, dumping any symbol tables
; it finds in child nodes.
.proc dumpDecl
    jsr pushQ

L1: ldz #0
    neg
    neg
    nop
    lda (stackPointer),z
    jsr isQZero
    bne :+
    jmp L6

:   stq ptr1
    ldz #decl::kind
    nop
    lda (ptr1),z
:   cmp #DECL_USES
    bne :+
    jmp L5

    ; Decl string
:   jsr indent
    lda #<strDecl
    ldx #>strDecl
    jsr printz

    ; Name
    jsr reloadPtr
    ldz #decl::name
    jsr dumpString
    lda #' '
    jsr dumpChar
    
    ; Level
    jsr reloadPtr
    ldz #decl::node
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jsr isQZero
    bne :+
    lda #13
    jsr dumpChar
    bra L2
:   ldz #symbol::level
    lda #'L'
    jsr printNumber
    lda #' '
    jsr dumpChar

    ; Offset
    jsr reloadPtr
    ldz #decl::node
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #symbol::offset
    lda #'O'
    jsr printNumber
    lda #' '
    jsr dumpChar

    ; Type
    jsr reloadPtr
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr dumpType

    jsr newLine

    ; Dump symbol table for record
    jsr reloadPtr
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_RECORD
    bne L2
    ldz #type::symtab
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L2
    inc level
    jsr indent
    lda #<strSymtab
    ldx #>strSymtab
    jsr printz
    inc level
    ldz #type::symtab
    neg
    neg
    nop
    lda (ptr1),z
    jsr dumpSymtab
    dec level
    dec level

L2: jsr reloadPtr
    ldz #decl::symtab
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L3
    inc level
    jsr indent
    lda #<strSymtab
    ldx #>strSymtab
    jsr printz
    ; jsr newLine
    inc level
    ldz #decl::symtab
    neg
    neg
    nop
    lda (ptr1),z
    jsr dumpSymtab
    dec level
    
    dec level

L3: jsr reloadPtr
    ldz #decl::unitSymtab
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L4
    lda #<strUnitSymtab
    ldx #>strUnitSymtab
    jsr printz
    jsr dumpSymtab

    ; Code
L4: jsr reloadPtr
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    jsr dumpStmt

L5: ldz #0
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #0
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    jmp L1
    
L6: jsr popQ
    rts
.endproc

.proc reloadPtr
    ldz #0
    neg
    neg
    nop
    lda (stackPointer),z
    stq ptr1
    rts
.endproc
