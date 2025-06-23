;
; array.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024-2025
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

ARRAYDECL_REAL = 1
ARRAYDECL_RECORD = 2
ARRAYDECL_STRING = 3
ARRAYDECL_FILE = 4
ARRAYDECL_ARRAY = 5

.export writeCharArray, readCharArrayFromInput, calcArrayElem
.export initArrayDeclaration, freeArrayDeclaration, cloneArrayDeclaration
.export getArraySize

.import ltInt16, gtInt16, convertType, subInt16, addInt16, multInt16, skipSpaces
.import memcopy, popax, pushax, FPINP, COMPLM, pusheax, popeax
.import runtimeError, convertString, heapAlloc, heapFree, fileClose
.import freeRecordDeclaration, cloneRecordDeclaration

.struct ARRAYDECL
    heapOffset .word                ; Byte offset into memory heap
    minIndex .word                  ; Low index of array
    maxIndex .word                  ; High index
    elemSize .word                  ; Size of each element
    literals .word                  ; Pointer to literals for initialization
    numLiterals .word               ; Number of literals
    elemDecl .word                  ; Pointer to declaration block for array elements
    elemType .byte                  ; one of ARRAYDECL_*
.endstruct

.bss
initPtr: .res 2

; Local variables used by initArrayDeclaration
numElems: .res 2
ndxElems: .res 2
numLiterals: .res 2

.code

; This routine calculates the address of an element. It builds on
; calcArrayOffset but pulls its input off the runtime stack. It
; is used to shrink memory footprint of generated code. The inputs
; for the routine are the array heap address under the index on the stack.
; The data type for the index is passed in A.
; The address of the array element is pushed back onto the runtime stack.
.proc calcArrayElem
    sta tmp3
    jsr popeax              ; pop array index off stack
    sta tmp1
    stx tmp2
    jsr popeax              ; pop array heap address off stack
    pha
    txa
    pha
    lda tmp1
    ldx tmp2
    jsr pushax
    pla
    tax
    pla
    ldy tmp3
    jsr calcArrayOffset
    jmp pusheax
.endproc

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
    cpy #ARRAYDECL_REAL         ; Is this an array of Reals?
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

; This routine initializes an array using an ARRAYDECL structure
; Inputs:
;   pointer to setup data (passed in A/X)
;   pointer to heap memory (top of stack, preserved and left at top of stack)
; Locals:
;   number of array elements
;   element index for loop
;   pointer to heap memory (ptr1)
;   pointer to setup data (ptr2)
;   pointer to array literal buffer (ptr4)

.proc initArrayDeclaration
    sta ptr2                    ; Store pointer to setup data
    stx ptr2+1
    jsr popeax                  ; Pop pointer to heap memory and store
    sta ptr1
    stx ptr1+1
    jsr pusheax                 ; Keep the heap pointer on the stack
    ; Add heap offset to the pointer
    ldy #ARRAYDECL::heapOffset
    lda ptr1
    clc
    adc (ptr2),y
    sta ptr1
    iny
    lda ptr1+1
    adc (ptr2),y
    sta ptr1+1
    ; Copy minIndex, maxIndex, and elemSize from declaration block into array header
    ldy #ARRAYDECL::minIndex
    lda (ptr2),y
    ldy #0
    sta (ptr1),y
    ldy #ARRAYDECL::minIndex+1
    lda (ptr2),y
    ldy #1
    sta (ptr1),y
    ldy #ARRAYDECL::maxIndex
    lda (ptr2),y
    ldy #2
    sta (ptr1),y
    ldy #ARRAYDECL::maxIndex+1
    lda (ptr2),y
    ldy #3
    sta (ptr1),y
    ldy #ARRAYDECL::elemSize
    lda (ptr2),y
    ldy #4
    sta (ptr1),y
    ldy #ARRAYDECL::elemSize+1
    lda (ptr2),y
    ldy #5
    sta (ptr1),y
    ; Calculate number of array elements.
    ; getArrayLength destroys ptr1, but it uses it for the heap
    ; pointer so it's okay since this code is doing the same.
    lda ptr1
    ldx ptr1+1
    jsr getArrayLength
    sta numElems
    stx numElems+1
    ; Clear ndxElems
    lda #0
    sta ndxElems
    sta ndxElems+1
    ; Move ptr1 past array header
    lda ptr1
    clc
    adc #6
    sta ptr1
    lda ptr1+1
    adc #0
    sta ptr1+1
    ; Check the element type
    ldy #ARRAYDECL::elemType
    lda (ptr2),y
    ; Are they strings?
    cmp #ARRAYDECL_STRING
    bne :+
    jmp initArrayStrings
    ; Are they records?
