.include "c64.inc"

.export initSpriteLibrary, setIrq

.import initSpriteBss, spriteIrq, spriteIrqReturn, getIrqAddress

.import hastarget

initSpriteLibrary:
    jsr initSpriteBss

    lda #0
    sta VIC_SPR_ENA         ; Disable all sprites

    sei                     ; set interrupt bit, make the CPU ignores interrupt requests
    lda #%01111111          ; switch off interrupt signals from CIA-1
    sta CIA1_ICR

    and VIC_CTRL1           ; clear most significant bit of VIC's raster register
    sta VIC_CTRL1

    sta CIA1_ICR            ; acknowledge pending interrupts from CIA-1
    sta CIA2_ICR            ; acknowledge pending interrupts from CIA-2

    lda #210                ; set rasterline where interrupt shall occur
    sta VIC_HLINE

    lda IRQVec
    sta spriteIrqReturn+1
    lda IRQVec+1
    sta spriteIrqReturn+2
    jmp getIrqAddress       ; Get address of IRQ handler on CPU stack
setIrq:
    pla                     ; Pop address of CPU handler off CPU stack and add 1
    clc
    adc #1
    sta IRQVec              ; set interrupt vectors, pointing to interrupt service routine
    pla
    adc #0
    sta IRQVec+1

    lda #%00000001          ; enable raster interrupt signals from VIC
    sta VIC_IMR

    cli                     ; clear interrupt flag, allowing the CPU to respond to interrupt requests
    rts

; irq:
;     lda #$7                 ; change border color to yellow
;     sta $d020

;     ldx #$90                ; empty loop to do nothing for under half a millisecond
; :   dex
;     bne :-

;     lda #$0
;     sta $d020               ; change border color to black

;     asl $d019               ; acknowledge the interrupt by clearing the VIC's interrupt flag

; old_interrupt:
;     jmp $0000               ; jump to standard interrupt handler
