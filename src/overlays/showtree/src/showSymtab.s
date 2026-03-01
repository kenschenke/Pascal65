;
; showSymtab.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; showSymtab routine

.include "ast.inc"
.include "asmlib.inc"
.include "4510macros.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "symtab.inc"
.include "tree.inc"

CH_BACKARROW = 95

.export showSymtab

.import printz, printzLong, getKey, loadPtr, printStructAddr, showSymbol

.data

keyLabel: .asciiz "key: "
leftLabel: .asciiz "left: "
rightLabel: .asciiz "right: "
symbolLabel: .asciiz "symbol: "
prompt: .byte "L:left  R:right  S:symbol  ", $5f, ":back", $0d, $0d, $0

.code

.proc showSymtab
    stq ptr2

    ; Key
    lda #<keyLabel
    ldx #>keyLabel
    jsr printz
    ldq ptr2
    jsr printzLong
    lda #13
    jsr CHROUT

    ; Left
    lda #<leftLabel
    ldx #>leftLabel
    ldz #TREENODE::left
    jsr printStructAddr

    ; Right
    lda #<rightLabel
    ldx #>rightLabel
    ldz #TREENODE::right
    jsr printStructAddr

    ; Symbol
    lda #<symbolLabel
    ldx #>symbolLabel
    ldz #TREENODE::data
    jsr printStructAddr

    lda #13
    jsr CHROUT

    lda #<prompt
    ldx #>prompt
    jsr printz

L2: jsr getKey
    cmp #'l'
    bne L3
    ldq ptr2
    jsr pushQ
    ldz #TREENODE::left
    jsr loadPtr
    beq :+
    jsr showSymtab
:   jsr popQ
    jmp showSymtab
L3: cmp #'r'
    bne L4
    ldq ptr2
    jsr pushQ
    ldz #TREENODE::right
    jsr loadPtr
    beq :+
    jsr showSymtab
:   jsr popQ
    jmp showSymtab
L4: cmp #'s'
    bne L5
    ldq ptr2
    jsr pushQ
    ldz #TREENODE::data
    jsr loadPtr
    beq :+
    jsr showSymbol
:   jsr popQ
    jmp showSymtab
L5: cmp #CH_BACKARROW
    bne L6
    rts
L6: bra L2
.endproc
