;
; addEnumsToSymtab.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; addEnumsToSymtab routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export addEnumsToSymtab

.import calcNamePtr

.bss

currentEnum: .res 4
enumType: .res 4
name: .res 4
newType: .res 4
newSymbol: .res 4

.code

; On entry:
;    ptr1 contains type to assign to each symbol
;    ptr2 contains first param_list structure
.proc addEnumsToSymtab
    ; Store 
    ldq ptr1
    stq enumType
    ldq ptr2
    stq currentEnum
    
    ; Loop through the list of enum declarations
L1: ldq currentEnum
    jsr isQZero
    bne :+
    rts

    ; Create a type for the enum
:   lda #TYPE_ENUMERATION_VALUE
    jsr pushA                       ; kind
    lda #1
    jsr pushA                       ; isConst
    ldq enumType
    jsr typeClone
    jsr pushQ                       ; subtype
    jsr pushQZero                   ; params
    jsr typeCreate
    stq newType

    ; Look up the enum name
    ldq currentEnum
    ldz #decl::name
    jsr calcNamePtr
    stq name

    ; Create a symbol node
    lda #SYMBOL_LOCAL
    jsr pushA                       ; kind
    ldq newType
    jsr pushQ                       ; type
    ldq name
    jsr pushQ                       ; name
    jsr symbolCreate
    stq newSymbol
    stq ptr3
    
    ; Set the new symbol's decl to the current enum
    ldz #symbol::decl
    ldx #0
:   lda currentEnum,x
    nop
    sta (ptr3),z
    inz
    inx
    cpx #4
    bne :-

    ; Bind the symbol to the current scope's symbol table
    ldq name
    stq ptr2
    ; ptr3 already contains new symbol
    sec
    jsr scopeBind
    bcc L2
    ; scopeBind failed - free the things we allocated
    ldq newSymbol
    jsr freeSymbol

L2: ldq currentEnum
    stq ptr1
    ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    stq currentEnum
    jmp L1
.endproc
