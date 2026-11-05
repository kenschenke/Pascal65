;
; dynarray.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Dynamic array routines (SetLength)
;
; A dynamic array is one heap block: the 6-byte array header (see array.s)
; followed by the elements. Its low index is always 0. Resizing it replaces
; the whole block, so the array variable's slot is updated with the new
; block's address.

.include "runtime.inc"
.include "error.inc"

.export setArrayLength

.import popeax, pusheax, popax, pushax, heapAlloc, heapFree, memcopy
.import runtimeError, getArrayLength
.import initArrayDeclaration, initRecordDeclaration
.import freeArrayStrings, freeArrayRecords, freeArrayFiles
.import numElems, ndxElems

ARRAYDECL_RECORD = 2
ARRAYDECL_STRING = 3
ARRAYDECL_FILE = 4
ARRAYDECL_ARRAY = 5

; Offsets in an array declaration block (see decl.s)
AD_MININDEX = 2
AD_MAXINDEX = 4
AD_ELEMSIZE = 6
AD_ELEMDECL = 12
AD_ELEMTYPE = 14

; Offset of the field list in a record declaration block
RD_STARTOFLIST = 4

; Size of a record field list entry: type, declaration, offset
RD_ENTRYSIZE = 5

.bss

declPtr: .res 2             ; array declaration block
slotPtr: .res 2             ; the array variable's slot
newLen: .res 2              ; new number of elements
oldLen: .res 2              ; old number of elements
oldHeap: .res 2             ; old heap block
newHeap: .res 2             ; new heap block
elemSize: .res 2            ; size of each element
elemPtr: .res 2             ; current element in the new block
elemNdx: .res 2             ; index of the current element

.code

; This routine sets the length of a dynamic array (SetLength).
; Inputs:
;   A/X - pointer to the array's declaration block
;   runtime stack (top) - the new length (LongInt)
;   runtime stack (under the length) - address of the array's slot
; The new length must be 0 to 32767.
.proc setArrayLength
    sta declPtr
    stx declPtr+1
    ; Pop the new length. Anything outside 0..32767 is an error.
    jsr popeax
    sta newLen
    stx newLen+1
    lda sreg
    ora sreg+1
    bne RE
    lda newLen+1
    bmi RE
    ; Pop the address of the array's slot and load the old heap block
    jsr popeax
    sta slotPtr
    stx slotPtr+1
    sta ptr1
    stx ptr1+1
    ldy #0
    lda (ptr1),y
    sta oldHeap
    iny
    lda (ptr1),y
    sta oldHeap+1
    ; The element size and the old length come from the header
    lda oldHeap
    sta ptr1
    lda oldHeap+1
    sta ptr1+1
    ldy #4
    lda (ptr1),y
    sta elemSize
    iny
    lda (ptr1),y
    sta elemSize+1
    lda oldHeap
    ldx oldHeap+1
    jsr getArrayLength
    sta oldLen
    stx oldLen+1
    ; The new block is 6 + newLen * elemSize bytes. That can be too big
    ; for 16 bits even though the length is in range.
    lda newLen
    ldx newLen+1
    jsr mulElemSize
    bcs OM
    clc
    adc #6
    bcc :+
    inx
    beq OM
:   cmp #$ff                    ; $FFFF is a special call to heapAlloc
    bne :+
    cpx #$ff
    beq OM
:   jsr heapAlloc
    sta newHeap
    stx newHeap+1
    jmp copyElements
RE: lda #rteValueOutOfRange
    jmp runtimeError
OM: lda #rteOutOfMemory
    jmp runtimeError
.endproc

; This routine is the second part of setArrayLength. It copies the
; header and the elements both blocks have, then sets the new high index.
.proc copyElements
    ; elemNdx = the number of elements copied, min(oldLen, newLen).
    ; Both lengths are 0..32767.
    lda newLen
    cmp oldLen
    lda newLen+1
    sbc oldLen+1
    bcc :+                      ; Branch if newLen < oldLen
    lda oldLen
    ldx oldLen+1
    jmp L1
:   lda newLen
    ldx newLen+1
L1: sta elemNdx
    stx elemNdx+1
    ; Bytes to copy: 6 + elemNdx * elemSize. This fits in both blocks.
    jsr mulElemSize
    clc
    adc #6
    bcc :+
    inx
