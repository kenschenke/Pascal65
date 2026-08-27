;
; dumpSymtab.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; dumpSymtab routine

.include "ast.inc"
.include "tree.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export dumpSymtab

.import printz, newLine, dumpChar, indent, printNumber, dumpType

.bss

node: .res .sizeof(TREENODE)

.data

nullStr: .asciiz "(null)"
strSYMBOL_LOCAL: .asciiz "SYMBOL-LOCAL"
strSYMBOL_PARAM: .asciiz "SYMBOL-PARAM"
strSYMBOL_GLOBAL: .asciiz "SYMBOL-GLOBAL"

kinds: .byte .LOBYTE(strSYMBOL_LOCAL), .HIBYTE(strSYMBOL_LOCAL)
       .byte .LOBYTE(strSYMBOL_PARAM), .HIBYTE(strSYMBOL_PARAM)
       .byte .LOBYTE(strSYMBOL_GLOBAL), .HIBYTE(strSYMBOL_GLOBAL)

.code

; This routine dumps the symbol table node passed in Q.
; It also recurses to the left and right children as well.
.proc dumpSymtab
    jsr isQZero
    bne :+
    rts
:   stq ptr1
    jsr pushQ               ; Save the symbol table node on the stack

    ; Left child
    ldz #TREENODE::left
    neg
    neg
    nop
    lda (ptr1),z
    jsr dumpSymtab

    jsr indent

    ; Print the name
    jsr reloadPtr
    ldz #0
    ldx #0
:   nop
    lda (ptr1),z
    sta node,x
    beq :+
    inx
    inz
    bne :-
:   lda #<node
    ldx #>node
    jsr printz

    lda #' '
    jsr dumpChar

    ; Kind
    jsr getData
    ldz #symbol::kind
    nop
    lda (ptr1),z
    asl a
    tax
    lda kinds,x
    pha
    lda kinds+1,x
    tax
    pla
    jsr printz
    
    lda #' '
    jsr dumpChar

    ; Level
    jsr getData
    ldz #symbol::level
    lda #'L'
    jsr printNumber
    lda #' '
    jsr dumpChar

    ; Offset
    jsr getData
    ldz #symbol::offset
    lda #'O'
    jsr printNumber

    lda #' '
    jsr dumpChar

    ; Decl
    jsr getData
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr dumpType

    jsr newLine

    ; Right child
    jsr reloadPtr
    ldz #TREENODE::right
    neg
    neg
    nop
    lda (ptr1),z
    jsr dumpSymtab

    jsr popQ
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

; This routine gets the data from the tree node
.proc getData
    jsr reloadPtr
    ldz #TREENODE::data
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    rts
.endproc