:   cmp #ARRAYDECL_RECORD
    beq DN
    ; Are they files?
    cmp #ARRAYDECL_FILE
    bne :+
    jmp initArrayFiles
:   ; Elements are scalar. Initialize them from literals.
    ldy #6
    lda (ptr2),y                    ; Check if there are literals supplied for this array
    bne :+
    iny
    lda (ptr2),y
    beq DN                          ; No literals. Skip the rest of initialization.
:   lda ptr2                        ; Copy ptr2 to ptr3
    sta ptr3
    lda ptr2+1
    sta ptr3+1
    ldy #ARRAYDECL::literals        ; Pointer to literals in ptr2
    lda (ptr3),y
    sta ptr2
    iny
    lda (ptr3),y
    sta ptr2+1
    ldy #ARRAYDECL::numLiterals     ; Put number of literals on CPU stack
    lda (ptr3),y
    pha
    iny
    lda (ptr3),y
    pha
    ldy #ARRAYDECL::elemType        ; Load literal element type
    lda (ptr3),y
    tay
    pla                             ; Pop number of literals off CPU stack
    tax
    pla
    jmp copyArrayLiteral
DN: rts
.endproc

.proc initArrayFiles
    ; Loop through the elements
L1: lda ndxElems
    cmp numElems
    bne L2
    lda ndxElems+1
    cmp numElems+1
    beq DN
L2: ldy #3
    lda #0
:   sta (ptr1),y
    dey
    bpl :-
    lda ptr1
    clc
    adc #4
    sta ptr1
    lda ptr1+1
    adc #0
    sta ptr1+1
    inc ndxElems
    bne L1
    inc ndxElems+1
    jmp L1
DN: rts
.endproc

.proc initArrayStrings
    ; Store the number of literals
    ldy #ARRAYDECL::numLiterals
    lda (ptr2),y
    sta numLiterals
    iny
    lda (ptr2),y
    sta numLiterals+1
    ; Store the pointer to the literals
    ldy #ARRAYDECL::literals
    lda (ptr2),y
    sta ptr4
    iny
    lda (ptr2),y
    sta ptr4+1
    ; Loop for each element
L1: lda numLiterals                 ; If numLiterals is zero,
    ora numLiterals+1               ; then this element has no literal initializer.
    beq NL                          ; Branch if no literal (create empty string)
    ; Allocate a new string from the literal
    jsr makeStringFromLiteral
    dec numLiterals                 ; Decrement numLiterals
    bpl LZ
    dec numLiterals+1
    jmp LZ
NL: jsr makeEmptyString
LZ: lda ptr1                        ; Add 2 to ptr1
    clc
    adc #2
    sta ptr1
    lda ptr1+1
    adc #0
    sta ptr1+1
    inc ndxElems                    ; Increment ndxElems
    bne :+
    inc ndxElems+1
:   lda ndxElems
    cmp numElems                    ; If numElems != ndxElems
    bne L1                          ; branch if not equal
    lda ndxElems+1
    cmp numElems+1
    bne L1
    rts
.endproc

; This routine preserves local variables for initArrayDeclaration

.proc saveArrayLocals
    lda numElems
    ldx numElems+1
    jsr pushax
    lda ndxElems
    ldx ndxElems+1
    jsr pushax
    lda ptr1
    ldx ptr1+1
    jsr pushax
    lda ptr3
    ldx ptr3+1
    jsr pushax
    lda ptr2
    ldx ptr2+1
    jsr pushax
    lda ptr4
    ldx ptr4+1
    jsr pushax
    rts
