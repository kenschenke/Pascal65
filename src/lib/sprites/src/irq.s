.include "cbm_kernal.inc"
.include "c64.inc"
.include "runtime.inc"

.export initSpriteBss, spriteIrqReturn
.export SPR_MASKS, getIrqAddress
.export collisionCallback, isIrqSet, installIrqHandler

.code

initSpriteBss:
    ldx #endbss-startbss-1
    lda #0
:   sta startbss,x
    dex
    bpl :-
    rts

installIrqHandler:
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

    ; Bit 1: Enable sprite/data collision interrupts
    ; Bit 2: Enable sprite/sprite collision interrupts
    ldy #%00000110

    sei                     ; disable CPU interrupts
    jsr rtAddIrqHandler
    sta spriteIrqReturn+1
    stx spriteIrqReturn+2
    cli                     ; clear interrupt flag, allowing the CPU to respond to interrupt requests
    lda #1
    sta isIrqSet
    rts

; This gets the address of the IRQ handler (irqHandler) and 
; puts it on the CPU stack using JSR. The setIrq label pops the address
; back off the STACK to store in the CINV vector.
getIrqAddress:
    jsr setIrq
    ; irqHandler must be the very next line
irqHandler:
    ; Look to see what triggered the interrupt
    lda collisionCallback
    ora collisionCallback+1
    beq spriteIrqReturn
    lda #%10000000
    bit VIC_IRR
    beq spriteIrqReturn
    lda #%00000010                  ; Mask sprite/data collision bit
    bit VIC_IRR
    beq spriteSpriteCollision       ; Branch if no sprite/data collision
    lda VIC_SPR_BG_COLL
    sta collisionBits
    lda #0
    sta spriteOnSprite
    jsr callCollisionCallback

spriteSpriteCollision:
    lda VIC_IRR
    and #%00000100                  ; Mask sprite/sprite collision bit
    beq spriteIrqReturn
    lda VIC_SPR_COLL
    sta collisionBits
    lda #1
    sta spriteOnSprite
    jsr callCollisionCallback

spriteIrqReturn:
    jmp $0000

.proc pushSpriteCallbackPointer
    lda collisionCallback+2
    sta sreg
    lda collisionCallback+3
    sta sreg+1
    lda collisionCallback
    ldx collisionCallback+1
    jmp rtPushEax
.endproc

; Calls the collision callback from the IRQ, with collisionBits and
; spriteOnSprite. The runtime's rtIrqCallBegin and rtIrqCallEnd save and
; restore what the interrupted program was using (see irqcall.s in the
; runtime), so the callback must be declared at the program's outer
; level. Like any library calling a Pascal routine, it pops the
; parameters and calls rtLibStackCleanup after: rtLibCallRoutine leaves
; the caller's nesting level on the CPU stack for it.
.proc callCollisionCallback
    lda collisionCallback
    ora collisionCallback+1
    beq DN
    jsr rtIrqCallBegin
    ; Set up the stack frame header
    jsr pushSpriteCallbackPointer
    jsr rtLibStackHeader
    ; First parameter (collision bits)
    ldx #0
    stx sreg
    stx sreg+1
    lda collisionBits
    jsr rtPushEax
    ; Second parameter (isSpriteToSpriteCollision)
    ldx #0
    stx sreg
    stx sreg+1
    lda spriteOnSprite
    jsr rtPushEax
    ; Call the routine
    jsr pushSpriteCallbackPointer
    jsr rtLibCallRoutine
    jsr rtPopEax            ; The parameters
    jsr rtPopEax
    lda #0                  ; A procedure
    jsr rtLibStackCleanup
    jmp rtIrqCallEnd
DN: rts
.endproc

.data

startbss:
collisionBits: .res 1
collisionCallback: .res 4
spriteOnSprite: .res 1
isIrqSet: .res 1

; Bit is 1 if sprite has target to hit (destination for movement)
endbss:

SPR_MASKS:
    .byte %00000001
    .byte %00000010
    .byte %00000100
    .byte %00001000
    .byte %00010000
    .byte %00100000
    .byte %01000000
    .byte %10000000
