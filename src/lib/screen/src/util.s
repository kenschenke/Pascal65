.include "runtime.inc"

.export loadParam, returnVal, storeVarParam, calcScreen, toScreenCode, is80Cols, is50Rows

.import reverse

; This routine calculates the address of a parameter and
; leaves it in ptr1.
; parameter number (0-based) in A.
.proc calcParam
    tax                 ; Parameter number in X
    lda stackP
    sec
    sbc #20             ; first parameter is 20 bytes below stack frame ptr
    sta ptr1
    lda stackP + 1
    sbc #0
    sta ptr1 + 1
    cpx #0
    beq DN
:   lda ptr1
    sec
    sbc #4
    sta ptr1
    lda ptr1 + 1
    sbc #0
    sta ptr1 + 1
    dex
    bne :-
DN: rts
.endproc

; Stores the value into a Var parameter.
; Value in A/X/sreg
; Parameter number (0-based) in Y
.proc storeVarParam
    pha
    txa
    pha
    tya
    jsr calcParam
    ldy #0
    lda (ptr1),y
    sta ptr2
    iny
    lda (ptr1),y
    sta ptr2 + 1
    pla
    sta (ptr2),y
    dey
    pla
    sta (ptr2),y
    ldy #2
    lda sreg
    sta (ptr2),y
    iny
    lda sreg + 1
    sta (ptr2),y
    nop
    nop
    nop
    nop
    nop
    rts
.endproc

; This routine loads a parameter off the runtime stack
; into A/X/sreg.
;
; Parameter number in A (0-based)
.proc loadParam
    jsr calcParam
    ldy #3
    lda (ptr1),y
    sta sreg + 1
    dey
    lda (ptr1),y
    sta sreg
    dey
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    rts
.endproc

; This routine stores the value in A/X/sreg into the
; return value spot in the current stack frame.
.proc returnVal
    pha
    lda stackP
    sec
    sbc #4
    sta ptr1
    lda stackP + 1
    sbc #0
    sta ptr1 + 1
    ldy #0
    pla
    sta (ptr1),y
    txa
    iny
    sta (ptr1),y
    lda sreg
    iny
    sta (ptr1),y
    lda sreg + 1
    iny
    sta (ptr1),y
    rts
.endproc

; Calculate screen or color RAM address
; Column in X, Row in Y
; Base address is expected in ptr1
; Address returned in A/X
.proc calcAddr
    jsr is80Cols
    beq C4                  ; branch if 40 columns
    lda #80                 ; assume 80 columns
    bne SC
C4: lda #40
SC: sta tmp1
    dey                     ; Row is 1-based, so subtract one
LR: dey
    bmi DR                  ; branch if done counting rows
    lda ptr1
    clc
    adc tmp1
    sta ptr1
    bcc LR
    inc ptr1 + 1
    jmp LR
DR: dex
    txa
    clc
    adc ptr1
    sta ptr1
    bcc :+
    inc ptr1 + 1
:   lda ptr1
    ldx ptr1 + 1
    rts
.endproc

; Column in X, Row in Y
; Rows and columns are 1-based
; Address returned in A/X
.proc calcScreen
    lda #0
    sta ptr1
.ifdef __MEGA65__
    lda #8
.else
    lda #4
.endif
    sta ptr1 + 1
    jmp calcAddr
.endproc

; Column in X, Row in Y
; Address returned in A/X
.proc calcColorMem
    lda #0
    sta ptr1
.ifdef __MEGA65__
    lda #0
.else
    lda #$d8
.endif
    sta ptr1 + 1
    jmp calcAddr
.endproc

; Convert PETSCII to a screen code
; PETSCII is passed in A and screen code returned in A
; Code from https://codebase64.org/doku.php?id=base:petscii_to_screencode
.proc toScreenCode
    cmp #$20
    bcc RV              ; branch is A < 32 (reverse character)

    cmp #$60
    bcc B1              ; branch if A < 96 (clear bits 6 and 7)

    cmp #$80
    bcc B2              ; branch if A < 128

    cmp #$a0
    bcc B3              ; branch if A < 160

    cmp #$c0
    bcc B4              ; branch if A < 192

    cmp #$ff
    bcc RV              ; branch if A < 255
    
    lda #$7e            ; set A = 126
    bne DN

B2: and #$5f            ; clear bits 5 and 7
    bne DN

B3: ora #$40            ; if A between 128 and 159, set bit 6
    bne DN

B4: eor #$c0            ; if A between 160 and 191, flip bits 6 and 7
    bne DN

B1: and #$3f            ; clear bits 6 and 7
    bpl DN

RV: eor #$80            ; flip bit 7
DN: ora reverse
    rts
.endproc

; Returns non-zero in A if screen is 80 columns
.proc is80Cols
    lda $d031
    and #$80
    rts
.endproc

; Returns non-zero in A if screen is 50 rows
.proc is50Rows
    lda $d031
    and #8
    rts
.endproc
