.include "c64.inc"
.include "runtime.inc"

.export addIrqHandler, irqInit, irqCleanup

.data

; This contains the address of the Kernal IRQ cleanup. This is read from
; $314/$315 during initialization and is restored during program cleanup.
irqKERNAL: .word 0

; The address of the first IRQ handler in the chain. This is returned to
; the caller as the next IRQ handler to JMP to. Each subsequent IRQ handler
; is added to the front.
irqChain: .word 0

.code

.proc irqInit
    sei                     ; Disable CPU interrupts
    lda #%01111111          ; switch off interrupt signals from CIA-1
    sta CIA1_ICR

    and VIC_CTRL1           ; clear most significant bit of VIC's raster register
    sta VIC_CTRL1

    sta CIA1_ICR            ; acknowledge pending interrupts from CIA-1
    sta CIA2_ICR            ; acknowledge pending interrupts from CIA-2

    lda #210                ; set rasterline where interrupt shall occur
    sta VIC_HLINE

    lda IRQVec              ; Store the KERNAL's IRQ handler
    sta irqKERNAL
    lda IRQVec+1
    sta irqKERNAL+1

    lda #<runtimeIrqHandler
    sta IRQVec              ; Set the runtime's handler as the IRQ handler
    sta irqChain            ; Also store it as the first handler in the chain
    lda #>runtimeIrqHandler
    sta IRQVec+1
    sta irqChain+1

    cli                     ; Reenable CPU interrupts
    rts
.endproc

; This routine adds an IRQ handler to the chain.
;
; IMPORTANT: The caller must disable interrupts with sei before
; calling this routine and re-enable interrupts with cli.
; Interrupts should only be re-enabled after the caller has stored
; the next handler. This is in case an IRQ is triggered in between
; the time the caller's handler is installed and before the caller
; has a chance to store the next handler's address.
;
; Inputs:
;
; A/X contain the low/high address of the new handler to be added.
; Y contains the VIC interrupt mask for $D019, as defined on
;    page 151 of the Commodore 64 Programmer's Reference Guide.
;    The mask will be combined with whatever mask is currently in place.
;
; Outputs:
;
; A/X contains the next IRQ handler to call in the chain.
; When the caller's IRQ handler finished it must JMP to this address.
.proc addIrqHandler
    sta ptr1
    sta IRQVec
    stx ptr1+1
    stx IRQVec+1

    tya                     ; Copy caller's interrupt mask to Y
    ora VIC_IMR             ; Combine the current interrupt mask
    sta VIC_IMR

    ; The current value of irqChain needs to be returned in A/X
    ; and the caller's handler (currently in ptr1) needs to be stored
    ; into irqChain.

    lda irqChain            ; Keep the current irqChain on the stack.
    pha
    lda irqChain+1
    pha
    
    lda ptr1                ; Put the caller's IRQ handler into irqChain
    sta irqChain
    lda ptr1+1
    sta irqChain+1

    pla                     ; Pop the old irqChain value off the stack.
    tax
    pla

    rts
.endproc

; This routine is installed as the last handler in the chain. It
; stores 15 in $D019 to unlatch all interrupt bits then passes control
; to the KERNAL's IRQ handler.
.proc runtimeIrqHandler
    lda #%00001111
    sta VIC_IRR
    jmp (irqKERNAL)
.endproc

; This is called during program cleanup and restores the KERNAL's IRQ
; cleanup, originally read from $314/$315.
.proc irqCleanup
    sei                     ; set interrupt bit, make the CPU ignore interrupt requests
    lda #%01111111          ; switch off interrupt signals from CIA-1
    sta CIA1_ICR

    sta CIA1_ICR            ; acknowledge pending interrupts from CIA-1
    sta CIA2_ICR            ; acknowledge pending interrupts from CIA-2

    lda irqKERNAL
    sta IRQVec
    lda irqKERNAL+1
    sta IRQVec+1

    cli                     ; Turn CPU interrupts back on

    lda #0
    sta irqKERNAL
    sta irqKERNAL+1
    sta irqChain
    sta irqChain+1

    rts
.endproc
