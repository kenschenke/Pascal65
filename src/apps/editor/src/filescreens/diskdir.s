;
; diskdir.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routines to read and manage disk directories

.include "zeropage.inc"
.include "editor.inc"
.include "cbm_kernal.inc"
.include "c64.inc"
.include "4510macros.inc"
.include "asmlib.inc"

.export freeDirEnts, readDiskDir

.import isQZero, showAllFiles

.bss

dirPtr: .res 4
lastPtr: .res 4
buffer: .res 40
first: .res 1
intBuf: .res 7

.data

dirFilename: .asciiz "$"
seqStr: .asciiz "seq"

.code

; This routine frees a linked list of DIRENT structures.
; Pointer to first DIRENT passed in Q
.proc freeDirEnts
    stq ptr1                ; Store DIRENT pointer in ptr1
    jsr isQZero
    beq DN                  ; Branch if NULL
    ldz #DIRENT::next
    neg
    neg
    nop
    lda (ptr1),z            ; Load next pointer
    stq dirPtr              ; Store it in dirPtr
    ldq ptr1                ; Load current DIRENT pointer
    jsr heapFree            ; Free it
    ldq dirPtr              ; Load next DIRENT pointer
    jmp freeDirEnts         ; Loop back around
DN: rts
.endproc

; This routine checks if the current file is a SEQ type
; The file type is in the buffer variable and the file type
; is indexed by the Y register.
;
; The Y register is preserved.
;
; If the file type is SEQ, the carry bit is set on return.
.proc isSeqType
    ldx #0
    phy                     ; Preserve the Y register
:   lda buffer,y
    cmp seqStr,x
    bne NO
    inx
    cpx #3
    beq YES
    iny
    bne :-
NO: ply
    clc
    rts
YES:
    ply
    sec
    rts
.endproc

; This routine reads a disk directory and creates a linked list
; or DIRENT structures. A pointer to the list is returned in Q.
; NULL is returned if the directory was not read or was empty.
;
; If the directory listing will contain all files, the carry flag
; is set on entry. If carry is clear, only SEQ files are listed.
.proc readDiskDir
    lda #0
    tax
    tay
    taz
    stq dirPtr
    stq lastPtr

    ; Call SETLFS
    ldx DEVNUM
    lda #1
    ldy #0
    ; tay
    ; iny
    jsr SETLFS
    ; Call SETNAM
    lda #1
    ldx #<dirFilename
    ldy #>dirFilename
    jsr SETNAM
    ; Call OPEN
    jsr OPEN
    ; Set the input channel
    ldx #1
    jsr CHKIN
    ; Skip the first two bytes
    jsr CHRIN
    jsr CHRIN

    ; Set a flag to skip the first entry
    lda #1
    sta first

    ; Loop until two zeros are read
L1: jsr CHRIN
    sta tmp1
    jsr CHRIN
    ora tmp1
    ; lda STATUS
    bne :+
    jmp DN

    ; Read the block size for this entry
:   jsr CHRIN
    sta intOp1
    jsr CHRIN
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16

    ; Read the directory entry into a buffer
    ; until we see a 0.
    ldy #0
:   jsr CHRIN
    sta buffer,y
    cmp #0
    beq :+
    iny
    bne :-

        ; If this is the first entry, skip it
:   lda first
    beq :+
    lda #0
    sta first
    beq L1

    ; Find the opening quote of the filename
:   ldy #0
:   lda buffer,y
    beq L2
    cmp #CH_DOUBLE_QUOTE
    beq L2
    iny
    bne :-

L2: cmp #0
    beq L1          ; Branch if no quote found
    iny
    phy             ; Push the position of the first character after the quote

    lda #.sizeof(DIRENT)
    ldx #0
    jsr heapAlloc
    stq ptr1
    ; Set the next pointer to NULL
    lda #0
    ldz #DIRENT::next+3
    ldx #3
:   nop
    sta (ptr1),z
    dez
    dex
    bpl :-

    ; Fill the filename, type, and blocks with spaces
    ldz #DIRENT::filename
    ldx #16
    lda #' '
:   nop
    sta (ptr1),z
    inz
    dex
    bne :-
    ldz #DIRENT::type
    ldx #3
:   nop
    sta (ptr1),z
    inz
    dex
    bne :-
    ldz #DIRENT::blocks
    ldx #3
:   nop
    sta (ptr1),z
    inz
    dex
    bne :-

    ; Copy the block count for the entry
    ldz #DIRENT::blocks
    ldx #0
:   lda intBuf,x
    beq :+
    nop
    sta (ptr1),z
    inz
    inx
    bne :-

    ; Copy the filename into the DIRENT
:   ply             ; Pop buffer index off CPU stack
    ldz #DIRENT::filename
:   lda buffer,y
    cmp #CH_DOUBLE_QUOTE
    beq L3
    nop
    sta (ptr1),z
    inz
    iny
    bne :-

L3:
    ; Look for the file type (skip spaces)
    iny
:   lda buffer,y
    beq L5
    cmp #' '
    bne L4
    iny
    bne :-

L4:
    lda showAllFiles
    bne :+
    jsr isSeqType
    bcs :+
    ; Non-SEQ file and not all files are being shown.
    ; Ignore this entry and free the DIRENT structure.
    ldq ptr1
    jsr heapFree
    jmp L1
    ; Copy the file type (if found)
:   ldx #3
    ldz #DIRENT::type
:   lda buffer,y
    nop
    sta (ptr1),z
    inz
    iny
    dex
    bne :-


L5: ; Append this DIRENT to the linked list.
    ldq dirPtr
    jsr isQZero
    bne L6
    ; First entry
    ldq ptr1
    stq dirPtr
    stq lastPtr
    jmp L1

L6: ldq lastPtr
    stq ptr2
    ldz #DIRENT::next+3
    ldx #3
:   lda ptr1,x
    nop
    sta (ptr2),z
    dez
    dex
    bpl :-
    ldq ptr1
    stq lastPtr
    jmp L1

    ; Call CLOSE
DN: lda #1
    jsr CLOSE
    ; Reset the input channel
    ldx #0
    jsr CHKIN           ; Set the input device back to the keyboard
    ldq dirPtr
    rts
.endproc
