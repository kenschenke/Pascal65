.export clearKeyBuf

KEYBUF = $d610

.proc clearKeyBuf
    lda #0
L1: ldx KEYBUF
    beq L2
    sta KEYBUF
    bne L1
L2: rts
.endproc