:   sta elemPtr                 ; elemPtr = new block + bytes copied
    stx elemPtr+1
    pha
    lda newHeap
    sta ptr1
    lda newHeap+1
    sta ptr1+1
    lda oldHeap
    sta ptr2
    lda oldHeap+1
    sta ptr2+1
    pla
    jsr memcopy
    lda elemPtr
    clc
    adc newHeap
    sta elemPtr
    lda elemPtr+1
    adc newHeap+1
    sta elemPtr+1
    ; The new high index is low + newLen - 1 (-1 for an empty array)
    lda newHeap
    sta ptr1
    lda newHeap+1
    sta ptr1+1
    ldy #0
    lda (ptr1),y
    clc
    adc newLen
    sta tmp1
    iny
    lda (ptr1),y
    adc newLen+1
    tax
    lda tmp1
    sec
    sbc #1
    ldy #2
    sta (ptr1),y
    txa
    sbc #0
    iny
    sta (ptr1),y
    jmp initElements
.endproc

; This routine is the third part of setArrayLength. It zeros the elements
; past the copied ones and initializes new strings and records.
.proc initElements
    ; Zero (newLen - elemNdx) * elemSize bytes at elemPtr. That is zero
    ; when the array did not grow.
    lda newLen
    sec
    sbc elemNdx
    pha
    lda newLen+1
    sbc elemNdx+1
    tax
    pla
    jsr mulElemSize
    sta tmp1
    stx tmp2
    lda elemPtr
    sta ptr1
    lda elemPtr+1
    sta ptr1+1
    ldy #0
L1: lda tmp1
    ora tmp2
    beq L2
    tya
    sta (ptr1),y
    inc ptr1
    bne :+
    inc ptr1+1
:   lda tmp1
    bne :+
    dec tmp2
:   dec tmp1
    jmp L1
    ; Strings and records need more than zeros
L2: lda declPtr
    sta ptr1
    lda declPtr+1
    sta ptr1+1
    ldy #AD_ELEMTYPE
    lda (ptr1),y
    cmp #ARRAYDECL_STRING
    bne :+
    jsr initNewStrings
    jmp freeDropped
:   cmp #ARRAYDECL_RECORD
    bne :+
    jsr initNewRecords
:   jmp freeDropped
.endproc

; This routine is the last part of setArrayLength. It frees the elements
; that were dropped from the old block, frees the old block and stores
; the new block's address in the array's slot.
.proc freeDropped
    ; Were elements dropped (newLen < oldLen)?
    lda newLen
    cmp oldLen
    lda newLen+1
    sbc oldLen+1
    bcs FB                      ; Branch if newLen >= oldLen
    ; numElems = oldLen - newLen, ndxElems = 0
    lda oldLen
    sec
    sbc newLen
    sta numElems
    lda oldLen+1
    sbc newLen+1
    sta numElems+1
    lda #0
    sta ndxElems
    sta ndxElems+1
    ; ptr1 = the first dropped element: old block + 6 + newLen * elemSize
    lda newLen
    ldx newLen+1
    jsr mulElemSize
    clc
    adc #6
    bcc :+
    inx
:   clc
    adc oldHeap
    sta ptr1
    txa
    adc oldHeap+1
    sta ptr1+1
    ; ptr2 = the declaration block
    lda declPtr
    sta ptr2
    lda declPtr+1
    sta ptr2+1
    ldy #AD_ELEMTYPE
    lda (ptr2),y
    cmp #ARRAYDECL_STRING
    bne :+
    jsr freeArrayStrings
    jmp FB
:   cmp #ARRAYDECL_RECORD
    bne :+
    jsr freeArrayRecords
    jmp FB
:   cmp #ARRAYDECL_FILE
    bne FB
    jsr freeArrayFiles
    ; Free the old block
FB: lda oldHeap
    ldx oldHeap+1
    jsr heapFree
    ; Store the new block in the array's slot
    lda slotPtr
    sta ptr1
    lda slotPtr+1
    sta ptr1+1
    ldy #0
    lda newHeap
    sta (ptr1),y
    iny
    lda newHeap+1
    sta (ptr1),y
    rts
.endproc

