;
; hdrload.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; loadHeader routine. Loads a pre-compiled library header (see hdr.inc)
; into the heap in place of parsing the library's Pascal source.

.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "c64.inc"
.include "asmlib.inc"
.include "ast.inc"
.include "hdr.inc"
.include "4510macros.inc"

HDR_FILENUM = 3

.export loadHeader

.import hdrRecSize, hdrFieldFirst, hdrFieldNext, hdrTbl, hdrEntryPtr

.data

strReadExt: .asciiz ",p,r"

.bss

rdName: .res 32
rdLen: .res 1
count: .res 2
cur: .res 2
recKind: .res 1
recSize: .res 1
newAddr: .res 4
tgtKind: .res 1
fieldOff: .res 1
readIdx: .res 1
refIdx: .res 2
rootAddr: .res 4

.code

; Load the header whose null-terminated filename (e.g. "system.hdr") is in A/X.
;
; Returns carry set on success, with the unit's module decl in Q.
; Returns carry clear if the file is missing or is not a valid header
; of this format version. The caller should parse the .pas file instead.
.proc loadHeader
    sta ptr1
    stx ptr1+1
    lda #0
    sta ptr1+2
    sta ptr1+3

    ; Does the file exist?
    lda ptr1
    ldx ptr1+1
    ldy #0
    ldz #0
    jsr doesFileExist
    cmp #0
    bne :+
    clc
    rts

:   jsr openInput
    jsr readPreamble
    bcc Fail
    jsr readRecords
    php
    jsr closeInput
    plp
    bcc FailFree
    jsr fixPointers
    bcc FailFree

    ; Record 1 is the unit's module decl
    lda #1
    ldx #0
    jsr hdrEntryPtr
    ldx #0
    ldz #0
:   nop
    lda (ptr3),z
    sta rootAddr,x
    inz
    inx
    cpx #4
    bne :-

    ldq hdrTbl
    jsr heapFree
    ldq rootAddr
    sec
    rts

FailFree:
    ldq hdrTbl
    jsr heapFree
    clc
    rts

Fail:
    jsr closeInput
    clc
    rts
.endproc

; Open the header file for reading. ptr1 points to the filename.
.proc openInput
    ; Build the name to open: the filename plus ",p,r"
    ldy #0
:   lda (ptr1),y
    beq :+
    sta rdName,y
    iny
    cpy #20
    bne :-
:   ldx #0
:   lda strReadExt,x
    sta rdName,y
    beq :+
    iny
    inx
    bne :-
:   sty rdLen

    ldx DEVNUM
    lda #HDR_FILENUM
    tay
    jsr SETLFS
    ldx #<rdName
    ldy #>rdName
    lda rdLen
    jsr SETNAM
    jsr OPEN
    ldx #HDR_FILENUM
    jmp CHKIN
.endproc

.proc closeInput
    jsr CLRCHN
    lda #HDR_FILENUM
    jmp CLOSE
.endproc

; Check the magic and version and read the record count.
; Allocates the index table. Carry is clear if the file is not valid.
.proc readPreamble
    jsr CHRIN
    cmp #'P'
    bne Bad
    jsr CHRIN
    cmp #'H'
    bne Bad
    jsr CHRIN
    cmp #HDR_VERSION
    bne Bad

    jsr CHRIN
    sta count
    jsr CHRIN
    sta count+1
    lda count
    ora count+1
    beq Bad
    lda #<HDR_MAX_RECORDS
    cmp count
    lda #>HDR_MAX_RECORDS
    sbc count+1
    bcc Bad                     ; HDR_MAX_RECORDS < count

    ; Allocate the index table: count * HDR_ENTRY_SIZE
    lda count
    asl
    sta intOp1
    lda count+1
    rol
    sta intOp1+1
    asl intOp1
    rol intOp1+1
    clc
    lda intOp1
    adc count
    pha
    lda intOp1+1
    adc count+1
    tax
    pla
    jsr heapAlloc
    stq hdrTbl
    sec
    rts

Bad:
    clc
    rts
.endproc

; Allocate and read each record. Pointer fields still hold record indexes.
; Carry is clear if the file is not valid.
.proc readRecords
    lda #1
    sta cur
    lda #0
    sta cur+1

Next:
    lda count
    cmp cur
    lda count+1
    sbc cur+1
    bcs :+                      ; cur <= count
    jmp Done

:   jsr CHRIN
    sta recKind
    cmp #HDR_REC_NAME
    bne :+
    jsr CHRIN                   ; length of the name
    bra HaveSize
:   cmp #0
    beq Bad
    cmp #HDR_REC_COUNT+1
    bcs Bad
    tax
    lda hdrRecSize,x
HaveSize:
    sta recSize
    ldx #0
    jsr heapAlloc
    stq newAddr

    ; Record it in the index table
    lda cur
    ldx cur+1
    jsr hdrEntryPtr
    ldx #0
    ldz #0
:   lda newAddr,x
    nop
    sta (ptr3),z
    inz
    inx
    cpx #4
    bne :-
    lda recKind
    nop
    sta (ptr3),z

    ; Read the record's bytes
    ldq newAddr
    stq ptr1
    lda #0
    sta readIdx
:   jsr CHRIN
    ldz readIdx
    nop
    sta (ptr1),z
    inc readIdx
    lda readIdx
    cmp recSize
    bne :-

    inc cur
    bne :+
    inc cur+1
:   jmp Next

Done:
    jsr READST
    and #$bf                    ; end-of-file is expected
    bne Bad
    sec
    rts

Bad:
    clc
    rts
.endproc

; Replace each record index with the record's address.
; Carry is clear if an index is out of range.
.proc fixPointers
    lda #1
    sta cur
    lda #0
    sta cur+1

Next:
    lda count
    cmp cur
    lda count+1
    sbc cur+1
    bcs :+                      ; cur <= count
    sec
    rts

:   jsr loadEntry
    lda recKind
    cmp #HDR_REC_NAME
    beq NextRec
    jsr hdrFieldFirst
Field:
    jsr hdrFieldNext
    bcs NextRec
    stx fieldOff
    sta tgtKind
    lda tgtKind
    beq Field                   ; plain value
    bmi Field                   ; not stored
    jsr fixField
    bcs Field
    rts                         ; carry is clear

NextRec:
    inc cur
    bne :+
    inc cur+1
:   jmp Next
.endproc

; Replace the record index in the pointer field at fieldOff of the record in ptr1.
; Carry is clear if the index is out of range.
.proc fixField
    ldz fieldOff
    nop
    lda (ptr1),z
    sta refIdx
    inz
    nop
    lda (ptr1),z
    sta refIdx+1
    lda refIdx
    ora refIdx+1
    bne :+
    sec                         ; null pointer
    rts

:   lda count
    cmp refIdx
    lda count+1
    sbc refIdx+1
    bcs :+                      ; refIdx <= count
    clc
    rts

:   lda refIdx
    ldx refIdx+1
    jsr hdrEntryPtr
    ldx #0
    ldz #0
:   nop
    lda (ptr3),z
    sta newAddr,x
    inz
    inx
    cpx #4
    bne :-
    ldz fieldOff
    ldx #0
:   lda newAddr,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    sec
    rts
.endproc

; Read the index table entry for record cur.
; Sets ptr1 to the record's address and recKind to its kind.
.proc loadEntry
    lda cur
    ldx cur+1
    jsr hdrEntryPtr
    ldx #0
    ldz #0
:   nop
    lda (ptr3),z
    sta ptr1,x
    inz
    inx
    cpx #4
    bne :-
    nop
    lda (ptr3),z
    sta recKind
    rts
.endproc
