;
; icodeHeader.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; readIcodeHeader routine

.include "icode.inc"
.include "ast.inc"
.include "zeropage.inc"

.export readIcodeHeader

.import readIcodeByte, readStatus, runtimeStackSize, setRuntimeMode
.import nameBuf, nameLen

.export globalSlots

.bss

globalSlots: .res 2         ; the module's own level 1 slots

.code

; This routine reads the icode file's header (icode.inc). The file is open
; on logical file 2. It sets the runtime mode and stack size, the module's
; level 1 slot count (globalSlots) and its name (nameBuf and nameLen, for
; the object file). The carry is set if the file isn't icode or is another
; version.
.proc readIcodeHeader
    jsr readIcodeByte
    cmp #ICODE_MAGIC0
    bne BD
    jsr readIcodeByte
    cmp #ICODE_MAGIC1
    bne BD
    jsr readIcodeByte
    cmp #ICODE_VERSION
    bne BD

    ; The kind: code generation writes only programs so far
    jsr readIcodeByte
    cmp #ICODE_KIND_PROGRAM
    bne BD

    jsr readIcodeByte
    jsr setRuntimeMode
    jsr readIcodeByte
    sta runtimeStackSize
    jsr readIcodeByte
    sta runtimeStackSize+1
    jsr readIcodeByte
    sta globalSlots
    jsr readIcodeByte
    sta globalSlots+1

    ; The module's name
    jsr readIcodeByte
    cmp #ICODE_MAX_NAME+1
    bcs BD
    sta nameLen
    ldx #0
:   cpx nameLen
    beq :+
    phx
    jsr readIcodeByte
    plx
    sta nameBuf,x
    inx
    bra :-

    ; A file that ends inside the header is bad
:   lda readStatus
    and #$40
    bne BD
    clc
    rts

BD: sec
    rts
.endproc
