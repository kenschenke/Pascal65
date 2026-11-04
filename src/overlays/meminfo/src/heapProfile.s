;
; heapProfile.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; heapProfile routine

.include "ast.inc"
.include "tree.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export heapProfile

PROFILE_MAX = 64            ; block sizes below this get their own counter
PAIRS_PER_LINE = 6

.data

strHeader: .asciiz "Allocated blocks by size (size:count)"
strBig: .asciiz "Blocks of 64 or more: "
strBytes: .asciiz " bytes: "
strFree: .asciiz "Free blocks: "
strStructs: .asciiz "AST structures (size, count):"
strKey: .asciiz "Press a key"
strKinds: .asciiz "Types by kind (kind:count)"
strCloned: .asciiz "Types with the cloned flag: "
strNote: .asciiz "(names and structs of equal size share a count)"

strDecl: .asciiz "decl"
strStmt: .asciiz "stmt"
strExpr: .asciiz "expr"
strType: .asciiz "type"
strParam: .asciiz "param_list"
strSymbol: .asciiz "symbol"
strTree: .asciiz "treenode"

NUM_STRUCTS = 7

structSizes:
    .byte .sizeof(decl), .sizeof(stmt), .sizeof(expr), .sizeof(type)
    .byte .sizeof(param_list), .sizeof(symbol), .sizeof(TREENODE)

structNames:
    .word strDecl, strStmt, strExpr, strType, strParam, strSymbol, strTree

.bss

bankNum: .res 1
matPtr: .res 4
blkPtr: .res 4
intBuf: .res 10
hist: .res PROFILE_MAX * 2
bigCount: .res 2
bigBytes: .res 4
freeCount: .res 2
kindHist: .res 64
clonedCount: .res 2
curSize: .res 1
perLine: .res 1
structIdx: .res 1

.code

; This routine walks the memory allocation table and prints a histogram of
; the sizes of the allocated blocks, then the counts for each AST structure.
; Waits for a key before returning.
.proc heapProfile
    lda #0
    ldx #PROFILE_MAX * 2 - 1
:   sta hist,x
    dex
    bpl :-
    ldx #63
:   sta kindHist,x
    dex
    bpl :-
    sta bigCount
    sta bigCount+1
    sta bigBytes
    sta bigBytes+1
    sta bigBytes+2
    sta bigBytes+3
    sta freeCount
    sta freeCount+1
    sta clonedCount
    sta clonedCount+1
    sta intOp2                  ; intOp1/intOp2 are added to bigBytes as 32 bits
    sta intOp2+1

    ; Loop through the banks
    sta bankNum
BN: lda bankNum
    jsr getMemHeapForBank
    jsr isQZero
    bne :+
    jmp Print
:   stq matPtr
    ldq heapBottom
    stq blkPtr

    ; Loop through the MAT entries
L1: ldq matPtr
    stq ptr1

    ; Is the current MAT entry zero?
    ldz #0
:   nop
    lda (ptr1),z
    bne L2
    inz
    cpz #2
    bne :-
    inc bankNum
    bra BN

    ; Is the MAT entry allocated?
L2: ldz #1
    nop
    lda (ptr1),z
    bpl L3                      ; Branch if not allocated
    and #$7f
    sta intOp1+1
    dez
    nop
    lda (ptr1),z
    sta intOp1

    lda intOp1+1
    bne Big
    lda intOp1
    cmp #PROFILE_MAX
    bcs Big
    cmp #.sizeof(type)
    bne :+
    jsr countType
:   lda intOp1
    asl
    tax
    inc hist,x
    bne :+
    inc hist+1,x
:   jmp L4

Big:
    inc bigCount
    bne :+
    inc bigCount+1
:   ldq bigBytes
    clc
    adcq intOp1
    stq bigBytes
    jmp L4

L3: inc freeCount
    bne :+
    inc freeCount+1
:

    ; Move to the next MAT entry
L4:
    ; Add this entry's size to the block address
    ldq matPtr
    stq ptr1
    ldz #0
    nop
    lda (ptr1),z
    sta intOp1
    inz
    nop
    lda (ptr1),z
    and #$7f
    sta intOp1+1
    lda #0
    sta intOp2
    sta intOp2+1
    ldq blkPtr
    clc
    adcq intOp1
    stq blkPtr
    lda #2
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq matPtr
    sec
    sbcq intOp32
    stq matPtr
    jmp L1

Print:
    lda #<strHeader
    ldx #>strHeader
    jsr putLine

    ; Print "size:count" for each size that has at least one block
    lda #1
    sta curSize
    lda #0
    sta perLine
