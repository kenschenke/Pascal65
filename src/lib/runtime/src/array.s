;
; array.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

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
.include "float.inc"

.export calcArrayOffset, writeCharArray, readCharArrayFromInput
.export initArrays

.import ltInt16, gtInt16, convertType, subInt16, addInt16, multInt16, skipSpaces
.import memcopy, popax, pushax, FPINP, COMPLM, calcStackOffset

.struct ARRAYINIT
    scopeLevel .byte
    scopeOffset .byte
    heapOffset .word
    minIndex .word
    maxIndex .word
    elemSize .word
    literals .word
    numLiterals .word
    areLiteralsReal .byte
.endstruct

.bss
initPtr: .res 2

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
    jsr rtPopAx
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
    jsr rtRuntimeError
.endproc

; This routine copies an array literal from the PRG's BSS
; into the array's heap, one element at a time.
;
; pointer to first array element is in ptr1
; literal buffer in ptr2
; Number of literals to copy in A/X
; Data type of element in Y
.proc copyArrayLiteral
    ; Save number of literals in tmp1/tmp2
    sta tmp1
    stx tmp2
    sty tmp3                    ; Save data type in tmp3

    ; Make a copy of ptr1 and ptr2 and copy ptr1 to ptr3 and ptr2 to ptr4
    lda ptr1
    sta ptr3
    ldx ptr1 + 1
    stx ptr3 + 1
    jsr pushax
    lda ptr2
    sta ptr4
    ldx ptr2 + 1
    stx ptr4 + 1
    jsr pushax

    ; This section copies the array literal buffer of all
    ; data types except real.
    ldy tmp3                    ; Load data type back from tmp3
    cpy #TYPE_REAL              ; Is this an array of Reals?
    beq L1                      ; Skip if so
    ; Subtract 6 from the array pointer to look at the header
    lda ptr1
    sec
    sbc #6
    sta ptr1
    lda ptr1 + 1
    sbc #0
    sta ptr1 + 1
    ldy #4
    lda (ptr1),y                ; The size of each element
    sta tmp3                    ; Put it in tmp3
:   lsr tmp3                    ; Divide by 2
    beq :+                      ; Skip if zero
    asl tmp1                    ; Multiply tmp1/tmp2 by 2,
    rol tmp2
    jmp :-
:   lda ptr1                    ; Add 6 to ptr1, making it point to
    clc                         ; the address of the first array element.
    adc #6
    sta ptr1
    bcc :+                      ; If the adc #6 did not overflow, skip the next instruction
    inc ptr1 + 1                ; The add overflowed, so increment ptr1 high byte.
:   lda tmp1                    ; Number of bytes to copy in tmp1 and tmp2
    ldx tmp2
    jsr memcopy
    jmp DN

    ; Array of reals -- store each element separately.
    ; The first byte of a real literal is non-zero
    ; if the real is negative. Following that is a null-terminated
    ; string representation of the value. Each has to be converted
    ; to internal FLOAT representation then copied into the array.
L1: ldy #0
    lda (ptr4),y                ; Read the "negative" flag
    pha                         ; Store it away
    iny                         ; Increase index for reading null-terminated value
    ; Copy the null-terminated string into FPBUF
    ldx #0                      ; X is index into FPBUF
:   lda (ptr4),y                ; Load character from real literal string
    sta FPBUF,x                 ; Store it in FPBUF
    beq :+                      ; If zero, skip ahead (done reading string)
    iny                         ; Increment source index
    inx                         ; Increment dest index
    bne :-                      ; Jump back to read next character
    ; Update ptr4
:   iny                         ; Move to first byte of next literal
    tya                         ; Copy source index to A for addition
    clc
    adc ptr4                    ; Move ptr4 to the next literal by adding
    sta ptr4                    ; the index from the last literal to ptr4
    bcc :+
    inc ptr4 + 1
:   jsr FPINP                   ; Convert the string literal into a FLOAT
    pla                         ; Read the "negative" flag
    beq :+                      ; Skip ahead if zero
    ldx #FPLSW                  ; Negate the value
    ldy #3
    jsr COMPLM
    ; Copy FPACC to the array heap
:   ldy #3                      ; Start copying at the last byte
    ldx #3
