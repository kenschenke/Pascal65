.import eqInt16, geInt16, gtInt16, leInt16, ltInt16
.import addInt16, divInt16, modInt16, multInt16, subInt16
.import writeBool, writeChar, writeInt16, readInt16
.import intOp1, intOp2, intBuf
.import getline
.import popa, popax
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.import spcl32768
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.importzp ptr1, ptr2

.export _testLt, _testEq, _testGt, _testLe, _testGe, _testGetLine
.export _testAddInt16, _testDivInt16, _testSubInt16, _testModInt16, _testMultInt16
.export _testWriteBool, _testWriteChar, _testWriteInt16, _testReadInt16

.proc _testAddInt16
    sta intOp2
    stx intOp2 + 1
    jsr popax
    sta intOp1
    stx intOp1 + 1
    jsr addInt16
    lda intOp1
    ldx intOp1 + 1
    rts
.endproc

.proc _testDivInt16
    sta intOp2
    stx intOp2 + 1
    jsr popax
    sta intOp1
    stx intOp1 + 1
    jsr divInt16
    lda intOp1
    ldx intOp1 + 1
    rts
.endproc

.proc _testEq
    sta intOp2
    stx intOp2 + 1
    jsr popax
    sta intOp1
    stx intOp1 + 1
    jmp eqInt16
.endproc

.proc _testGe
    sta intOp2
    stx intOp2 + 1
    jsr popax
    sta intOp1
    stx intOp1 + 1
    jmp geInt16
.endproc

.proc _testGetLine
    jmp getline
.endproc

.proc _testGt
    sta intOp2
    stx intOp2 + 1
    jsr popax
    sta intOp1
    stx intOp1 + 1
    jmp gtInt16
.endproc

.proc _testLe
    sta intOp2
    stx intOp2 + 1
    jsr popax
    sta intOp1
    stx intOp1 + 1
    jmp leInt16
.endproc

.proc _testLt
    sta intOp2
    stx intOp2 + 1
    jsr popax
    sta intOp1
    stx intOp1 + 1
    jmp ltInt16
.endproc

.proc _testModInt16
    sta intOp2
    stx intOp2 + 1
    jsr popax
    sta intOp1
    stx intOp1 + 1
    jsr modInt16
    lda intOp1
    ldx intOp1 + 1
    rts
.endproc

.proc _testMultInt16
    sta intOp2
    stx intOp2 + 1
    jsr popax
    sta intOp1
    stx intOp1 + 1
    jsr multInt16
    lda intOp1
    ldx intOp1 + 1
    rts
.endproc

.proc _testSubInt16
    sta intOp2
    stx intOp2 + 1
    jsr popax
    sta intOp1
    stx intOp1 + 1
    jsr subInt16
    lda intOp1
    ldx intOp1 + 1
    rts
.endproc

.proc _testWriteChar
    tax
    jsr popa
    jmp writeChar
.endproc

.proc _testWriteBool
    tax
    jsr popa
    jmp writeBool
.endproc

.proc _testReadInt16
    sta ptr2
    stx ptr2 + 1

    lda #<intBuf
    sta ptr1
    lda #>intBuf
    sta ptr1 + 1

    ; set intBuf to 0s
    lda #0
    ldy #6
L1:
    sta (ptr1),y
    dey
    bne L1

    ; copy caller's string to buffer
    ldy #0
L2:
    lda (ptr2),y
    beq L3
    sta (ptr1),y
    iny
    jmp L2

L3:
    jsr readInt16
    lda intOp1
    ldx intOp1 + 1
    rts
.endproc

.proc _testWriteInt16
    pha
    jsr popax
    sta intOp1
    stx intOp1 + 1
    pla
    jmp writeInt16
.endproc

