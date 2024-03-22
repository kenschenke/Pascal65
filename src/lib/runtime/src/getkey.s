.include "runtime.inc"

.export clearKeyBuf, getKey

.proc clearKeyBuf
.ifdef __MEGA65__
    lda #0
L1:
    ldx $d610
    beq L2
    sta $d610
    bne L1
L2:
.endif
    rts
.endproc

.ifdef __MEGA65__
.proc _fixAlphaCase
;     if (c >= 97 && c <= 122) c -= 32;
;     else if (c >= 65 && c <= 90) c += 128;
    cmp #96
    bcc L1      ; branch if char <= 96
    cmp #122
    bcs L2      ; branch if char > 122
    sec
    sbc #32     ; subtract 32 from char
    jmp L2
L1:
    cmp #64
    bcc L2      ; branch if char <= 64
    cmp #90
    bcs L2      ; branch if char > 90
    clc
    adc #128    ; add 128 to char
L2:
    ldx #0
    rts
.endproc
.endif

; If A is 0 on entry then the routine will only return
; a keystroke from the buffer, otherwise 0 is returned.
; If A is non-zero on entry then the routine will return
; a keystroke from the buffer or wait until a key is pressed.
;
; The key is returned in A.
.ifdef __MEGA65__
getKey:
    cmp #0
    beq NW
LP: lda $d610
    beq LP
    bne DN
NW: lda $d610
DN: ldx #0
    stx $d610
    jmp _fixAlphaCase
.else
getKey:
    cmp #0
    beq NW
LP: jsr GETIN
    cmp #0
    beq LP
    bne DN
NW: jmp GETIN
DN: rts
.endif