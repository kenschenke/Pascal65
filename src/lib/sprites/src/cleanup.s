.include "c64.inc"

.export cleanupSpriteLibrary

.import spriteIrqReturn

.proc cleanupSpriteLibrary
    ; Turn off all sprites
    lda #0
    sta VIC_SPR_ENA

    sei                     ; set interrupt bit, make the CPU ignores interrupt requests
    lda #%01111111          ; switch off interrupt signals from CIA-1
    sta CIA1_ICR

    sta CIA1_ICR            ; acknowledge pending interrupts from CIA-1
    sta CIA2_ICR            ; acknowledge pending interrupts from CIA-2

    lda spriteIrqReturn+1
    sta IRQVec
    lda spriteIrqReturn+2
    sta IRQVec+1

    cli                     ; Turn CPU interrupts back on

    rts
.endproc
