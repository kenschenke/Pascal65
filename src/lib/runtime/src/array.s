; Runtime array routines
;
; Arrays are stored in heap memory, in the following layout.
;    First two bytes are the lower bound of the array index.
;    Next two bytes are the upper bound of the array index.
;    Next two bytes are the size of each array element.
;    Each of the array elements follows.

.include "error.inc"
.include "runtime.inc"

.import runtimeError, ltInt16, gtInt16
.import subInt16, addInt16, multInt16, popax

.export calcArrayOffset, initArrayHeap

; This routine calculates the address of an element in an array's
; heap buffer for an index. It expects the array index to be pushed
; onto the runtime stack and the array heap address to be in A/X.
;
; The address in the array's heap is returned in A/X.
.proc calcArrayOffset
    sta ptr1            ; Array heap address in ptr1
    stx ptr1 + 1
    jsr popax
    sta intOp1          ; Array index in intOp1
    stx intOp1 + 1
    jsr checkArrayBounds
    ldy #0
    lda (ptr1),y
    sta intOp2          ; Lower bound in intOp2
    iny
    lda (ptr1),y
    sta intOp2 + 1
    jsr subInt16
    iny                 ; Skip over the upper bound
    iny
    iny
    lda (ptr1),y        ; Element size in intOp2
    sta intOp2
    iny
    lda (ptr1),y
    sta intOp2 + 1
    jsr multInt16
    lda #6              ; Skip over first 6 bytes of array heap
    sta intOp2
    lda #0
    sta intOp2 + 1
    jsr addInt16
    lda ptr1            ; Add the heap address to the offset
    sta intOp2
    lda ptr1 + 1
    sta intOp2 + 1
    jsr addInt16
    lda intOp1
    ldx intOp1 + 1
    rts
.endproc

; Check the array index to ensure it is within array bounds
; This routine is called by calcArrayOffset and expects the
; array's heap address to be stored in ptr1 and the
; array index to be in intOp1, which is preserved.
.proc checkArrayBounds
    ldy #0
    lda (ptr1),y
    sta intOp2          ; Lower array bound
    iny
    lda (ptr1),y
    sta intOp2 + 1
    jsr ltInt16         ; Is index < lower bound?
    bne L1              ; If so, runtime error
    iny
    lda (ptr1),y
    sta intOp2          ; Upper array bound
    iny
    lda (ptr1),y
    sta intOp2 + 1
    jsr gtInt16         ; Is index > upper bound
    bne L1              ; If so, runtime error
    rts
L1:
    lda #rteValueOutOfRange
    jsr runtimeError
.endproc

; This routine initializes an array heap, which is the
; following format:
;
;    Lower bound of index (2 byte integer)
;    Upper bound of index (2 byte integer)
;    Size of each array element (2 byte integer)
;
; The inputs to the routine are passed in the following way:
;    Size of each array element pushed onto runtime stack
;    Upper bound pushed onto runtime stack
;    Lower bound pushed onto runtime stack
;    Array heap address in A/X
.proc initArrayHeap
    sta ptr1
    stx ptr1 + 1
    jsr popax
    ldy #0
    sta (ptr1),y        ; Store lower array bound
    ldy #1
    txa
    sta (ptr1),y
    jsr popax
    ldy #2
    sta (ptr1),y        ; Store upper array bound
    txa
    ldy #3
    sta (ptr1),y
    jsr popax
    ldy #4
    sta (ptr1),y        ; Store element size
    txa
    ldy #5
    sta (ptr1),y
    rts
.endproc