:   lda FPBASE+FPLSW,x
    sta (ptr3),y
    dex
    dey
    bpl :-
    ; Add 4 to ptr3
    lda ptr3
    clc
    adc #4
    sta ptr3
    bcc :+
    inc ptr3 + 1
    ; Decrement tmp1/tmp2 (number of elements)
:   dec tmp1
    bne L1
    lda tmp2
    beq DN
    dec tmp2
    jmp L1

    ; Restore ptr1 and ptr2
DN: jsr popax
    sta ptr2
    stx ptr2 + 1
    jsr popax
    sta ptr1
    stx ptr1 + 1
    rts
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

.macro loadInitPtr
    lda initPtr
    sta ptr3
    lda initPtr + 1
    sta ptr3 + 1
.endmacro

; This routine initializes all the array heaps

; The pointer to the array of ARRAYINIT structures
; is passed in A/X
.proc initArrays
    sta initPtr
    stx initPtr + 1

    ; Loop through the ARRAYINIT structures
L1: loadInitPtr
    ldy #0                  ; Look at first two bytes
    lda (ptr3),y
    iny
    ora (ptr3),y
    bne :+                  ; If first two bytes are zero, done
    rts

    ; Get the address of the array heap
:   ldy #1
    lda (ptr3),y
    tax
    dey
    lda (ptr3),y
    jsr calcStackOffset

    ; ptr1 points to the address on the runtime stack of the array variable.
    ; Load the address of the heap off the stack and put it back in ptr1 so
    ; ptr1 points to the array's heap instead.
    ldy #0
    lda (ptr1),y
    pha
    iny
    lda (ptr1),y
    sta ptr1 + 1
    pla
    sta ptr1

    ; Add the heap offset to the address
    ldy #ARRAYINIT::heapOffset
    lda ptr1
    clc
    adc (ptr3),y
    sta ptr1
    iny
    lda ptr1 + 1
    adc (ptr3),y
    sta ptr1 + 1

    ; Set the fields in the array header
    ldy #ARRAYINIT::minIndex
    lda (ptr3),y
    ldy #0
    sta (ptr1),y
    ldy #ARRAYINIT::minIndex + 1
    lda (ptr3),y
    ldy #1
    sta (ptr1),y
    ldy #ARRAYINIT::maxIndex
    lda (ptr3),y
    ldy #2
    sta (ptr1),y
    ldy #ARRAYINIT::maxIndex + 1
    lda (ptr3),y
    ldy #3
    sta (ptr1),y
    ldy #ARRAYINIT::elemSize
    lda (ptr3),y
    ldy #4
    sta (ptr1),y
    ldy #ARRAYINIT::elemSize + 1
    lda (ptr3),y
    ldy #5
    sta (ptr1),y

    ; Advance ptr1 past the array header
    lda ptr1
    clc
    adc #6
    sta ptr1
    bcc AL
    inc ptr1 + 1

    ; Check if there are literals to set
AL: ldy #ARRAYINIT::literals
    lda (ptr3),y
    iny
    ora (ptr3),y
    beq NX
    
    ; There are literals - load their address into ptr2
    lda (ptr3),y
    sta ptr2 + 1
    dey
    lda (ptr3),y
    sta ptr2
    ; Load element size and stow it on the CPU stack for a bit
    ldy #ARRAYINIT::numLiterals
    lda (ptr3),y
    pha
    iny
    lda (ptr3),y
    pha
    ; If the literals are reals, put TYPE_REAL in Y, otherwise TYPE_INTEGER
    ldy #ARRAYINIT::areLiteralsReal
    lda (ptr3),y
    beq :+
    ldy #TYPE_REAL
    bne IL
:   ldy #TYPE_INTEGER
IL: pla
    tax
    pla
    jsr copyArrayLiteral

    ; Move to next ARRAYINIT structure
NX: lda initPtr
    clc
    adc #.sizeof(ARRAYINIT)
    sta initPtr
    bcc :+
    inc initPtr + 1
:   jmp L1
DN: rts
.endproc

; This routine writes a character array to the console.
; Inputs
;    A/X - pointer to array heap
;    Field width on runtime stack
.proc writeCharArray
    sta ptr2
    stx ptr2 + 1
    ; Calculate the array length
    jsr getArrayLength
    sta tmp1
    stx tmp2
    ; Pop the field width off the runtime stack
    jsr rtPopAx
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
    jsr rtLeftPad
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
    jsr rtCalcStackOffset
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
