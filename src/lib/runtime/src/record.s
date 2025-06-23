;
; record.s
; Ken Schenke (kenschenke@gmail.com)
;
; Record routines
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

.include "runtime.inc"
.include "types.inc"

.export calcRecordOffset
.export initRecordDeclaration, freeRecordDeclaration, cloneRecordDeclaration
.export getRecordSize

RECDECL_RECORD = 2
RECDECL_STRING = 3
RECDECL_FILE = 4
RECDECL_ARRAY = 5

.import pushax, pusheax, popeax, popax, heapAlloc, heapFree, fileClose
.import freeArrayDeclaration, memcopy, cloneArrayDeclaration, convertString

.struct RECDECL
    heapOffset .word                    ; Size of record
    recSize .word
    startOfList .byte
.endstruct

; This routine calculates the address of a field in a record's
; heap buffer. It expects the field offset to be pushed onto the
; runtime stack and the record heap address to be passed in A/X.
;
; The address in the record's heap is returned in A/X.
.proc calcRecordOffset
    sta ptr1
    stx ptr1 + 1
    jsr popax
    sta tmp1
    stx tmp2
    lda ptr1
    clc
    adc tmp1
    pha
    lda ptr1 + 1
    adc tmp2
    tax
    pla
    rts
.endproc

; This routine initializes a record using a setup block
; Inputs:
;   pointer to setup data (passed in A/X)
;   pointer to heap memory (top of stack, preserved and left at top of stack)
; Locals:
;   pointer to start of record (ptr1)
;   pointer to setup data (ptr2)

.proc initRecordDeclaration
    sta ptr2                    ; Store pointer to setup data
    stx ptr2+1
    jsr popeax                  ; Pop pointer to heap memory and store
    sta ptr1
    stx ptr1+1
    jsr pusheax                 ; Keep the heap pointer on the stack
    ; Add heap offset to the pointer
    ldy #RECDECL::heapOffset
    lda ptr1
    clc
    adc (ptr2),y
    sta ptr1
    iny
    lda ptr1+1
    adc (ptr2),y
    sta ptr1+1
    ; Move ptr2 to the start of the list
    lda ptr2
    clc
    adc #RECDECL::startOfList
    sta ptr2
    lda ptr2+1
    adc #0
    sta ptr2+1
    ; Walk through the list of record members that need intializing
L1: ldy #0
    lda (ptr2),y
    ; Is this the end of the list?
    beq DN                  ; Branch to DN if end of list
    ; Move ptr2 past the record member type
    inc ptr2
    bne :+
    inc ptr2+1
    ; Is it a string?
:   cmp #RECDECL_STRING
    bne :+
    jsr saveRecordLocals    ; Save local variables
    jsr initRecordString
    jsr restoreRecordLocals
    jmp NX
    ; Is it a record?
; :   cmp #RECDECL_RECORD
;     bne :+
;     jsr saveRecordLocals    ; Save local variables
;     jsr initRecordSubRecord
;     jsr restoreRecordLocals
;     jmp NX
    ; Is it a file?
:   cmp #RECDECL_FILE
    bne NX
    jsr saveRecordLocals    ; Save local variables
    jsr initRecordFile
    jsr restoreRecordLocals
    ; Move ptr2 forward by 4 bytes, to the next item in the list
NX: lda ptr2
    clc
    adc #4
    sta ptr2
    lda ptr2+1
    adc #0
    sta ptr2+1
    jmp L1
DN: rts
.endproc

.proc saveRecordLocals
    lda ptr1
    ldx ptr1+1
    jsr pushax
    lda ptr2
    ldx ptr2+1
    jsr pushax
    lda ptr3
    ldx ptr3+1
    jsr pushax
    rts
.endproc

.proc restoreRecordLocals
    jsr popax
    sta ptr3
    stx ptr3+1
    jsr popax
    sta ptr2
    stx ptr2+1
    jsr popax
    sta ptr1
    stx ptr1+1
    rts
.endproc

; This routine adds the record field offset to ptr1
.proc addFieldOffset
    ldy #2
    lda ptr1
    clc
    adc (ptr2),y
    sta ptr1
    iny
    lda ptr1+1
    adc (ptr2),y
    sta ptr1+1
    rts
.endproc

; This routine allocates an empty string and stores it in the record
; heap (ptr1) at the offset in ptr2
.proc initRecordString
    jsr addFieldOffset               ; Add the field offset to ptr1
    jsr saveRecordLocals            ; Preserve ptr1 and ptr2
    lda #1
    ldx #0
    jsr heapAlloc                   ; Allocate the string
    pha                             ; Put the string pointer on the stack
    txa
    pha 
    jsr restoreRecordLocals         ; Restore ptr1 and ptr2
    ldy #1
    pla                             ; Pop the string pointer back off the stack
    sta (ptr1),y                    ; Store the pointer in the record heap
    sta ptr4+1                      ; Store it in ptr4 as well
    dey
    pla
    sta (ptr1),y
    sta ptr4
    ldy #0
    tya
    sta (ptr4),y                    ; Store a zero in the string length
    rts
