;
; loader.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; The dynamic runtime loader
;
; A program built for the dynamic runtime (the default) has an empty jump
; table at RT_BASE and this loader right after it, at LOADER_ADDR. Codegen
; copies it into the program as it is. The program header calls it where a
; static program calls RT_RUNTIMEERRORINIT, after it has saved page zero and
; the stack pointer. The loader:
;
;   1. Reads the header of runtimeN (RTH_* in asm.inc) and checks it.
;   2. Checks that the program, a minimum heap and the runtime stack fit
;      below rtLow, so loading the runtime can't overwrite the program.
;   3. Loads runtimeN at rtLow and copies its jump table to RT_BASE.
;   4. Patches the program header's stack top and heap top for rtLow. They
;      were set at compile time for the runtime on the compiler's disk.
;   5. Jumps to RT_RUNTIMEERRORINIT, which returns to the header.
;
; If the runtime is missing or bad, or the program doesn't fit, it prints a
; message, restores what the header changed and returns to BASIC.
;
; It reads the program header's values through the header's address, which
; the linker patches into the first two instructions (the "init" tag).

.include "asm.inc"
.include "c64.inc"
.include "cbm_kernal.inc"

.export loaderStart, LOADER_SIZE, LOADER_INIT_L, LOADER_INIT_H

; Offsets in the program header (prgHeader.s)
.import PRG_HEADER_CODE_OFFSET_1: zp, PRG_HEADER_CODE_OFFSET_2: zp
.import PRG_HEADER_CODE_OFFSET_3: zp, PRG_HEADER_STACKSIZE1_L: zp
.import PRG_HEADER_STACKSIZE1_H: zp, PRG_HEADER_STACKSIZE2_L: zp
.import PRG_HEADER_STACKSIZE2_H: zp, PRG_HEADER_STACKTOP_H: zp

JMPTBL_SIZE = $156
LOADER_ADDR = RT_BASE + JMPTBL_SIZE
MIN_HEAP_SIZE = 256         ; as in checkCodeSize (prgHeader.s)
ZP_BACKUP_LEN = $5d         ; page zero bytes the header saves, from $04
LFN = 1

; Page zero the loader uses. The header has saved it.
HDR = ZP_PTR1L              ; the program header
SRC = ZP_PTR2L
DST = ZP_PTR3L
TMP = ZP_PTR4L

.export LOADER_ADDR

.rodata

loaderStart:

.org LOADER_ADDR

loader:
    lda #0                  ; Low byte of the header, patched by the linker
initL = * - 1
    sta HDR
    lda #0                  ; High byte
initH = * - 1
    sta HDR+1

    ; Read runtimeN's load address and header
    lda #fileNameRdEnd - fileNameRd
    ldx #<fileNameRd
    ldy #>fileNameRd
    jsr SETNAM
    lda #LFN
    ldx DEVNUM
    ldy #2
    jsr SETLFS
    jsr OPEN
    bcc :+
    jmp NF
:
    ldx #LFN
    jsr CHKIN
    bcc :+
    jmp NC
:
    lda #0
    sta count
RH: jsr CHRIN
    ldx count
    sta rtHdr,x
    lda STATUS
    beq :+
    jmp RE                  ; The file ended or failed
:   inc count
    lda count
    cmp #2 + RTH_SIZE
    bne RH
    jsr closeFile

    ; Check it: the load address is rtLow, then magic and version
    lda rtHdr
    cmp rtHdr + 2 + RTH_LOW
    beq :+
    jmp BD
:
    lda rtHdr+1
    cmp rtHdr + 2 + RTH_LOW + 1
    beq :+
    jmp BD
:
    ldx #0
MG: lda rtHdr + 2 + RTH_MAGIC,x
    cmp magic,x
    beq :+
    jmp BD
:   inx
    cpx #5                  ; The magic number and the version
    bne MG

    ; The program must end below rtLow, with its heap and stack:
    ; heap bottom + stack size + 4 + MIN_HEAP_SIZE <= rtLow
    ldy #PRG_HEADER_CODE_OFFSET_2
    lda (HDR),y
    ldy #PRG_HEADER_STACKSIZE1_L
    clc
    adc (HDR),y
    sta TMP
    ldy #PRG_HEADER_CODE_OFFSET_3
    lda (HDR),y
    ldy #PRG_HEADER_STACKSIZE1_H
    adc (HDR),y
    bcc :+
    jmp TL
:
    sta TMP+1
    lda TMP
    clc
    adc #<(4 + MIN_HEAP_SIZE)
    sta TMP
    lda TMP+1
    adc #>(4 + MIN_HEAP_SIZE)
    bcc :+
    jmp TL