P1: lda curSize
    asl
    tax
    lda hist,x
    ora hist+1,x
    beq P3

    lda curSize
    sta intOp1
    lda #0
    sta intOp1+1
    jsr putInt
    lda #':'
    jsr CHROUT
    jsr loadHistCount
    jsr putInt
    lda #' '
    jsr CHROUT
    inc perLine
    lda perLine
    cmp #PAIRS_PER_LINE
    bcc P3
    lda #13
    jsr CHROUT
    lda #0
    sta perLine
P3: inc curSize
    lda curSize
    cmp #PROFILE_MAX
    bne P1

    lda perLine
    beq :+
    lda #13
    jsr CHROUT

    ; Blocks too big for the histogram
:   lda #<strBig
    ldx #>strBig
    jsr putStr
    lda bigCount
    sta intOp1
    lda bigCount+1
    sta intOp1+1
    jsr putInt
    lda #<strBytes
    ldx #>strBytes
    jsr putStr
    ldq bigBytes
    stq intOp1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt32
    jsr putBuf
    lda #13
    jsr CHROUT

    lda #<strFree
    ldx #>strFree
    jsr putStr
    lda freeCount
    sta intOp1
    lda freeCount+1
    sta intOp1+1
    jsr putInt
    lda #13
    jsr CHROUT

    ; Print the AST structures. The sizes come from the structure
    ; definitions so this stays correct when they change.
    lda #<strStructs
    ldx #>strStructs
    jsr putLine
    lda #0
    sta structIdx
S1: lda structIdx
    asl
    tax
    lda structNames,x
    pha
    lda structNames+1,x
    tax
    pla
    jsr putStr
    lda #' '
    jsr CHROUT
    ldx structIdx
    lda structSizes,x
    sta intOp1
    sta curSize
    lda #0
    sta intOp1+1
    jsr putInt
    lda #' '
    jsr CHROUT
    jsr loadHistCount
    jsr putInt
    lda #13
    jsr CHROUT
    inc structIdx
    lda structIdx
    cmp #NUM_STRUCTS
    bne S1

    lda #<strNote
    ldx #>strNote
    jsr putLine
    lda #<strKey
    ldx #>strKey
    jsr putLine

    ; Wait for a key
:   jsr GETIN
    beq :-

    ; Second page: breakdown of the type structures by kind
    lda #147
    jsr CHROUT
    lda #<strKinds
    ldx #>strKinds
    jsr putLine
    lda #0
    sta curSize
    sta perLine
K1: lda curSize
    asl
    tax
    lda kindHist,x
    ora kindHist+1,x
    beq K3
    lda curSize
    sta intOp1
    lda #0
    sta intOp1+1
    jsr putInt
    lda #':'
    jsr CHROUT
    lda curSize
    asl
    tax
    lda kindHist,x
    sta intOp1
    lda kindHist+1,x
    sta intOp1+1
    jsr putInt
    lda #' '
    jsr CHROUT
    inc perLine
    lda perLine
    cmp #PAIRS_PER_LINE
    bcc K3
    lda #13
    jsr CHROUT
    lda #0
    sta perLine
K3: inc curSize
    lda curSize
    cmp #32
    bne K1
    lda #13
    jsr CHROUT
    lda #<strCloned
    ldx #>strCloned
    jsr putStr
    lda clonedCount
    sta intOp1
    lda clonedCount+1
    sta intOp1+1
    jsr putInt
    lda #13
    jsr CHROUT
    lda #<strKey
    ldx #>strKey
    jsr putLine
:   jsr GETIN
    beq :-
    rts
.endproc

; Counts the type structure whose MAT entry is at ptr1 by its kind and
; whether it has the cloned flag.
.proc countType
    ldq blkPtr
    stq ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #32
    bcs DN
    asl
    tax
    inc kindHist,x
    bne :+
    inc kindHist+1,x
:   ldz #type::flags
    nop
    lda (ptr2),z
    and #TYPE_FLAG_ISCLONED
    beq DN
    inc clonedCount
    bne DN
    inc clonedCount+1
DN: rts
.endproc

; Loads the histogram count for curSize into intOp1
.proc loadHistCount
    lda curSize
    asl
    tax
    lda hist,x
    sta intOp1
    lda hist+1,x
    sta intOp1+1
    rts
.endproc

; Prints the null-terminated string at A/X
.proc putStr
    sta ptr1
    stx ptr1+1
    ldy #0
:   lda (ptr1),y
    beq :+
    jsr CHROUT
    iny
    bne :-
:   rts
.endproc

; Prints the null-terminated string at A/X followed by a carriage return
.proc putLine
    jsr putStr
    lda #13
    jsr CHROUT
    rts
.endproc

; Prints intBuf
.proc putBuf
    ldx #0
:   lda intBuf,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   rts
.endproc

; Prints the 16-bit value in intOp1
.proc putInt
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    jmp putBuf
.endproc
