.include "runtime.inc"
.include "c64.inc"

.export initRasterCb, setRasterCb

.data

rasterCb: .dword 0

.code

.proc initRasterCb
    ldx #3
    lda #0
    sta irqReturn+1
    sta irqReturn+2
:   sta rasterCb,x
    dex
    bpl :-
    rts
.endproc

setRasterCb:
    lda #0
    jsr rtLibLoadParam
    sei
    sta rasterCb
    stx rasterCb+1
    lda sreg
    sta rasterCb+2
    lda sreg+1
    sta rasterCb+3
    cli

    ; If this IRQ handler has already been installed, skip doing it again.
    lda irqReturn+1
    ora irqReturn+2
    bne DN

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
    sta irqReturn+1
    stx irqReturn+2
    cli                     ; clear interrupt flag, allowing the CPU to respond to interrupt requests
DN: rts

getIrqAddress:
    jsr setIrq
    ; irqHandler must be the very next line
irqHandler:
    lda rasterCb
    ora rasterCb+1
    beq irqReturn

    lda #%10000000
    bit VIC_IRR
    beq irqReturn
    lda #%00000001
    bit VIC_IRR
    beq irqReturn

    jsr pushRasterCb
    jsr rtLibStackHeader

    jsr pushRasterCb
    jsr rtLibCallRoutine

irqReturn:
    jmp $0000

.proc pushRasterCb
    lda rasterCb+2
    sta sreg
    lda rasterCb+3
    sta sreg+1
    lda rasterCb
    ldx rasterCb+1
    jmp rtPushEax
.endproc