.endproc

; This routine restores local variables for initArrayDeclaration

.proc restoreArrayLocals
    jsr popax
    sta ptr4
    stx ptr4+1
    jsr popax
    sta ptr2
    stx ptr2+1
    jsr popax
    sta ptr3
    stx ptr3+1
    jsr popax
    sta ptr1
    stx ptr1+1
    jsr popax
    sta ndxElems
    stx ndxElems+1
    jsr popax
    sta numElems
    stx numElems+1
    rts
.endproc

; This routine allocates an empty string and stores in the array heap (ptr1)

.proc makeEmptyString
    jsr saveArrayLocals             ; Preserve the ptr1 and ptr2 for the call to heapAlloc
    lda #1                          ; Allocate a 1-byte buffer for the empty string
    ldx #0
    jsr heapAlloc
    sta ptr3                        ; Store the string buffer pointer in ptr3
    stx ptr3+1
    jsr restoreArrayLocals          ; Restore ptr1 and ptr2 after the call to heapAlloc
    lda ptr3                        ; Copy the new string buffer to the array heap
    ldy #0
    sta (ptr1),y                    ; Also store it in the array heap (ptr1)
    iny
    lda ptr3+1
    sta (ptr1),y                    ; Store the high byte of the string buffer pointer
    lda #0
    tay
    sta (ptr3),y                    ; Store 0 (length) in new string buffer
    rts
.endproc

; This routine allocates a string from a null-terminated literal (ptr4)

.proc makeStringFromLiteral
    jsr saveArrayLocals
    lda ptr4
    ldx ptr4+1
    ldy #TYPE_STRING_LITERAL
    jsr convertString
    pha
    txa
    pha
    jsr restoreArrayLocals
    ldy #1
    pla
    sta (ptr1),y
    dey
    pla
    sta (ptr1),y
    ldy #0
L1: lda (ptr4),y
    pha
    inc ptr4
    bne L2
    inc ptr4+1
L2: pla
    bne L1
    rts
.endproc

; This routine clones an array using an ARRAYDECL structure
; and leaves the cloned array address at the top of the runtime stack.
; Inputs:
;   pointer to setup data (passed in A/X)
;   pointer to source array heap (top of stack)
;   pointer to target array heap (under source on stack)
; Locals:
;   number of array elements
;   element index for loop
;   pointer to source heap (ptr1)
;   pointer to target heap (ptr2)
;   pointer to setup data (ptr3)

.proc cloneArrayDeclaration
    sta ptr3                        ; Store setup data ptr
    stx ptr3+1
    jsr popeax
    sta ptr1                        ; Store source heap ptr
    stx ptr1+1
    jsr popeax
    sta ptr2                        ; Store target heap ptr
    stx ptr2+1
    ; jsr pusheax                     ; Keep the target address on the stack for the caller
    ; Calculate number of array elements.
    ; getArrayLength destroys ptr1, but it uses it for the heap
    ; pointer so it's okay since this code is doing the same.
    lda ptr1
    ldx ptr1+1
    jsr getArrayLength
    sta numElems
    stx numElems+1
    ; Clear ndxElems
    lda #0
    sta ndxElems
    sta ndxElems+1
    ; Copy the array header information
    ldy #5
:   lda (ptr1),y
    sta (ptr2),y
    dey
    bpl :-
    ; Move ptr1 past array header
    lda ptr1
    clc
    adc #6
    sta ptr1
    lda ptr1+1
    adc #0
    sta ptr1+1
    ; Move ptr2 past array header
    lda ptr2
    clc
    adc #6
    sta ptr2
    lda ptr2+1
    adc #0
    sta ptr2+1
    ; Check the element type
    ldy #ARRAYDECL::elemType
    lda (ptr3),y
    ; Are they strings?
    cmp #ARRAYDECL_STRING
    bne :+
    jmp cloneArrayStrings
    ; Are they records?
:   cmp #ARRAYDECL_RECORD
    bne :+
    jmp cloneArrayRecords
    ; Are they files?
