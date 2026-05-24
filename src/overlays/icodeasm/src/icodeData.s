;
; icodeData.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Intermediate code data segments

.include "asmlib.inc"
.include "icode.inc"
.include "zeropage.inc"
.include "membufasm.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

;;
;; Array and Record Data
;;
;; Schema information for arrays and records is stored in data segments (DAT instruction).
;; The schema blocks are referenced with labels when stored with DAT instructions
;; as well as by the DIA, DIR, and DCF instructions.
;;
;; IMPORTANT!
;;
;;    The layout of the schema blocks in the intermediate code is similar, but
;;    not identical to the layout in the object code. The following documents
;;    the layout in the intermediate code specifically.
;;
;; Element types:
;;
;;    Number  Description
;;    ------  -----------
;;    0       Scalar
;;    1       Real
;;    2       Record
;;    3       String
;;    4       File
;;    5       Array
;;
;; Array blocks:
;;
;;    Size in bytes  Description
;;    -------------  --------------------------------------------------------------
;;    2              This array's offset inside variable heap
;;    2              Lower bound of array index
;;    2              Upper bound of array index
;;    2              Element size
;;    1              Element type (see list)
;;    n/a            Null-terminated label for element declaration block
;;    n/a            Null-terminated label for list of literals to initialize the array elements
;;    2              The number of literals in the list
;;
;; Record blocks:
;;
;;    The record declaration block starts with a 4-byte header followed by a list of record
;;    fields to initialize. The list is terminated by a single zero byte.
;;
;;    Record field types:
;;
;;       Number  Description
;;       ------  -----------
;;       2       Record
;;       3       String
;;       4       File
;;       5       Array
;;
;;    Record Header:
;;
;;       Size in bytes  Description
;;       -------------  --------------------------------------------------------------
;;       2              This record's offset inside variable heap
;;       2              Size of record
;;
;;    List of record fields:
;;
;;       Size in bytes  Description
;;       -------------  --------------------------------------------------------------
;;       1              Field type (see list, 0 = end of list)
;;       2              Offset - number of bytes from start of record
;;       n/a            Null-terminated label for field declaration block (record or array)
;;

saveDataLabelOffset = 0
saveDataMemBufOffset = saveDataLabelOffset + 4
saveDataTypeOffset = saveDataMemBufOffset + 4

.export icodeInitData, icodeSaveData, icodeWriteData, icodeFreeData

.import loadStackValue

.bss

dataMemBuf: .res 4
callerMemBuf: .res 4
buffer: .res 1
buflen: .res 2

.code

.proc icodeInitData
    lda #0
    tax
    tay
    taz
    stq dataMemBuf
    rts
.endproc

; This routine saves a block to the intermediate code's data segment.
; Information in the block is saved until everything in the code segment
; is written. The data segment is then written at the end.
;
; Parameters (from bottom to top):
;    type (ARRAYDECL_) (1 byte)
;    caller's membuf pointer
;    label pointer (4 bytes)
.proc icodeSaveData
    ldq dataMemBuf
    jsr isQZero
    bne :+
    jsr allocMemBuf
    stq dataMemBuf

    ; Write the membuf type
:   ldz #saveDataTypeOffset
    nop
    lda (stackPointer),z
    sta buffer
    ldq dataMemBuf
    stq ptr1
    lda #<buffer
    sta ptr2
    lda #>buffer
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr writeToMemBuf

    ; Write the caller's membuf pointer
    lda #saveDataMemBufOffset
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq stackPointer
    clc
    adcq intOp32
    stq ptr2
    ldq dataMemBuf
    stq ptr1
    lda #4
    ldx #0
    jsr writeToMemBuf

    ; Write the label
    ldq dataMemBuf
    stq ptr1
    ldz #saveDataLabelOffset
    jsr loadStackValue
    stq ptr2
    ldz #0
    ; Count the label length
:   nop
    lda (ptr2),z
    beq :+
    inz
    bne :-
:   inz
    tza
    ldx #0
    jsr writeToMemBuf

    jsr popQ            ; label
    jsr popQ            ; caller's membuf
    jsr popA            ; type

    rts
.endproc

; This routine writes the data segments to the intermediate code.
.proc icodeWriteData
    ldq dataMemBuf
    jsr isQZero
    bne :+
    rts

:   stq ptr1
    lda #0
    tax
    jsr setMemBufPos

    ; Loop through the membuf
L1: ldq dataMemBuf
    jsr isMemBufAtEnd
    bne :+
    rts

    ; Read the buffer type
:   ldq dataMemBuf
    stq ptr1
    lda #<buffer
    sta ptr2
    lda #>buffer
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr readFromMemBuf

    ; Read the membuf pointer
    ldq dataMemBuf
    stq ptr1
    lda #<callerMemBuf
    sta ptr2
    lda #>callerMemBuf
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #4
    ldx #0
    jsr readFromMemBuf

    ; Write the mnemonic for the data segment
    lda #IC_DAT
    jsr CHROUT

    ; Write the type
    lda #IC_IBU
    jsr CHROUT
    lda buffer
    jsr CHROUT

    ; Write the label
    lda #IC_LBL
    jsr CHROUT
L2: ldq dataMemBuf
    stq ptr1
    lda #<buffer
    sta ptr2
    lda #>buffer
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr readFromMemBuf
    lda buffer
    jsr CHROUT
    lda buffer
    bne L2

    ; Look up the length of the data membuf
    ldq callerMemBuf
    stq ptr1
    ldz #MEMBUF::used
    nop
    lda (ptr1),z
    sta buflen
    inz
    nop
    lda (ptr1),z
    sta buflen+1

    ; Write the membuf length
    lda #IC_IWU
    jsr CHROUT
    lda buflen
    jsr CHROUT
    lda buflen+1
    jsr CHROUT

    ; Rewind the membuf
    ldq callerMemBuf
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos

    ; Write the membuf
L3: lda buflen
    ora buflen+1
    beq L4
    ldq callerMemBuf
    stq ptr1
    lda #<buffer
    sta ptr2
    lda #>buffer
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr readFromMemBuf
    lda buffer
    jsr CHROUT
    lda buflen
    sec
    sbc #1
    sta buflen
    lda buflen+1
    sbc #0
    sta buflen+1
    bra L3
L4: jmp L1
.endproc

; This routine frees the icode data segment and all membufs inside it.
.proc icodeFreeData
    ldq dataMemBuf
    jsr isQZero
    bne :+
    rts

    ; Rewind the membuf
:   stq ptr1
    lda #0
    tax
    jsr setMemBufPos

    ; Loop through the membufs inside
L1: ldq dataMemBuf
    jsr isMemBufAtEnd
    bne :+
    jmp DN

    ; Read the type
:   ldq dataMemBuf
    sta ptr1
    lda #<buffer
    sta ptr2
    lda #>buffer
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr readFromMemBuf

    ; Read the membuf
    ldq dataMemBuf
    stq ptr1
    lda #<callerMemBuf
    sta ptr2
    lda #>callerMemBuf
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #4
    ldx #0
    jsr readFromMemBuf

    ldq callerMemBuf
    jsr freeMemBuf

    ; Read past the label
L2: ldq dataMemBuf
    stq ptr1
    lda #<buffer
    sta ptr2
    lda #>buffer
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr readFromMemBuf
    lda buffer
    bne L2

    ; Loop back to read the next segment
    bra L1

DN: ldq dataMemBuf
    jsr freeMemBuf
    lda #0
    tax
    tay
    taz
    stq dataMemBuf
    rts
.endproc
