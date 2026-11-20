;
; tpu.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; tpuBeginX and tpuFinishX (tpuBegin and tpuFinish, tpu.inc) write a unit
; compiled on its own (unit mode) to its .tpu file (tpu.inc). Everything
; but the icode is known once the
; unit and the units it uses are parsed, and the interface must be written
; as the parser made it, before the resolver changes it. So tpuBeginX
; writes the first part of the file to zztpu then, and tpuFinishX copies it
; and the unit's icode file to <unit>.tpu once icode has written it.
;
; Erasing a file closes every open file (the drive's command channel), so
; each routine erases files before it opens any.

.include "c64.inc"
.include "ast.inc"
.include "hdr.inc"
.include "tpu.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export tpuBeginX, tpuFinishX
; For tpumake.s
.export nameToFn, addSuffix, openIn, startCrc, crcByte, crc, interfaceCrc
.export fnBuf, fnLen

.import hdrWrite, hdrOutVec

FILE_IN = 2                 ; logical file numbers
FILE_OUT = 3

.data

strTemp: .asciiz "zztpu"
strSystem: .asciiz "system"
strSeqRead: .asciiz ",s,r"
strSeqWrite: .asciiz ",s,w"
strTpu: .asciiz ".tpu"
unitPrefix: .asciiz ICODE_UNIT_PREFIX

.bss

rootPtr: .res 4             ; the unit's root declaration
unitsPtr: .res 4            ; the units list
srcName: .res 2             ; the source file's or unit's name (16 bits)
crc: .res 2
byteCount: .res 2
srcCrc: .res 2
ifCrc: .res 2
ifLen: .res 2
copyDecl: .res 4            ; the interface's root, for hdrWrite
copyStmt: .res 4
copyFrom: .res 4            ; the root makeCopy copies
copyCode: .res 4            ; for makeCopy
copyNext: .res 4
thisUnit: .res 4
usedRoot: .res 4             ; usedUnit's, kept from walkUsed's declPtr
declPtr: .res 4
codePtr: .res 4
chain: .res 1
writing: .res 1             ; zero while counting the used units
usedCount: .res 1
nameLen: .res 1
nameBuf: .res 24
fnBuf: .res 32              ; a file name, then ",s,r" or ",s,w"
fnLen: .res 1
outBuf: .res 32             ; <unit>.tpu, then ",s,w"
outLen: .res 1
codeLen: .res 2             ; the icode file's length
unitName: .res 13           ; tpuFinishX's unit
status: .res 1

.code

; This routine writes the first part of a unit's TPU to zztpu: everything
; but the icode section. Call it once the unit and every unit it uses are
; parsed, before resolving. On the runtime stack, bottom to top: the units
; list (4 bytes) and the 16-bit address of the source file's name (2). The
; unit's root declaration is in Q. The carry is set if it can't be
; written.
.proc tpuBeginX
    stq rootPtr
    jsr popAX
    sta srcName
    stx srcName+1
    jsr popQ
    stq unitsPtr

    lda #<strTemp
    ldx #>strTemp
    jsr eraseFile

    ; The source's CRC
    lda srcName
    ldx srcName+1
    jsr nameToFn
    lda #<strSeqRead
    ldx #>strSeqRead
    jsr openIn
    jsr startCrc
:   jsr CHRIN
    jsr crcByte
    lda STATUS
    and #$40
    beq :-
    lda #FILE_IN
    jsr CLOSE
    jsr CLRCHN
    lda crc
    sta srcCrc
    lda crc+1
    sta srcCrc+1

    ; The interface's CRC and length
    ldq rootPtr
    jsr interfaceCrc
    bcc :+
    rts
:   lda crc
    sta ifCrc
    lda crc+1
    sta ifCrc+1
    lda byteCount
    sta ifLen
    lda byteCount+1
    sta ifLen+1

    ; How many units it uses
    lda #0
    sta writing
    jsr walkUsed

    ; zztpu
    lda #<strTemp
    ldx #>strTemp
    jsr nameToFn
    lda #<strSeqWrite
    ldx #>strSeqWrite
    jsr openOut
    lda #TPU_MAGIC0
    jsr CHROUT
    lda #TPU_MAGIC1
    jsr CHROUT
    lda #TPU_VERSION
    jsr CHROUT
    lda #ICODE_VERSION
    jsr CHROUT
    lda #0                      ; flags
    jsr CHROUT
    lda srcCrc
    jsr CHROUT
    lda srcCrc+1
    jsr CHROUT
    lda ifCrc
    jsr CHROUT
    lda ifCrc+1
    jsr CHROUT

    ; The used units, each with its interface CRC
    lda usedCount
    jsr CHROUT
    inc writing
    jsr walkUsed
    bcs ER

    ; The interface section
    lda ifLen
    jsr CHROUT
    lda ifLen+1
    jsr CHROUT
    ldq rootPtr
    jsr makeCopy
    lda #<CHROUT
    sta hdrOutVec
    lda #>CHROUT
    sta hdrOutVec+1
    ldq copyDecl
    jsr hdrWrite
    php
    jsr freeCopy
    plp
    bcs ER

    jsr closeOut
    clc
    rts

ER: jsr closeOut
    sec
    rts
.endproc

; This routine writes <unit>.tpu: zztpu, then the icode section, the
; length and bytes of the unit's icode file (ICODE_UNIT_PREFIX and its
; name), and erases zztpu and the icode file. The unit's name is at A/X
; (16 bits, null-terminated). The carry is set if it can't be written.
.proc tpuFinishX
    sta ptr1
    stx ptr1+1
    ldy #0
