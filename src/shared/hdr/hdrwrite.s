;
; hdrwrite.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; hdrWrite routine. Writes the AST reachable from a module's declaration
; as pre-compiled header records (hdr.inc). mkhdr writes a library unit's
; .hdr file with it. It was mkhdr's own until a Pascal unit's interface
; needed it too (plans/tpu.md).

.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "asmlib.inc"
.include "ast.inc"
.include "hdr.inc"
.include "4510macros.inc"

.export hdrWrite

.import hdrRecSize, hdrFieldFirst, hdrFieldNext, hdrTbl, hdrEntryPtr

.bss

candAddr: .res 4            ; address being looked up
addKind: .res 1
idx: .res 2
count: .res 2               ; number of records in the index table
finalCount: .res 2
cur: .res 2
recKind: .res 1
recSize: .res 1
tgtKind: .res 1
fieldOff: .res 1
nameLen: .res 1
emitIdx: .res 1
resultLo: .res 1
resultHi: .res 1
errCode: .res 1
outBuf: .res 64

.code

; This routine writes the header of the module whose root declaration is
; in Q to the current output (CHROUT): the magic, version and record count,
; then every record reachable from it, the root first. Pointers become
; record numbers. It returns with the carry clear and the record count in
; A/X, or with the carry set and an HDR_ERR_* code in A. The caller opens
; and closes the output.
.proc hdrWrite
    stq candAddr

    ; The index table
    lda #<(HDR_MAX_RECORDS*HDR_ENTRY_SIZE)
    ldx #>(HDR_MAX_RECORDS*HDR_ENTRY_SIZE)
    jsr heapAlloc
    stq hdrTbl

    ; Seed the table with the module decl (record 1)
    lda #0
    sta count
    sta count+1
    lda #HDR_REC_DECL
    jsr findOrAdd
    bcc :+
    jmp tooMany

    ; Phase 1. Walk every record and add whatever it points to.
:   lda #1
    sta cur
    lda #0
    sta cur+1

PhaseA:
    lda count
    cmp cur
    lda count+1
    sbc cur+1
    bcc PhaseADone              ; count < cur
    jsr loadEntry
    lda recKind
    cmp #HDR_REC_NAME
    beq NextA
    jsr hdrFieldFirst
FieldA:
    jsr hdrFieldNext
    bcs NextA
    stx fieldOff
    sta tgtKind
    lda tgtKind
    beq FieldA                  ; plain value
    bmi FieldA                  ; not stored
    ldz fieldOff
    ldx #0
:   nop
    lda (ptr1),z
    sta candAddr,x
    inz
    inx
    cpx #4
    bne :-
    lda tgtKind
    jsr findOrAdd
    bcc FieldA
    jmp tooMany
NextA:
    inc cur
    bne PhaseA
    inc cur+1
    bra PhaseA

PhaseADone:
    lda count
    sta finalCount
    lda count+1
    sta finalCount+1

    ; Header: magic, version, record count
    lda #'P'
    jsr CHROUT
    lda #'H'
    jsr CHROUT
    lda #HDR_VERSION
    jsr CHROUT
    lda count
    jsr CHROUT
    lda count+1
    jsr CHROUT

    ; Phase 2. Write each record.
    lda #1
    sta cur
    lda #0
    sta cur+1

PhaseB:
    lda count
    cmp cur
    lda count+1
    sbc cur+1
    bcc PhaseBDone
    jsr loadEntry
    lda recKind
    cmp #HDR_REC_NAME
    beq WriteName
    jsr writeStruct
    bra NextB

WriteName:
    ldz #0
:   nop
    lda (ptr1),z
    beq :+
    inz
    bne :-
    ; Name is 255 characters or longer
    lda #HDR_ERR_NAME_LONG
    jmp fail
:   inz
    tza
    sta nameLen
    lda #HDR_REC_NAME
    jsr CHROUT
    lda nameLen
    jsr CHROUT
    lda #0
    sta emitIdx
