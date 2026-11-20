;
; objcache.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; A unit's object file, <unit>.obj, stays beside its TPU between builds
; (plans/objcode.md Phase 4). It records a key for the TPU it was made
; from: the source's CRC the TPU holds, and a CRC of the TPU's header and
; used units (tpu.inc), which change with the source, the icode or TPU
; version and the interface CRC of each unit it used. Those are all the
; unit's icode depends on. Code generation skips a unit whose object has
; this object format, this runtime (RT_ABI_VERSION) and its TPU's key
; (genUnits in codegen.s). A unit compiled from its own icode file has no
; TPU, so its object has no key and is made each time.
;
; Rebuild all erases the objects with the TPUs (tpuClean in tpumake.s).

.include "c64.inc"
.include "asm.inc"
.include "linker.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"

.export tpuKey, objCurrent, keySrc, keyStamp, keyValid
.export initGenNames, addGenName, getGenUnitsX

.import readIcodeByte, readStatus

LFN_IN = 2                  ; the icode files' logical file number

GEN_MAX = 64                ; genNames' length, the units' names

.data

strTpu: .asciiz ".tpu,s,r"
strObj: .asciiz ".obj,s,r"

; The start of a current unit object's header
objStart:
    .byte OBJ_MAGIC0, OBJ_MAGIC1, OBJ_VERSION, RT_ABI_VERSION
    .byte OBJ_KIND_UNIT, OBJ_FLAG_CACHED
objStart2:

.bss

keySrc: .res 2              ; the TPU's source CRC
keyStamp: .res 2            ; the CRC of its header and used units
keyValid: .res 1            ; non-zero once tpuKey has made them
crc: .res 2
fn: .res 24                 ; a unit's file name, then the suffix
left: .res 1
nameLen: .res 1
genNames: .res GEN_MAX + 1  ; the units generated, each with a space
genLen: .res 1

.code

; This routine makes the key of the TPU of the unit named at A/X
; (null-terminated): keySrc and keyStamp, and keyValid non-zero. The carry
; is set, and keyValid zero, if the TPU can't be read.
.proc tpuKey
    ldy #0
    jsr openFile
    lda #0
    sta keyValid
    lda #$ff
    sta crc
    sta crc+1

    ; The magic, the versions and the flags
    ldx #5
:   jsr readCrc
    dex
    bne :-

    ; The source's CRC, then the interface's
    jsr readCrc
    sta keySrc
    jsr readCrc
    sta keySrc+1
    jsr readCrc
    jsr readCrc

    ; The used units: each one's name and the interface CRC it had
    jsr readCrc
    sta left
L1: lda left
    beq DN
    dec left
    jsr readCrc
    clc
    adc #2
    tax
:   jsr readCrc
    dex
    bne :-
    lda readStatus
    bne BD
    bra L1

DN: lda readStatus
    bne BD
    lda crc
    sta keyStamp
    lda crc+1
    sta keyStamp+1
    inc keyValid
    jsr closeFile
    clc
    rts

BD: jsr closeFile
    sec
    rts
.endproc

; This routine reads a byte of the TPU and adds it to the CRC. It keeps X
; and returns the byte in A.
.proc readCrc
    jsr readIcodeByte
    pha
    phx
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
    plx
    pla
    rts
.endproc

; This routine returns the carry clear if the object file of the unit
; named at A/X (null-terminated) is current: it is there, it is a unit's
; of this object format and runtime, and its key is the one tpuKey made.
.proc objCurrent
    ldy #1
    jsr openFile
    ldx #0
L1: jsr readIcodeByte
    cmp objStart,x
    bne NO
    inx
    cpx #objStart2 - objStart
    bne L1
    jsr readIcodeByte
    cmp keySrc
    bne NO
    jsr readIcodeByte
    cmp keySrc+1
    bne NO
    jsr readIcodeByte
    cmp keyStamp
    bne NO
    jsr readIcodeByte
    cmp keyStamp+1
    bne NO
    lda readStatus              ; a file that isn't there, or ends
    bne NO
    jsr closeFile
    clc
    rts

NO: jsr closeFile
    sec
    rts
.endproc

; This routine opens the file named at A/X (null-terminated), with the
; suffix ".tpu,s,r" if Y is 0 or ".obj,s,r" if it is 1, on LFN_IN to read
.proc openFile
    sta ptr1
    stx ptr1+1
    lda #<strTpu
    ldx #>strTpu
    cpy #0
    beq :+
    lda #<strObj
    ldx #>strObj
:   sta ptr2
    stx ptr2+1
    ldy #0
:   lda (ptr1),y
    beq :+
    sta fn,y
    iny
    bra :-
:   ldx #0
:   lda (ptr2,x)
    sta fn,y
    beq :+
    iny
    inw ptr2
    bra :-
:   sty nameLen
    ldx DEVNUM
    lda #LFN_IN
    tay
    jsr SETLFS
    lda nameLen
    ldx #<fn
    ldy #>fn
    jsr SETNAM
    jsr OPEN
    lda #0
    sta readStatus
    rts
.endproc

; This routine closes LFN_IN
.proc closeFile
    lda #LFN_IN
    jsr CLOSE
    jmp CLRCHN
.endproc

; This routine starts the list of units generated with none
.proc initGenNames
    lda #0
    sta genLen
    sta genNames
    rts
.endproc

; This routine adds the name at A/X (null-terminated) and a space to the
; list of units generated, as far as it holds them
.proc addGenName
    sta ptr1
    stx ptr1+1
    ldx genLen
    ldy #0
:   lda (ptr1),y
    beq :+
    cpx #GEN_MAX - 1
    bcs DN
    sta genNames,x
    inx
    iny
    bra :-
:   lda #' '
    sta genNames,x
    inx
DN: lda #0
    sta genNames,x
    stx genLen
    rts
.endproc

; This routine returns in A/X the list of the units whose code the last
; code generation made, each name followed by a space. The test harness
; reads it before another overlay is loaded (compilertestasm).
.proc getGenUnitsX
    lda #<genNames
    ldx #>genNames
    rts
.endproc