.endproc

; This routine initializes a new file handle (four 0's)
.proc initRecordFile
    jsr addFieldOffset               ; Add the heap offset to ptr1
    ldy #3
    lda #0
:   sta (ptr1),y
    dey
    bpl :-
    rts
.endproc

; This routine frees a record using a record declaration block
; Inputs:
;   pointer to setup data (passed in A/X)
;   pointer to record heap (top of stack)
; Locals:
;   pointer to array heap (ptr1)
;   pointer to setup data (ptr2)

.proc freeRecordDeclaration
    sta ptr2                        ; Store setup data ptr
    stx ptr2+1
    jsr popeax
    sta ptr1                        ; Store heap ptr
    stx ptr1+1
    ; Move ptr2 to the start of the list
    lda ptr2
    clc
    adc #RECDECL::startOfList
    sta ptr2
    lda ptr2+1
    adc #0
    sta ptr2+1
    ; Walk through the list of record members that need freed
L1: ldy #0
    lda (ptr2),y
    ; Is this the end of the list?
    beq DN                  ; Branch to DN if end of list
    ; Move ptr2 past the record member type
    inc ptr2
    bne :+
    inc ptr2+1
    ; Is it a string?
:   cmp #RECDECL_STRING
    bne :+
    jsr saveRecordLocals    ; Save local variables
    jsr freeRecordString
    jsr restoreRecordLocals
    jmp NX
    ; Is it a record?
:   cmp #RECDECL_RECORD
    bne :+
    jsr saveRecordLocals    ; Save local variables
    jsr freeRecordSubRecord
    jsr restoreRecordLocals
    jmp NX
    ; Is it a file?
:   cmp #RECDECL_FILE
    bne :+
    jsr saveRecordLocals    ; Save local variables
    jsr freeRecordFile
    jsr restoreRecordLocals
    jmp NX
:   cmp #RECDECL_ARRAY
    bne NX
    jsr saveRecordLocals    ; Save local variables
    jsr freeRecordArray
    jsr restoreRecordLocals
    ; Move ptr2 forward by 4 bytes, to the next item in the list
NX: lda ptr2
    clc
    adc #4
    sta ptr2
    lda ptr2+1
    adc #0
    sta ptr2+1
    jmp L1
DN: rts
.endproc

.proc freeRecordString
    ; Add field offset to heap pointer
    jsr addFieldOffset
    ; Free string storage
    ldy #1
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    jsr heapFree
    rts
.endproc

.proc freeRecordSubRecord
    ; Add field offset to heap pointer
    jsr addFieldOffset
    lda ptr1                    ; Put heap pointer on stack
    ldx ptr1+1
    jsr pusheax
    ldy #1                      ; Load declaration ptr into A/X
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    jmp freeRecordDeclaration   ; Recursive call to free sub-record
.endproc

.proc freeRecordFile
    ; Add field offset to heap pointer
    jsr addFieldOffset
    ; Is the file open?
    ldy #2
    lda (ptr1),y
    beq DN                      ; Branch if not opened
    ; Is the file handle cloned?
    iny
    lda (ptr1),y
    and #1                      ; Branch if cloned
    bne DN
    ; Close the file
    ldy #1
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    jsr fileClose
DN: rts
.endproc

.proc freeRecordArray
    ; Add field offset to heap pointer
    jsr addFieldOffset
    lda ptr1                    ; Put heap pointer on stack
    ldx ptr1+1
    jsr pusheax
    ldy #1                      ; Load declaration ptr into A/X
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    jmp freeArrayDeclaration   ; Free the array
.endproc

; This routine returns the size of the record from the declaration block
; passed in A/X
.proc getRecordSize
    sta ptr3
    stx ptr3+1
    ldy #RECDECL::recSize+1
    lda (ptr3),y
    tax
    dey
    lda (ptr3),y
    rts
.endproc

; This routine clones a record using a setup block.
; The address of the cloned record is left at the top of the runtime stack.
; Inputs:
;   pointer to setup data (passed in A/X)
;   pointer to source record heap (top of stack)
;   pointer to target record heap (under source on stack)
; Locals:
;   pointer to source heap (ptr1)
;   pointer to target heap (ptr2)
;   pointer to setup data (ptr3)

.proc cloneRecordDeclaration
    sta ptr3                        ; Store setup data ptr
    stx ptr3+1
    jsr popeax
    sta ptr1                        ; Store source heap ptr
    stx ptr1+1
    jsr popeax
    sta ptr2                        ; Target heap ptr
    stx ptr2+1
    ; jsr pusheax                     ; Leave it on the stack for the caller
    ; Start by copying the entire record
    ; Cloning strings, arrays, records, and files comes later.
    jsr saveRecordLocals
    lda ptr2                        ; Swap ptr2 and ptr1 for memcpy
    sta tmp1
    lda ptr2+1
    sta tmp2
    lda ptr1
    sta ptr2
    lda ptr1+1
    sta ptr2+1
    lda tmp1
    sta ptr1
    lda tmp2
    sta ptr1+1
    ldy #RECDECL::recSize+1         ; Load record size into A/X
    lda (ptr3),y
    tax
    dey
    lda (ptr3),y
    jsr memcopy
    jsr restoreRecordLocals
    ; Move ptr3 to the start of the list
    lda ptr3
    clc
    adc #RECDECL::startOfList
    sta ptr3
    lda ptr3+1
    adc #0
    sta ptr3+1
    ; Walk through the list of record members that need intializing
L1: ldy #0
    lda (ptr3),y
    ; Is this the end of the list?
    beq DN                  ; Branch to DN if end of list
    ; Move ptr3 past the record member type
    inc ptr3
    bne :+
    inc ptr3+1
    ; Is it an array?
:   cmp #RECDECL_ARRAY
    bne :+
    jsr saveRecordLocals    ; Save local variables
    jsr cloneRecordArray
    jsr restoreRecordLocals
    jmp NX
    ; Is it a string?
:   cmp #RECDECL_STRING
    bne :+
    jsr saveRecordLocals    ; Save local variables
    jsr cloneRecordString
    jsr restoreRecordLocals
    jmp NX
    ; Is it a record?
:   cmp #RECDECL_RECORD
    bne :+
    jsr saveRecordLocals    ; Save local variables
    jsr cloneRecordSubRecord
    jsr restoreRecordLocals
    jmp NX
    ; Is it a file?
:   cmp #RECDECL_FILE
    bne NX
    jsr cloneRecordFile
    ; Move ptr3 forward by 4 bytes, to the next item in the list
NX: lda ptr3
    clc
    adc #4
    sta ptr3
    lda ptr3+1
    adc #0
    sta ptr3+1
    jmp L1
DN: rts
.endproc

; This routine adds the record offset to ptr1 and ptr2
.proc addCloneOffset
    ; Put record field offset in tmp1/tmp2
    ldy #2
    lda (ptr3),y
    sta tmp1
    iny
    lda (ptr3),y
    sta tmp2
    ; Add offset (tmp1/tmp2) to ptr1
    lda ptr1
    clc
    adc tmp1
    sta ptr1
    lda ptr1+1
    adc tmp2
    sta ptr1+1
    ; Add offset (tmp1/tmp2) to ptr2
    lda ptr2
    clc
    adc tmp1
    sta ptr2
    lda ptr2+1
    adc tmp2
    sta ptr2+1
    rts
.endproc

.proc cloneRecordArray
    ; Add the array offset to ptr1 and ptr2
    jsr addCloneOffset
    ; Put the target heap and source heap on the stack (in that order)
    lda ptr2
    ldx ptr2+1
    jsr pusheax
    lda ptr1
    ldx ptr1+1
    jsr pusheax
    ; Load the pointer to the array's declaration block
    ldy #1
    lda (ptr3),y
    tax
    dey
    lda (ptr3),y
    ; Clone the array
    jmp cloneArrayDeclaration
.endproc

.proc cloneRecordString
    ; Ptr3 points to current entry in decl block
    ; Ptr1 points to source heap
    ; Ptr2 points to target heap
    jsr addCloneOffset
    ; Clone the string
    jsr saveRecordLocals
    ldy #1
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    ldy #TYPE_STRING_VAR
    jsr convertString
    ; Store the new string on the CPU stack
    pha
    txa
    pha
    jsr restoreRecordLocals
    ; Store the new string in the target heap
    ldy #1
    pla
    sta (ptr2),y
    dey
    pla
    sta (ptr2),y
    rts
.endproc

.proc cloneRecordSubRecord
    ; Add the sub-record offset to ptr1 and ptr2
    jsr addCloneOffset
    ; Put the target heap and source heap on the stack (in that order)
    lda ptr2
    ldx ptr2+1
    jsr popeax
    lda ptr1
    ldx ptr1+1
    jsr popeax
    ; Load the pointer to the sub-record's declaration block
    ldy #1
    lda (ptr3),y
    tax
    dey
    lda (ptr3),y
    ; Clone the sub-record
    jmp cloneRecordDeclaration
.endproc

.proc cloneRecordFile
    ; This one is easy. Just need to set bit 1 on the fourth byte of the file handle
    ldy #3
    lda (ptr2),y
    ora #1
    sta (ptr2),y
    rts
.endproc