:   ldz emitIdx
    nop
    lda (ptr1),z
    jsr CHROUT
    inc emitIdx
    lda emitIdx
    cmp nameLen
    bne :-

NextB:
    inc cur
    bne PhaseB
    inc cur+1
    bra PhaseB

    ; Every pointer should have been found in phase 1
PhaseBDone:
    lda count
    cmp finalCount
    bne Internal
    lda count+1
    cmp finalCount+1
    bne Internal

    ldq hdrTbl
    jsr heapFree
    lda count
    ldx count+1
    clc
    rts

Internal:
    lda #HDR_ERR_INTERNAL
    jmp fail

tooMany:
    lda #HDR_ERR_TOO_MANY
    ; Fall through to fail
.endproc

; This routine frees the index table and returns the error in A with the
; carry set
.proc fail
    sta errCode
    ldq hdrTbl
    jsr heapFree
    lda errCode
    sec
    rts
.endproc

; Write the structure for the record in ptr1, with its pointers replaced
; by record indexes. recKind has the HDR_REC_* kind.
.proc writeStruct
    ldx recKind
    lda hdrRecSize,x
    sta recSize

    ; Copy the structure into outBuf
    ldx #0
    ldz #0
:   nop
    lda (ptr1),z
    sta outBuf,x
    inz
    inx
    cpx recSize
    bne :-

    lda recKind
    jsr hdrFieldFirst
Field:
    jsr hdrFieldNext
    bcs Emit
    stx fieldOff
    sta tgtKind
    lda tgtKind
    beq Field                   ; plain value
    bmi ZeroField

    ; Replace the address with its record index
    ldx fieldOff
    ldy #0
:   lda outBuf,x
    sta candAddr,y
    inx
    iny
    cpy #4
    bne :-
    lda tgtKind
    jsr findOrAdd
    sta resultLo
    stx resultHi
    ldx fieldOff
    lda resultLo
    sta outBuf,x
    inx
    lda resultHi
    sta outBuf,x
    inx
    lda #0
    sta outBuf,x
    inx
    sta outBuf,x
    bra Field

ZeroField:
    ldx fieldOff
    ldy #4
    lda #0
:   sta outBuf,x
    inx
    dey
    bne :-
    bra Field

Emit:
    lda recKind
    jsr CHROUT
    lda #0
    sta emitIdx
:   ldx emitIdx
    lda outBuf,x
    jsr CHROUT
    inc emitIdx
    lda emitIdx
    cmp recSize
    bne :-
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

; Find candAddr in the index table. If it's not there, add it with the kind in A.
; Returns the 1-based record index in A/X (zero for a null address).
; Carry is set if the table is full.
.proc findOrAdd
    sta addKind

    lda candAddr
    ora candAddr+1
    ora candAddr+2
    ora candAddr+3
    bne :+
    lda #0
    tax
    clc
    rts

:   lda #0
    sta idx
    sta idx+1

Search:
    inc idx
    bne :+
    inc idx+1
:   lda count
    cmp idx
    lda count+1
    sbc idx+1
    bcc NotFound                ; count < idx
    lda idx
    ldx idx+1
    jsr hdrEntryPtr
    ldx #0
    ldz #0
:   nop
    lda (ptr3),z
    cmp candAddr,x
    bne Search
    inz
    inx
    cpx #4
    bne :-
    lda idx
    ldx idx+1
    clc
    rts

NotFound:
    inc count
    bne :+
    inc count+1
:   lda #<HDR_MAX_RECORDS
    cmp count
    lda #>HDR_MAX_RECORDS
    sbc count+1
    bcc Full                    ; HDR_MAX_RECORDS < count
    lda count
    ldx count+1
    jsr hdrEntryPtr
    ldx #0
    ldz #0
:   lda candAddr,x
    nop
    sta (ptr3),z
    inz
    inx
    cpx #4
    bne :-
    lda addKind
    nop
    sta (ptr3),z
    lda count
    ldx count+1
    clc
    rts

Full:
    sec
    rts
.endproc