:   lda (ptr1),y
    sta unitName,y
    beq :+
    iny
    cpy #12
    bne :-
    lda #0
    sta unitName,y

    ; <unit>.tpu, erased first
:   ldy #0
:   lda unitName,y
    beq :+
    sta outBuf,y
    iny
    bra :-
:   ldx #0
:   lda strTpu,x
    sta outBuf,y
    beq :+
    iny
    inx
    bra :-
:   sty outLen
    lda #<outBuf
    ldx #>outBuf
    jsr eraseFile

    ; The icode file's length. It must start as icode does.
    jsr icodeFn
    lda #<strSeqRead
    ldx #>strSeqRead
    jsr openIn
    lda #0
    sta codeLen
    sta codeLen+1
    jsr CHRIN
    cmp #ICODE_MAGIC0
    beq CL
    jmp BD
CL: inc codeLen
    bne :+
    inc codeLen+1
:   lda STATUS
    and #$40
    bne CD
    jsr CHRIN
    bra CL
CD: lda #FILE_IN
    jsr CLOSE
    jsr CLRCHN

    ; <unit>.tpu: zztpu, then the icode section
    ldx outLen
    ldy #0
:   lda strSeqWrite,y
    sta outBuf,x
    beq :+
    inx
    iny
    bra :-
:   stx outLen
    ldx DEVNUM
    lda #FILE_OUT
    tay
    jsr SETLFS
    lda outLen
    ldx #<outBuf
    ldy #>outBuf
    jsr SETNAM
    jsr OPEN

    lda #<strTemp
    ldx #>strTemp
    jsr nameToFn
    lda #<strSeqRead
    ldx #>strSeqRead
    jsr openIn
    jsr copyIn
    lda #FILE_IN
    jsr CLOSE

    ldx #FILE_OUT
    jsr CHKOUT
    lda codeLen
    jsr CHROUT
    lda codeLen+1
    jsr CHROUT
    jsr icodeFn
    lda #<strSeqRead
    ldx #>strSeqRead
    jsr openIn
    jsr copyIn
    lda #FILE_IN
    jsr CLOSE
    jsr closeOut

    ; zztpu and the unit's icode file, which is in the TPU now, aren't
    ; needed any more
    lda #<strTemp
    ldx #>strTemp
    jsr eraseFile
    jsr icodeFn
    lda #<fnBuf
    ldx #>fnBuf
    jsr eraseFile
    clc
    rts

BD: lda #FILE_IN
    jsr CLOSE
    jsr CLRCHN
    sec
    rts
.endproc

; This routine copies the input file to the output file, to the end
.proc copyIn
L1: ldx #FILE_IN
    jsr CHKIN
    jsr CHRIN
    pha
    lda STATUS
    sta status
    ldx #FILE_OUT
    jsr CHKOUT
    pla
    jsr CHROUT
    lda status
    and #$40
    beq L1
    jmp CLRCHN
.endproc

; This routine puts the unit's icode file's name in fnBuf
.proc icodeFn
    ldx #0
:   lda unitPrefix,x
    beq :+
    sta fnBuf,x
    inx
    bra :-
:   ldy #0
:   lda unitName,y
    sta fnBuf,x
    beq :+
    inx
    iny
    bra :-
:   stx fnLen
    rts
.endproc

; This routine counts the units the unit uses in usedCount, or writes
; each one's name and interface CRC: System first, as every unit uses it,
; then those its Uses name (interface, then implementation) but System.
; The carry is set if a CRC can't be made.
.proc walkUsed
    lda #0
    sta usedCount
    lda #<strSystem
    ldx #>strSystem
    jsr nameToBuf
    jsr usedUnit
    bcc :+
    rts

