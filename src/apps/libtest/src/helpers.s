.import eqInt16, geInt16, gtInt16, leInt16, ltInt16
.import addInt16, divInt16, modInt16, multInt16, subInt16
.import writebool, writechar
.import intOp1, intOp2
.import popa, popax
.export _testLt, _testEq, _testGt, _testLe, _testGe
.export _testAddInt16, _testDivInt16, _testSubInt16, _testModInt16, _testMultInt16
.export _testWriteBool, _testWriteChar

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
    jmp writechar
.endproc

.proc _testWriteBool
    tax
    jsr popa
    jmp writebool
.endproc
