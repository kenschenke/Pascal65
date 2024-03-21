.include "cbm_kernal.inc"
.include "runtime.inc"

.export getkey, getkeynowait

.import returnVal

getkey:
    lda #1
    jsr rtGetKey
    jmp DN

getkeynowait:
    lda #0
    jsr rtGetKey

DN:
    ldx #0
    stx sreg
    stx sreg + 1
    jmp returnVal