:   ldq rootPtr
    stq ptr1
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    stq codePtr
    jsr isQZero
    beq DN
    lda #stmt::interfaceDecl
    sta chain
L1: ldq codePtr
    stq ptr1
    ldz chain
    neg
    neg
    nop
    lda (ptr1),z
L2: stq declPtr
    jsr isQZero
    beq L4
    stq ptr1
    ldz #decl::kind
    nop
    lda (ptr1),z
    cmp #DECL_USES
    bne L3

    ; Its name, unless it is System
    ldz #decl::name
    ldx #0
:   nop
    lda (ptr1),z
    sta nameBuf,x
    beq :+
    inz
    inx
    cpx #23
    bne :-
:   jsr isSystem
    beq L3
    jsr usedUnit
    bcs ER

L3: ldq declPtr
    stq ptr1
    ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    bra L2

L4: lda chain
    cmp #stmt::decl
    beq DN
    lda #stmt::decl
    sta chain
    bra L1

DN: clc
ER: rts
.endproc

; This routine counts the unit named in nameBuf or, while writing, writes
; its name and interface CRC. The carry is set if the CRC can't be made.
.proc usedUnit
    inc usedCount
    lda writing
    bne :+
    clc
    rts

:   ldx #0
:   lda nameBuf,x
    beq :+
    inx
    bra :-
:   stx nameLen
    txa
    jsr CHROUT
    ldx #0
:   cpx nameLen
    beq :+
    lda nameBuf,x
    jsr CHROUT
    inx
    bra :-

    ; Its interface CRC, from its root in the units list, or the one its
    ; TPU recorded if it was loaded from it (tpuload.s)
:   jsr findUnit
    jsr isQZero
    bne :+
    lda #0                      ; not in the list
    sta crc
    sta crc+1
    bra WR
:   stq usedRoot
    ldq thisUnit
    stq ptr1
    ldz #unit::fromTpu
    nop
    lda (ptr1),z
    beq :+
    ldz #unit::ifCrc
    nop
    lda (ptr1),z
    sta crc
    inz
    nop
    lda (ptr1),z
    sta crc+1
    bra WR
:   ldq usedRoot
    jsr interfaceCrc
    bcc WR
    rts
WR: lda crc
    jsr CHROUT
    lda crc+1
    jsr CHROUT
    clc
    rts
.endproc

; This routine returns in Q the root declaration of the unit named in
; nameBuf, from the units list, or zero
.proc findUnit
    ldq unitsPtr
L1: stq thisUnit
    jsr isQZero
    beq DN
    stq ptr1
    ldz #unit::name
    ldx #0
:   nop
    lda (ptr1),z
    cmp nameBuf,x
    bne NX
    cmp #0
    beq FD
    inz
    inx
    bra :-
NX: ldq thisUnit
    stq ptr1
    ldz #unit::next
    neg
    neg
    nop
    lda (ptr1),z
    bra L1
FD: ldq thisUnit
    stq ptr1
    ldz #unit::astRoot
    neg
    neg
    nop
    lda (ptr1),z
DN: rts
.endproc

; This routine returns with Z set if nameBuf is "system"
.proc isSystem
    ldx #0
:   lda nameBuf,x
    cmp strSystem,x
    bne DN
    cmp #0
    beq DN
    inx
    bra :-
DN: rts
.endproc

; This routine makes the CRC and length of the interface section of the
; unit whose root is in Q, in crc and byteCount. The carry is set if it
; can't be written.
.proc interfaceCrc
    jsr makeCopy
    jsr startCrc
    lda #<countByte
    sta hdrOutVec
    lda #>countByte
    sta hdrOutVec+1
    ldq copyDecl
    jsr hdrWrite
    php
    jsr freeCopy
    plp
    rts
.endproc

; This routine adds the byte in A to the CRC and the count
.proc countByte
    inc byteCount
    bne crcByte
    inc byteCount+1
    ; Fall through to crcByte
.endproc

; This routine adds the byte in A to the CRC (CRC-16/CCITT)
.proc crcByte
    eor crc+1
    sta crc+1
    ldx #8
L1: asl crc
    rol crc+1
    bcc :+
    lda crc+1
    eor #$10
    sta crc+1
    lda crc
    eor #$21
    sta crc
:   dex
    bne L1
    rts
.endproc

.proc startCrc
    lda #$ff
    sta crc
    sta crc+1
    lda #0
    sta byteCount
    sta byteCount+1
    rts
.endproc