:   cmp #ARRAYDECL_FILE
    bne :+
    jmp cloneArrayFiles
    ; Are they arrays?
:   cmp #ARRAYDECL_ARRAY
    bne :+
    jmp cloneArrayOfArrays
:   ; Elements are scalar. Copy the array elements in bulk.
    ldy #ARRAYDECL::elemSize
    lda (ptr3),y                        ; Copy element size to intOp1
    sta intOp1
    iny
    lda (ptr3),y
    sta intOp1+1
    ; Copy numElems to intOp2
    lda numElems
    sta intOp2
    lda numElems+1
    sta intOp2+1
    jsr multInt16
    ; Swap ptr1 and ptr2
    lda ptr1
    sta ptr4
    lda ptr1+1
    sta ptr4+1
    lda ptr2
    sta ptr1
    lda ptr2+1
    sta ptr1+1
    sta ptr2+1
    lda ptr4
    sta ptr2
    lda ptr4+1
    sta ptr2+1
    lda intOp1
    ldx intOp1+1
    jmp memcopy
.endproc

.proc cloneArrayOfArrays
    ; Loop through the elements
L1: lda ndxElems
    cmp numElems
    bne L2
    lda ndxElems+1
    cmp numElems+1
    beq DN
L2: jsr saveArrayLocals
    lda ptr1
    ldx ptr1+1
    jsr pusheax                         ; Put source address onto the stack
    ; Put the array declaration into ptr3
    lda ptr3
    sta ptr4
    lda ptr3+1
    sta ptr4+1
    ldy #6
    lda (ptr4),y
    sta ptr3
    iny
    lda (ptr4),y
    sta ptr3+1
    jsr cloneArrayDeclaration
    jsr restoreArrayLocals
    ; Look up the size of the array and put in tmp1/tmp2
    ldy #4
    lda (ptr3),y
    sta tmp1
    iny
    lda (ptr3),y
    sta tmp2
    ; Advance ptr1 by the size of the array
    lda ptr1
    clc
    adc tmp1
    sta ptr1
    lda ptr1+1
    adc tmp2
    sta ptr1+1
    ; Advance ptr2 by the size of the array
    lda ptr2
    clc
    adc tmp1
    sta ptr2
    lda ptr2+1
    adc tmp2
    sta ptr2+1
    inc ndxElems
    bne L1
    inc ndxElems+1
    jmp L1
DN: rts
.endproc

.proc cloneArrayStrings
    ; Loop through the elements
L1: lda ndxElems
    cmp numElems
    bne L2
    lda ndxElems+1
    cmp numElems+1
    beq DN
L2: jsr saveArrayLocals
    ldy #1
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    ldy #TYPE_STRING_VAR
    jsr convertString
    pha
    txa
    pha
    jsr restoreArrayLocals
    ldy #1
    pla
    sta (ptr2),y
    dey
    pla
    sta (ptr2),y 
    lda ptr1
    clc
    adc #2
    sta ptr1
    lda ptr1+1
    adc #0
    sta ptr1+1
    lda ptr2
    clc
    adc #2
    sta ptr2
    lda ptr2+1
    adc #0
    sta ptr2+1
    inc ndxElems
    bne L1
    inc ndxElems+1
    jmp L1
DN: rts
.endproc

.proc cloneArrayRecords
    ; Loop through the elements
L1: lda ndxElems
    cmp numElems
    bne L2
    lda ndxElems+1
    cmp numElems+1
    beq DN
L2: jsr saveArrayLocals
    lda ptr2                        ; Push target heap address onto stack
    ldx ptr2+1
    jsr pusheax
    lda ptr1                        ; Push source heap address onto stack
    ldx ptr1+1
    jsr pusheax
    ; Load the record declaration pointer into A/X
    ldy #ARRAYDECL::elemDecl+1
    lda (ptr3),y
    tax
    dey
    lda (ptr3),y
    jsr cloneRecordDeclaration
    jsr restoreArrayLocals
    ; Look up the size of the record and put in tmp1/tmp2
    ldy #ARRAYDECL::elemSize
    lda (ptr3),y
    sta tmp1
    iny
    lda (ptr3),y
    sta tmp2
    ; Advance ptr1 by the size of the record
    lda ptr1
    clc
    adc tmp1
    sta ptr1
    lda ptr1+1
    adc tmp2
    sta ptr1+1
    ; Advance ptr2 by the size of the record
    lda ptr2
    clc
    adc tmp1
    sta ptr2
    lda ptr2+1
    adc tmp2
    sta ptr2+1
    inc ndxElems
    bne L1
    inc ndxElems+1
    jmp L1
