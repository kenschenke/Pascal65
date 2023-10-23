; Runtime array routines
;
; Arrays are stored in heap memory, in the following layout.
;    First two bytes are the lower bound of the array index.
;    Next two bytes are the upper bound of the array index.
;    Next two bytes are the size of each array element.
;    Each of the array elements follows.

.include "error.inc"
.include "runtime.inc"
.include "cbm_kernal.inc"

.import runtimeError, ltInt16, gtInt16, calcStackOffset
.import subInt16, addInt16, multInt16, popax, pushax

.export calcArrayOffset, initArrayHeap, writeCharArray

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

; This routine writes a character array to the console.
; The array index minimum (16-bit) is pushed to the runtime stack,
; followed by the index maximum (also 16-bit).
; The variable offset on the runtime stack is passed in X
; The variable nesting level is passed in A
.proc writeCharArray
    jsr calcStackOffset
    ; Leave the array's heap address in ptr1 for a second
    ; and store the min/max on the CPU stack
    jsr popax           ; Pop the array max index off the runtime stack
    pha                 ; and push it on the CPU stack
    txa
    pha
    ; Now do the same for the minimum index
    jsr popax
    sta tmp1            ; Store the minimum in tmp1/tmp2
    stx tmp2
    pha
    txa
    pha
    lda tmp1
    ldx tmp2
    jsr pushax          ; Push the min index to the runtime stack
    ; Calculate the address of the first character in the array
    ldy #1
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    jsr calcArrayOffset
    sta ptr1            ; Store the first char's address in ptr1
    stx ptr1 + 1
    ; Pop the min index off the CPU stack and store in intOp2
    pla
    sta intOp2 + 1
    pla
    sta intOp2
    ; Pop the max index off the CPU stack and store in intOp1
    pla
    sta intOp1 + 1
    pla
    sta intOp1
    jsr subInt16        ; Subtract intOp2 from intOp1
    ; Add 1 to the difference and store in tmp1/tmp2
    lda intOp1
    clc
    adc #1
    sta tmp1
    lda intOp1 + 1
    adc #0
    sta tmp2
    ; Loop until tmp1/tmp2 are zero
    ldy #0
L1:
    lda (ptr1),y
    jsr CHROUT
    ; Decrement tmp1/tmp2
    lda tmp1
    sec
    sbc #1
    sta tmp1
    lda tmp2
    sbc #0
    sta tmp2
    lda tmp1
    ora tmp2
    beq L2
    ; Increment ptr1
    lda ptr1
    clc
    adc #1
    sta ptr1
    lda ptr1 + 1
    adc #0
    sta ptr1 + 1
    jmp L1
L2:
    rts
.endproc