:
    sta TMP+1
    lda rtHdr
    sec
    sbc TMP
    lda rtHdr+1
    sbc TMP+1
    bcs :+                  ; Branch if rtLow < the end
    jmp TL
:

    ; Load the runtime at its own address
    lda #fileNameRdEnd - fileNameRd - 4     ; Without ",p,r"
    ldx #<fileNameRd
    ldy #>fileNameRd
    jsr SETNAM
    lda #LFN
    ldx DEVNUM
    ldy #1
    jsr SETLFS
    lda #0
    jsr LOAD
    bcs NF

    ; Copy its jump table to RT_BASE
    lda rtHdr
    clc
    adc #RTH_SIZE
    sta SRC
    lda rtHdr+1
    adc #0
    sta SRC+1
    lda #<RT_BASE
    sta DST
    lda #>RT_BASE
    sta DST+1
    ldy #0
:   lda (SRC),y             ; The first page
    sta (DST),y
    iny
    bne :-
    inc SRC+1
    inc DST+1
:   lda (SRC),y             ; The rest
    sta (DST),y
    iny
    cpy #<JMPTBL_SIZE
    bne :-
    .assert >JMPTBL_SIZE = 1, error, "the copy expects one full page"

    ; The runtime stack grows down from rtLow, a page boundary
    lda rtHdr+1
    ldy #PRG_HEADER_STACKTOP_H
    sta (HDR),y

    ; The heap's top is rtLow - stack size - 4
    lda rtHdr
    sec
    ldy #PRG_HEADER_STACKSIZE1_L
    sbc (HDR),y
    sta TMP
    lda rtHdr+1
    ldy #PRG_HEADER_STACKSIZE1_H
    sbc (HDR),y
    sta TMP+1
    lda TMP
    sec
    sbc #4
    ldy #PRG_HEADER_STACKSIZE2_L
    sta (HDR),y
    lda TMP+1
    sbc #0
    ldy #PRG_HEADER_STACKSIZE2_H
    sta (HDR),y

    ; The header continues with the runtime's first call
    jmp RT_RUNTIMEERRORINIT

    ; The header was short. If nothing was read, the file is missing.
RE: jsr closeFile
    lda count
    bne BD
    bra NF
NC: jsr closeFile
NF: lda #<msgNotFound
    ldx #>msgNotFound
    bra FL
BD: lda #<msgInvalid
    ldx #>msgInvalid
    bra FL
TL: lda #<msgTooLarge
    ldx #>msgTooLarge

    ; Print "runtime file runtimeN" (except for "too large"), then the
    ; message in A/X, and return to BASIC
FL: sta SRC
    stx SRC+1
    lda #$0e                ; Lower case, for the directive's name
    jsr CHROUT
    lda #13
    jsr CHROUT
    lda SRC
    cmp #<msgTooLarge
    beq :+
    lda #<msgFile
    ldx #>msgFile
    jsr print
:   lda SRC
    ldx SRC+1
    jsr print
    lda #13
    jsr CHROUT

    ; Undo what the header did, as the program's cleanup code does
    lda ZP_SAVEDSTACK
    sta count
    lda 1                   ; Re-enable BASIC ROM
    ora #1
    sta 1
    jsr CLALL
    ldy #PRG_HEADER_CODE_OFFSET_1   ; The page zero backup
    lda (HDR),y
    sta RS+1
    iny
    lda (HDR),y
    sta RS+2
    ldx #0
RS: lda $ffff,x
    sta $04,x
    inx
    cpx #ZP_BACKUP_LEN
    bne RS
    ldx count
    txs
    lda #0
    rts

; This routine prints the null-terminated string in A/X
print:
    sta DST
    stx DST+1
    ldy #0
:   lda (DST),y
    beq :+
    jsr CHROUT
    iny
    bne :-
:   rts

closeFile:
    lda #LFN
    jsr CLOSE
    jmp CLRCHN

magic: .byte RTH_MAGIC0, RTH_MAGIC1, RTH_MAGIC2, RTH_MAGIC3, RT_ABI_VERSION
fileNameRd: .byte .sprintf("runtime%d,p,r", RT_ABI_VERSION)
fileNameRdEnd:
msgFile: .asciiz .sprintf("runtime file runtime%d", RT_ABI_VERSION)
msgNotFound: .asciiz " not found"
msgInvalid: .asciiz " is invalid"
msgTooLarge: .asciiz "program too large for dynamic runtime; try $StaticRuntime"
count: .res 1
rtHdr: .res 2 + RTH_SIZE

loaderEnd:

.reloc

LOADER_SIZE = loaderEnd - loader
LOADER_INIT_L = initL - loader
LOADER_INIT_H = initH - loader