DN: rts
.endproc

.proc cloneArrayFiles
    ; Loop through the elements
L1: lda ndxElems
    cmp numElems
    bne L2
    lda ndxElems+1
    cmp numElems+1
    beq DN
L2: ldy #2
:   lda (ptr1),y
    sta (ptr2),y
    dey
    bpl :-
    ldy #3
    lda (ptr1),y
    ora #1                          ; Flip bit 0 to indicate this is a cloned file handle
    sta (ptr2),y
    lda ptr1
    clc
    adc #4
    sta ptr1
    lda ptr1+1
    adc #0
    sta ptr1+1
    lda ptr2
    clc
    adc #4
    sta ptr2
    lda ptr2+1
    adc #0
    sta ptr2+1
    inc ndxElems
    bne L1
    inc ndxElems+1
    jmp L1
DN: rts
.endproc

; This routine frees an array using an ARRAYDECL structure
; Inputs:
;   pointer to setup data (passed in A/X)
;   pointer to array heap (top of stack)
; Locals:
;   number of array elements
;   element index for loop
;   pointer to array heap (ptr1)
;   pointer to setup data (ptr2)

.proc freeArrayDeclaration
    sta ptr2                        ; Store setup data ptr
    stx ptr2+1
    jsr popeax
    sta ptr1                        ; Store heap ptr
    stx ptr1+1
    ; Calculate number of array elements.
    ; getArrayLength destroys ptr1, but it uses it for the heap
    ; pointer so it's okay since this code is doing the same.
    lda ptr1
    ldx ptr1+1
    jsr getArrayLength
    sta numElems
    stx numElems+1
    ; Clear ndxElems
    lda #0
    sta ndxElems
    sta ndxElems+1
    ; Move ptr1 past array header
    lda ptr1
    clc
    adc #6
    sta ptr1
    lda ptr1+1
    adc #0
    sta ptr1+1
    ; Check the element type
    ldy #ARRAYDECL::elemType
    lda (ptr2),y
    ; Are they strings?
    cmp #ARRAYDECL_STRING
    bne :+
    jmp freeArrayStrings
    ; Are they records?
:   cmp #ARRAYDECL_RECORD
    bne :+
    jmp freeArrayRecords
    ; Are they files?
:   cmp #ARRAYDECL_FILE
    bne :+
    jmp freeArrayFiles
    ; Are they arrays?
:   cmp #ARRAYDECL_ARRAY
    bne :+
    jmp freeArrayOfArrays
:   ; Elements are scalar. Nothing else to do.
    rts
.endproc

.proc freeArrayStrings
    ; Loop through the elements
L1: lda ndxElems
    cmp numElems
    bne L2
    lda ndxElems+1
    cmp numElems+1
    beq DN
L2: jsr saveArrayLocals
    ldy #1
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    jsr heapFree
    jsr restoreArrayLocals
    ; Move ptr1 to the next element
    lda ptr1
    clc
    adc #2
    sta ptr1
    lda ptr1+1
    adc #0
    sta ptr1+1
    ; Increment ndxElems
    inc ndxElems
    bne L1
    inc ndxElems+1
    jmp L1
DN: rts
.endproc

.proc freeArrayRecords
    ; Loop through the elements
L1: lda ndxElems
    cmp numElems
    bne L2
    lda ndxElems+1
    cmp numElems+1
    beq DN
