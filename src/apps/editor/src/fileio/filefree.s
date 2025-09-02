;
; filefree.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; fileFree routine

.include "zeropage.inc"
.include "editor.inc"
.include "4510macros.inc"
.include "asmlib.inc"

.export fileFree

.import isQZero

.bss

filePtr: .res 4
thisLine: .res 4

.code

; Frees the lines and buffers for the file in Q
;    ptr1 - pointer to file
;    ptr2 - pointer to current line
.proc fileFree
    stq ptr1
    stq filePtr
    ; Walk through the lines in the file
    ldz #EDITFILE::firstLine
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
L1: ldq ptr2
    jsr isQZero
    beq L3
    stq thisLine
    ; Is the line empty?
    ldz #EDITLINE::capacity
    nop
    lda (ptr2),z
    beq L2
    ; Free the line contents
    ldz #EDITLINE::buffer
    neg
    neg
    nop
    lda (ptr2),z
    jsr heapFree
    ldq thisLine
    stq ptr2
L2: ; Copy the next line pointer to ptr3
    ldz #EDITLINE::next
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr3
    ; Free the line structure
    ldq ptr2
    jsr heapFree
    ; Move to the next line
    ldq ptr3
    stq ptr2
    jmp L1
L3: ; Free the file structure
    ldq filePtr
    jmp heapFree
.endproc
