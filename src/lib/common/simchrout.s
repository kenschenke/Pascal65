.import pushax
.importzp tmp1

.export simCHROUT

pvwrite = $fff7

; Output a single character in Sim6502
; Character to output is in A
; X/Y are preserved
; tmp1 is clobbered
.proc simCHROUT
.ifdef __SIM6502__
    sta tmp1
    tya
    pha
    txa
    pha
    lda #1          ; FD 1 (stdout)
    ldx #0
    jsr pushax
    lda #<tmp1
    ldx #>tmp1
    jsr pushax
    lda #1          ; Output 1 character
    ldx #0
    jsr pvwrite
    pla
    tax
    pla
    tay
    rts
.endif
.endproc