L2: jsr saveArrayLocals
    ; Push the heap pointer onto the stack
    lda ptr1
    ldx ptr1+1
    jsr pusheax
    ; Load the pointer to the record declaration into A/X
    ; lda ptr2
    ; sta ptr4
    ; lda ptr2+1
    ; sta ptr4+1
    ldy #ARRAYDECL::elemDecl+1
    lda (ptr2),y
    tax
    dey
    lda (ptr2),y
    jsr freeRecordDeclaration
    jsr restoreArrayLocals
    ; Advance ptr1 by the size of the record
    ldy #ARRAYDECL::elemSize
    lda ptr1
    clc
    adc (ptr2),y
    sta ptr1
    iny
    lda ptr1+1
    adc (ptr2),y
    sta ptr1+1
    ; Increment ndxElems
    inc ndxElems
    bne L1
    inc ndxElems+1
    jmp L1
DN: rts
.endproc

.proc freeArrayOfArrays
    ; Loop through the elements
L1: lda ndxElems
    cmp numElems
    bne L2
    lda ndxElems+1
    cmp numElems+1
    beq DN
L2: jsr saveArrayLocals
    ; Push the heap pointer onto the stack
    lda ptr1
    ldx ptr1+1
    jsr pushax
    ; Load the pointer to the array declaration into A/X
    lda ptr2
    sta ptr4
    lda ptr2+1
    sta ptr4+1
    ldy #ARRAYDECL::elemDecl+1
    lda (ptr4),y
    tax
    dey
    lda (ptr4),y
    jsr freeArrayDeclaration
    jsr restoreArrayLocals
    ; Look up the size of the element and put in tmp1/tmp2
    ldy #ARRAYDECL::elemSize
    lda (ptr3),y
    sta tmp1
    iny
    lda (ptr3),y
    sta tmp2
    ; Advance ptr1 by the size of the record
    lda ptr1
    clc
    adc tmp1
    sta ptr1
    lda ptr1+1
    adc tmp2
    sta ptr1+1
    ; Increment ndxElems
    inc ndxElems
    bne L1
    inc ndxElems+1
    jmp L1
DN: rts
.endproc

.proc freeArrayFiles
    ; Loop through the elements
L1: lda ndxElems
    cmp numElems
    bne L2
    lda ndxElems+1
    cmp numElems+1
    beq DN
L2: ldy #3                          ; Look at bit 0 - if 1 then this is a cloned file handle.
    lda (ptr1),y
    and #1
    bne :+                          ; Branch if a cloned file handle
    ; Close the file
    jsr saveArrayLocals
    ldy #1
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    jsr fileClose
    jsr restoreArrayLocals
    ; Move ptr1 to the next file in the array
:   lda ptr1
    clc
    adc #4
    sta ptr1
    lda ptr1+1
    adc #0
    sta ptr1+1
    ; Increment ndxElems
    inc ndxElems
    bne L1
    inc ndxElems+1
    jmp L1
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
;   A/X - address of array heap
.proc readCharArrayFromInput
    sta ptr2
    stx ptr2 + 1
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

; This routine calculates an array's size based on the declaration block
; passed in A/X
.proc getArraySize
    sta ptr3                        ; Put the declaration block ptr in ptr3
    stx ptr3+1
    sta ptr2                        ; Also put it in ptr2 for some math
    stx ptr2+1
    ; Move ptr2 to point to the min/max element indexes in the declaration block
    lda ptr2
    clc
    adc #ARRAYDECL::minIndex
    sta ptr2
    lda ptr2+1
    adc #0
    sta ptr2+1
    ; Get the array length (number of elements)
    lda ptr2
    ldx ptr2+1
    jsr getArrayLength
    sta intOp1                      ; Store the array length in intOp1
    stx intOp1+1
    ldy #ARRAYDECL::elemSize
    lda (ptr3),y
    sta intOp2                      ; Store the element size in intOp2
    iny
    lda (ptr3),y
    sta intOp2+1
    jsr multInt16                   ; Multiply array length by element size
    lda #6
    sta intOp2
    lda #0
    sta intOp2+1
    jsr addInt16                    ; Add 6 for array header
    lda intOp1                      ; Return array size in A/X
    ldx intOp1+1
    rts
.endproc
