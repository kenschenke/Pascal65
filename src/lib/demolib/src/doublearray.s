;
; doublearray.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"

.export doubleArray

.import doubleArrayHelper

.proc doubleArray
    lda #0              ; Load the first parameter's address
    jsr rtLibLoadParam
    sta ptr1            ; This is a pointer to the parameter's location
    stx ptr1 + 1        ; on the runtime stack.
    ldy #1
    lda (ptr1),y        ; Dereference the pointer to get at the address
    tax
    dey
    lda (ptr1),y
    jmp doubleArrayHelper
.endproc