; This routine gives each new string element an empty string.
; elemPtr is the first new element and elemNdx is its index.
.proc initNewStrings
L1: lda elemNdx
    cmp newLen
    bne L2
    lda elemNdx+1
    cmp newLen+1
    beq DN
L2: lda #1
    ldx #0
    jsr heapAlloc
    sta ptr1
    stx ptr1+1
    ldy #0
    tya
    sta (ptr1),y                ; String length 0
    lda elemPtr
    sta ptr2
    lda elemPtr+1
    sta ptr2+1
    lda ptr1
    sta (ptr2),y
    iny
    lda ptr1+1
    sta (ptr2),y
    lda elemPtr
    clc
    adc #2
    sta elemPtr
    bcc :+
    inc elemPtr+1
:   inc elemNdx
    bne L1
    inc elemNdx+1
    jmp L1
DN: rts
.endproc

; This routine initializes each new record element.
; elemPtr is the first new element and elemNdx is its index.
;
; The record's declaration block describes the array's first element:
; its heap offset, and those of the arrays and records in it, are offsets
; from the start of the array's original heap block. Element i is
; initialized by adding them to a base address of
; (element i's address) - (the record block's heap offset).
.proc initNewRecords
L1: lda elemNdx
    cmp newLen
    bne L2
    lda elemNdx+1
    cmp newLen+1
    beq DN
L2: lda declPtr
    sta ptr1
    lda declPtr+1
    sta ptr1+1
    ldy #AD_ELEMDECL
    lda (ptr1),y
    sta ptr2
    iny
    lda (ptr1),y
    sta ptr2+1
    ldy #0
    lda elemPtr
    sec
    sbc (ptr2),y
    pha
    iny
    lda elemPtr+1
    sbc (ptr2),y
    tax
    pla
    ldy #0
    sty sreg
    sty sreg+1
    jsr pusheax                 ; base address
    lda ptr2
    ldx ptr2+1
    jsr initRecordTree
    lda elemPtr
    clc
    adc elemSize
    sta elemPtr
    lda elemPtr+1
    adc elemSize+1
    sta elemPtr+1
    inc elemNdx
    bne L1
    inc elemNdx+1
    jmp L1
DN: rts
.endproc

; This routine initializes a record and what is in it: strings and files,
; plus arrays and records, along with their own contents. For a static
; array, the compiler writes an instruction for each of these.
; Inputs:
;   A/X - record declaration block
;   runtime stack - base address the heap offsets are added to (popped)
.proc initRecordTree
    sta tmp1
    pha
    txa
    pha
    lda tmp1
    jsr initRecordDeclaration   ; Strings and files. Leaves the base.
    pla
    tax
    pla
    clc
    adc #RD_STARTOFLIST
    bcc :+
    inx
:   jsr pushax                  ; Stack: base (4), list entry (2)
    ; Walk through the list for arrays and records
L1: ldy #0
    lda (sp),y
    sta ptr2
    iny
    lda (sp),y
    sta ptr2+1
    dey
    lda (ptr2),y                ; Entry type
    beq DN                      ; Zero ends the list
    cmp #ARRAYDECL_ARRAY
    beq L2
    cmp #ARRAYDECL_RECORD
    bne NX
    ; Push a copy of the base
L2: ldy #5
    lda (sp),y
    sta sreg+1
    dey
    lda (sp),y
    sta sreg
    dey
    lda (sp),y
    tax
    dey
    lda (sp),y
    jsr pusheax
    ; Load the entry's declaration block into A/X (low byte in tmp1)
    ldy #1
    lda (ptr2),y
    sta tmp1
    iny
    lda (ptr2),y
    tax
    ldy #0
    lda (ptr2),y
    cmp #ARRAYDECL_ARRAY
    bne :+
    lda tmp1
    jsr initArrayTree
    jmp NX
:   lda tmp1
    jsr initRecordTree
    ; Move to the next entry
NX: ldy #0
    lda (sp),y
    clc
    adc #RD_ENTRYSIZE
    sta (sp),y
    iny
    lda (sp),y
    adc #0
    sta (sp),y
    jmp L1
DN: jsr popax                   ; list entry
    jmp popeax                  ; base
.endproc

