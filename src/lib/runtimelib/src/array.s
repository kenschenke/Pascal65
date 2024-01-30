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
.include "types.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp calcArrayOffset
jmp initArrayHeap
jmp writeCharArray
jmp readCharArrayFromInput

; end of exports
.byte $00, $00, $00

; imports

runtimeError: jmp $0000
ltInt16: jmp $0000
gtInt16: jmp $0000
calcStackOffset: jmp $0000
convertType: jmp $0000
subInt16: jmp $0000
addInt16: jmp $0000
multInt16: jmp $0000
popax: jmp $0000
pushax: jmp $0000
leftpad: jmp $0000
skipSpaces: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

; This routine calculates the address of an element in an array's
; heap buffer for an index. It expects the array index to be pushed
; onto the runtime stack and the array heap address to be in A/X.
;
; The address in the array's heap is returned in A/X.
; The data type of the index is passed in Y.
.proc calcArrayOffset
    sta ptr1            ; Array heap address in ptr1
    stx ptr1 + 1
    tya                 ; Push the index data type on the CPU stack
    pha
    jsr popax
    sta intOp1          ; Array index in intOp1
    stx intOp1 + 1
    pla                 ; Pop the index data type off the CPU stack
    ldx #TYPE_INTEGER
    jsr convertType
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

; This routine calculates the length of the array
; and returns it in A/X.  intOp1, intOp2, and ptr1 are destroyed.
; The pointer to the array heap is passed in A/X.
.proc getArrayLength
    sta ptr1
    stx ptr1 + 1
    ldy #0
    lda (ptr1),y
    sta intOp2
    iny
    lda (ptr1),y
    sta intOp2 + 1
    iny
    lda (ptr1),y
    sta intOp1
    iny
    lda (ptr1),y
    sta intOp1 + 1
    jsr subInt16
    lda #1
    sta intOp2
    lda #0
    sta intOp2 + 1
    jsr addInt16
    lda intOp1
    ldx intOp1 + 1
    rts
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
    sta ptr2
    stx ptr2 + 1
    jsr popax
    ldy #0
    sta (ptr2),y        ; Store lower array bound
    ldy #1
    txa
    sta (ptr2),y
    jsr popax
    ldy #2
    sta (ptr2),y        ; Store upper array bound
    txa
    ldy #3
    sta (ptr2),y
    jsr popax
    ldy #4
    sta (ptr2),y        ; Store element size
    txa
    ldy #5
    sta (ptr2),y
    rts
.endproc

; This routine writes a character array to the console.
; Inputs
;    A - variable nesting level
;    X - variable offset on runtime stack
;    Field width on runtime stack
.proc writeCharArray
    jsr calcStackOffset
    ldy #1
    lda (ptr1),y        ; Look up the array heap address
    sta ptr2 + 1
    dey
    lda (ptr1),y
    sta ptr2
    ; Calculate the array length
    lda ptr2
    ldx ptr2 + 1
    jsr getArrayLength
    sta tmp1
    stx tmp2
    ; Pop the field width off the runtime stack
    jsr popax
    sta tmp3
    ; If field width specified and array length <= 255
    lda tmp2            ; Look at high byte of array length
    bne L0              ; If non-zero, skip left-padding
    lda tmp3            ; Look at requested field width
    beq L0              ; If it's zero, skip left-padding
    lda tmp1            ; Array length
    pha                 ; Save tmp1 since leftpad destroys it
    tax
    lda tmp3
    jsr leftpad
    pla                 ; Restore the array length
    sta tmp1
    ; Loop until tmp1/tmp2 are zero
L0:
    ; Skip over the array header
    lda ptr2
    clc
    adc #6
    sta ptr2
    lda ptr2 + 1
    adc #0
    sta ptr2 + 1
    ldy #0
L1:
    lda (ptr2),y
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
    ; Increment ptr2
    lda ptr2
    clc
    adc #1
    sta ptr2
    lda ptr2 + 1
    adc #0
    sta ptr2 + 1
    clc
    bcc L1
L2:
    rts
.endproc

; This routine reads a string of characters from the input
; and stores them in a character array.  It skips spaces in
; the input until the first non-space.  If the input is larger
; than the array, it stops reading at the limit.  If the input
; is smaller than the array, the remainder is space-filled.
;
; Inputs
;   A - nesting level of array variable
;   X - value offset on runtime stack
.proc readCharArrayFromInput
    jsr calcStackOffset
    ldy #1                  ; Store array heap address in ptr2
    lda (ptr1),y            ; and leave it in A/X for call
    sta ptr2 + 1            ; to getArrayLength
    tax
    dey
    lda (ptr1),y
    sta ptr2
    jsr getArrayLength
    pha                     ; Store the array length on the CPU stack
    txa
    pha
    jsr skipSpaces          ; Skip over spaces in the input buffer
    ; Move ptr2 (points to array heap) to the first array element.
    lda ptr2
    clc
    adc #6
    sta ptr2
    lda ptr2 + 1
    adc #0
    sta ptr2 + 1
    ; Pull the array length from the CPU stack and store in tmp1/tmp2
    pla
    sta tmp2
    pla
    sta tmp1
    ; Copy characters from the input buffer until the end of the
    ; buffer is reached or the end of the array is reached.
    ldx inputPos            ; Current position in the input buffer
    lda #0
    sta tmp3                ; Current array position
L1:
    lda tmp1
    ora tmp2
    beq L2                  ; Branch if end of the array reached
    lda tmp3
    cmp inputBufUsed
    bcs L2                  ; Branch if end of the buffer reached
    ldy inputPos
    lda (inputBuf),y
    ldy tmp3
    sta (ptr2),y
    inc tmp3
    inc inputPos
    ; Decrement tmp1/tmp2
    lda tmp1
    sec
    sbc #1
    sta tmp1
    lda tmp2
    sbc #0
    sta tmp2
    clc
    bcc L1
L2:
    ; Update ptr2 to the current array position
    lda tmp3
    clc
    adc ptr2
    sta ptr2
    lda ptr2 + 1
    adc #0
    sta ptr2 + 1
    ; Space-fill the remainder of the array (if any)
    ldy #0
L3:
    lda tmp1
    ora tmp2
    beq L4                  ; Branch if tmp1/tmp2 are zero
    lda #' '
    sta (ptr2),y
    ; Increment ptr2
    lda ptr2
    clc
    adc #1
    sta ptr2
    lda ptr2 + 1
    adc #0
    sta ptr2 + 1
    ; Decrement tmp1/tmp2
    lda tmp1
    sec
    sbc #1
    sta tmp1
    lda tmp2
    sbc #0
    sta tmp2
    clc
    bcc L3
L4:
    rts
.endproc
