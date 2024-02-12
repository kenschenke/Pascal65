.include "inputbuf.inc"
.include "cbm_kernal.inc"
.include "c64.inc"
.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp getline
jmp getlineNoEnter

; end of exports
.byte $00, $00, $00

; imports

floatNeg: jmp $0000
invertInt8: jmp $0000
invertInt16: jmp $0000
invertInt32: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

CH_STOP = 3
CH_DEL = 20
CH_ENTER = 13
CH_UNDERSCORE = $af

.proc clearBuf
    lda #0
    ldy #INPUTBUFLEN - 1
L1:
    sta (inputBuf),y
    dey
    bpl L1
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

.proc getCharMega65
L1:
    ldx $d610
    beq L1
    lda #0
    sta $d610
    txa
    rts
.endproc

.proc flushKeyBufMega65
    lda #0
L1:
    ldx $d610
    beq L2
    sta $d610
    bne L1
L2:
    rts
.endproc
.endif

; Read an input line from the keyboard into inputBuf.
; Non-zero is returned in A if the user presses RUN/STOP.
; inputBufUsed contains the number of characters read.
; inputBuf is not zero-terminated.
.proc getlineNoEnter
    jsr clearBuf
.ifdef __MEGA65__
    jsr flushKeyBufMega65
.endif
    ; turn the cursor on
.ifdef __MEGA65__
    lda #CH_UNDERSCORE
    jsr CHROUT
    lda #0
.else
    lda #0
    sta CURS_FLAG
.endif
    ; clear tmp1
    sta tmp1
Loop:
    jsr STOP
    beq StopKey
.ifdef __MEGA65__
    jsr getCharMega65
    jsr _fixAlphaCase
.else
    jsr GETIN
.endif
    cmp #CH_ENTER
    beq EnterKey
    cmp #CH_DEL
    beq DeleteKey
    ; Is the character less than 32?
    cmp #32
    bcc Loop        ; Yes - ignore it
    ; Is the character > 160?
    cmp #160
    bcs Keep        ; Yes - keep it
    ; Is the character > 127?
    cmp #127
    bcs Loop        ; Yes - ignore it
Keep:
    ; Has the user already typed the maximum allowed characters?
    ldx tmp1
    cpx #INPUTBUFLEN
    beq Loop        ; Yes - ignore the key
.ifdef __MEGA65__
    pha
    lda #CH_DEL
    jsr CHROUT
    pla
.endif
    jsr CHROUT
    ldy tmp1
    sta (inputBuf),y
    inc tmp1
.ifdef __MEGA65__
    lda #CH_UNDERSCORE
    jsr CHROUT
.endif
    jmp Loop
DeleteKey:
    ; Delete
    ldx tmp1
    beq Loop        ; Already at start of buffer
    jsr CHROUT
.ifdef __MEGA65__
    jsr CHROUT
    lda #CH_UNDERSCORE
    jsr CHROUT
.endif
    dec tmp1
    ldy tmp1
    lda #' '
    sta (inputBuf),y
    jmp Loop

StopKey:
    ; User hit STOP key
.ifdef __MEGA65__
    lda #CH_DEL
    jsr CHROUT
    lda #1
.else
    lda #1
    sta CURS_FLAG
.endif
    ldx #0
.ifdef RUNTIME
    ; Exit from the program
    jsr exit
.endif
    rts

EnterKey:
    ; User pressed Enter
.ifdef __MEGA65__
    lda #CH_DEL
    jsr CHROUT
.else
    lda #1
    sta CURS_FLAG
    lda #' '
    jsr CHROUT
.endif
.ifdef __MEGA65__
    jsr flushKeyBufMega65
.endif
    lda #0
    ldx tmp1
    stx inputBufUsed
    rts
.endproc

.proc getline
    jsr getlineNoEnter
    cmp #0
    bne L1
    lda #CH_ENTER
    jsr CHROUT
    lda #0
L1:
    rts
.endproc