; This routine initializes an array and what is in it. Its elements are
; described by the declaration block for the first one. Element k is
; initialized with a base address of base + k * elemSize.
; Inputs:
;   A/X - array declaration block
;   runtime stack - base address the heap offsets are added to (popped)
.proc initArrayTree
    sta tmp1
    pha
    txa
    pha
    lda tmp1
    jsr initArrayDeclaration    ; Header, strings, files, literals.
    pla                         ; It leaves the base on the stack.
    tax
    pla
    sta ptr2
    stx ptr2+1
    ldy #AD_ELEMTYPE
    lda (ptr2),y
    cmp #ARRAYDECL_ARRAY
    beq :+
    cmp #ARRAYDECL_RECORD
    beq :+
    jmp popeax                  ; Nothing more to do. Drop the base.
:   lda ptr2
    ldx ptr2+1
    jsr pushax                  ; Stack: base (4), decl (2)
    lda #0
    tax
    jsr pushax                  ; Stack: base (4), decl (2), k (2)
    ; Loop while k < number of elements (high - low + 1)
L1: ldy #2
    lda (sp),y
    sta ptr2
    iny
    lda (sp),y
    sta ptr2+1
    ldy #AD_MAXINDEX
    lda (ptr2),y
    sec
    ldy #AD_MININDEX
    sbc (ptr2),y
    sta tmp1
    ldy #AD_MAXINDEX+1
    lda (ptr2),y
    ldy #AD_MININDEX+1
    sbc (ptr2),y
    sta tmp2
    inc tmp1
    bne :+
    inc tmp2
:   ldy #0
    lda (sp),y
    cmp tmp1
    bne L2
    iny
    lda (sp),y
    cmp tmp2
    beq DN
    ; Push base + k * elemSize
L2: ldy #AD_ELEMSIZE
    lda (ptr2),y
    sta tmp1
    iny
    lda (ptr2),y
    sta tmp2
    ldy #0
    lda (sp),y
    pha
    iny
    lda (sp),y
    tax
    pla
    jsr mulBySize
    ldy #4
    clc
    adc (sp),y
    pha
    txa
    iny
    adc (sp),y
    tax
    pla
    ldy #0
    sty sreg
    sty sreg+1
    jsr pusheax                 ; Stack: base, decl, k, element base
    ; Load the element declaration block (decl is now at sp+6)
    ldy #6
    lda (sp),y
    sta ptr2
    iny
    lda (sp),y
    sta ptr2+1
    ldy #AD_ELEMDECL
    lda (ptr2),y
    sta tmp1
    iny
    lda (ptr2),y
    tax
    ldy #AD_ELEMTYPE
    lda (ptr2),y
    cmp #ARRAYDECL_ARRAY
    bne :+
    lda tmp1
    jsr initArrayTree
    jmp NX
:   lda tmp1
    jsr initRecordTree
    ; k = k + 1
NX: ldy #0
    lda (sp),y
    clc
    adc #1
    sta (sp),y
    iny
    lda (sp),y
    adc #0
    sta (sp),y
    jmp L1
DN: jsr popax                   ; k
    jsr popax                   ; decl
    jmp popeax                  ; base
.endproc

; This routine multiplies A/X by elemSize.
.proc mulElemSize
    pha
    lda elemSize
    sta tmp1
    lda elemSize+1
    sta tmp2
    pla
    ; Fall through
.endproc

; This routine multiplies A/X by tmp1/tmp2 (unsigned). The product is
; returned in A/X. Carry is set if it does not fit in 16 bits.
; intOp1, tmp1, tmp2 and ptr4 are destroyed.
.proc mulBySize
    sta intOp1
    stx intOp1+1
    lda #0
    sta ptr4
    sta ptr4+1
    ldx #16
L1: asl ptr4                    ; product = product * 2
    rol ptr4+1
    bcs DN
    asl tmp1                    ; next bit of the multiplier, high first
    rol tmp2
    bcc L2
    lda ptr4                    ; product = product + A/X
    clc
    adc intOp1
    sta ptr4
    lda ptr4+1
    adc intOp1+1
    sta ptr4+1
    bcs DN
L2: dex
    bne L1
    clc
DN: lda ptr4
    ldx ptr4+1
    rts
.endproc