; This routine copies the root declaration in Q and its statement to
; copyDecl and copyStmt, without the implementation's declarations and
; without a leading Uses of System, which the parser gives the first module
; it parses and the compiler gives every unit (injectSystemUnit). Its
; header is then the interface, as a library's is.
.proc makeCopy
    stq copyFrom
    lda #.sizeof(decl)
    ldx #0
    jsr heapAlloc
    stq copyDecl
    stq ptr2
    ldq copyFrom
    stq ptr1
    ldz #0
:   nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    inz
    cpz #.sizeof(decl)
    bne :-

    lda #0
    tax
    tay
    taz
    stq copyStmt
    ldq copyFrom
    stq ptr1
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    bne :+
    rts
:   stq copyCode

    lda #.sizeof(stmt)
    ldx #0
    jsr heapAlloc
    stq copyStmt
    stq ptr2
    ldq copyCode
    stq ptr1
    ldz #0
:   nop
    lda (ptr1),z
    nop
    sta (ptr2),z
    inz
    cpz #.sizeof(stmt)
    bne :-

    ; No implementation
    ldz #stmt::decl
    lda #0
    ldx #4
:   nop
    sta (ptr2),z
    inz
    dex
    bne :-

    ; No leading Uses of System
    ldz #stmt::interfaceDecl
    neg
    neg
    nop
    lda (ptr2),z
    jsr isQZero
    beq LK
    stq ptr1
    ldz #decl::kind
    nop
    lda (ptr1),z
    cmp #DECL_USES
    bne LK
    ldz #decl::name
    ldx #0
:   nop
    lda (ptr1),z
    cmp strSystem,x
    bne LK
    cmp #0
    beq :+
    inz
    inx
    bra :-
:   ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    stq copyNext
    ldq copyStmt
    stq ptr2
    ldz #stmt::interfaceDecl
    ldx #0
:   lda copyNext,x
    nop
    sta (ptr2),z
    inz
    inx
    cpx #4
    bne :-

    ; The copy's statement
LK: ldq copyDecl
    stq ptr2
    ldz #decl::code
    ldx #0
:   lda copyStmt,x
    nop
    sta (ptr2),z
    inz
    inx
    cpx #4
    bne :-
    rts
.endproc

.proc freeCopy
    ldq copyStmt
    jsr isQZero
    beq :+
    jsr heapFree
:   ldq copyDecl
    jmp heapFree
.endproc

; This routine copies the null-terminated name at A/X to nameBuf
.proc nameToBuf
    sta ptr1
    stx ptr1+1
    ldy #0
:   lda (ptr1),y
    sta nameBuf,y
    beq :+
    iny
    bra :-
:   rts
.endproc

; This routine copies the null-terminated name at A/X to fnBuf, with its
; length in fnLen
.proc nameToFn
    sta ptr1
    stx ptr1+1
    ldy #0
:   lda (ptr1),y
    sta fnBuf,y
    beq :+
    iny
    bra :-
:   sty fnLen
    rts
.endproc

; This routine erases the file named at A/X if it's there
.proc eraseFile
    sta ptr1
    stx ptr1+1
    ldy #0
    sty ptr1+2
    sty ptr1+3
    ldz #0
    jsr doesFileExist
    beq :+
    jsr scratchFile
:   rts
.endproc

; This routine adds the suffix at A/X (",s,r") to fnBuf and opens it as
; the input
.proc openIn
    jsr addSuffix
    ldx DEVNUM
    lda #FILE_IN
    tay
    jsr SETLFS
    lda fnLen
    ldx #<fnBuf
    ldy #>fnBuf
    jsr SETNAM
    jsr OPEN
    ldx #FILE_IN
    jmp CHKIN
.endproc

; This routine adds the suffix at A/X (",s,w") to fnBuf and opens it as
; the output
.proc openOut
    jsr addSuffix
    ldx DEVNUM
    lda #FILE_OUT
    tay
    jsr SETLFS
    lda fnLen
    ldx #<fnBuf
    ldy #>fnBuf
    jsr SETNAM
    jsr OPEN
    ldx #FILE_OUT
    jmp CHKOUT
.endproc

.proc closeOut
    jsr CLRCHN
    lda #FILE_OUT
    jmp CLOSE
.endproc

; This routine adds the null-terminated suffix at A/X to fnBuf
.proc addSuffix
    sta ptr1
    stx ptr1+1
    ldx fnLen
    ldy #0
:   lda (ptr1),y
    sta fnBuf,x
    beq :+
    inx
    iny
    bra :-
:   stx fnLen
    rts
.endproc
