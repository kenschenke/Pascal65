;
; doubleparm.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"
.include "types.inc"

.export doubleParam

; Doubles the parameter (multiply by 2)
.proc doubleParam
    lda #0                  ; Load the address of the first parameter
    jsr rtLibLoadParam
    sta ptr1                ; Store it in ptr1
    stx ptr1 + 1
    ldy #0
    lda (ptr1),y            ; Load low byte of value
    asl a                   ; double it
    pha                     ; save it on the CPU stack
    iny
    lda (ptr1),y            ; Load high byte of value
    rol a                   ; double it
    tax                     ; put it in X
    pla                     ; pop low byte off CPU stack
    ldy #0
    jmp rtLibStoreVarParam  ; Store the result back into the first parameter
.endproc
