.include "c64.inc"
.include "runtime.inc"

.export initAnimLibrary, setIrq

.import initAnimBss, animIrqReturn, getIrqAddress

initAnimLibrary:
    jsr initAnimBss

    jmp getIrqAddress       ; Get address of IRQ handler on CPU stack
setIrq:
    pla                     ; Pop address of CPU handler off CPU stack and add 1
    clc
    adc #1
    sta tmp1
    pla
    adc #0
    tax
    lda tmp1

    ; Bit 0: Raster interrupt
    ldy #%00000001

    sei                     ; disable CPU interrupts
    jsr rtAddIrqHandler
    sta animIrqReturn+1
    stx animIrqReturn+2
    cli                     ; clear interrupt flag, allowing the CPU to respond to interrupt requests
    rts
