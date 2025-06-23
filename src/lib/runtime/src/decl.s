;
; decl.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; Initialize, clone, and free array and record declarations.

; The runtime code manages array and record declarations using an information
; block.
;
; Array Declarations
;
; +----------------------------------------------------+
; | Bytes | Description                                |
; +-------|--------------------------------------------+
; | 2     | Heap offset - # of bytes past heap pointer |
; | 2     | Low index of array (signed 16-bit integer) |
; | 2     | High index of array                        |
; | 2     | Element size (signed 16-bit integer)       |
; | 2     | Pointer to literals                        |
; | 2     | Number of literals supplied                |
; | 2     | Pointer to element declaration block       |
; | 1     | Element type (see list below)              |
; +-------+--------------------------------------------+
;
; Element Types
;
; +-----------------------+
; | Number | Description  |
; +--------+--------------+
; | 1      | Real numbers |
; | 2      | Record       |
; | 3      | String       |
; | 4      | File handle  |
; | 5      | Array        |
; +--------+--------------+
;
; Array Literals
;
; If literals are part of the array initialization, they are stored in a block
; of memory and pointed at by the array declaration block. Scalar values are
; stored sequentially in memory. Real numbers are stored sequentially as
; null-terminated strings. String literals are stored the same way.
;
; Record Declarations
;
; Record declarations start with a 2-byte record size followed by a list of:
;
; +--------------------------------------------------------+
; | Bytes | Description                                    |
; +-------|------------------------------------------------+
; | 2     | Heap offset - # of bytes past heap pointer     |
; | 2     | Record size                                    |
; +--------------------------------------------------------+
; |  ******* Following list repeated as necessary *******  |
; +--------------------------------------------------------+
; | 1     | Element type from above (0 = end of list)      |
; | 2     | Pointer to declaration block (record or array) |
; | 2     | Offset - # of bytes from start of record       |
; +-------+------------------------------------------------+

.include "runtime.inc"

.export initDecl, freeDecl, cloneDecl

.import heapAlloc, heapFree, pusheax, popeax
.import initArrayDeclaration, initRecordDeclaration
.import freeArrayDeclaration, freeRecordDeclaration
.import cloneArrayDeclaration, cloneRecordDeclaration
.import getArraySize, getRecordSize

.bss
heapAddr: .res 2
declAddr: .res 2
declType: .res 1

.code

.proc initDecl
    cpy #5                          ; Is this an array?
    bne :+                          ; Branch if not
    jmp initArrayDeclaration
:   jmp initRecordDeclaration
.endproc

.proc freeDecl
    ; The declaration block address at the top of the runtime stack
    ; needs to be preserved so it can be freed later.
    sta tmp1                        ; Save the declaration block address
    stx tmp2                        ; in tmp/tmp2
    sty tmp3                        ; Save declaration type in tmp3
    jsr popeax                      ; Pop the heap address off the stack
    sta heapAddr                    ; Store in heapAddr
    stx heapAddr+1
    jsr pusheax                     ; Push the heap address back onto the stack
    lda tmp1                        ; Load the declaration block address back into A/X
    ldx tmp2
    ldy tmp3                        ; Load the declaration type back into Y
    cpy #5                          ; Is this an array?
    bne :+                          ; Branch if not
    jsr freeArrayDeclaration
    jmp DN
:   jsr freeRecordDeclaration
DN: lda heapAddr
    ldx heapAddr+1
    jmp heapFree
.endproc

.proc cloneDecl
    sty declType                    ; Store the declaration type in declType for later
    sta declAddr                    ; Store the declaration block addr in declAddr
    stx declAddr+1
    cpy #5                          ; Are we cloning an array
    bne :+                          ; Branch if not
    jsr getArraySize                ; Calculate the size of the array
    jmp L1                          ; Skip to L1
:   jsr getRecordSize               ; Get the size of the record
L1: jsr heapAlloc                   ; Allocate some memory for the cloned array or record
    sta heapAddr                    ; Store the target address in heapAddr
    stx heapAddr+1
    jsr popeax                      ; Pop the source address off the stack
    sta ptr1                        ; Store it in ptr1 for a bit
    stx ptr1+1
    lda heapAddr                    ; Load the target address into A/X
    ldx heapAddr+1
    jsr pusheax                     ; Push it onto the stack
    lda ptr1                        ; Load the source address into A/X
    ldx ptr1+1
    jsr pusheax                     ; Push that onto the stack as well
    lda declAddr                    ; Load the declaration block addr back into declAddr
    ldx declAddr+1
    ldy declType                    ; Load the declaration type into Y
    cpy #5                          ; Is this an array?
    bne :+                          ; Branch if not
    jsr cloneArrayDeclaration
    jmp ZZ
:   jsr cloneRecordDeclaration
ZZ: lda heapAddr                    ; Put the target address back on the stack
    ldx heapAddr+1
    jmp pusheax
.endproc
