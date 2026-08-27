;
; rtstack.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Runtime stack

.include "zeropage.inc"
.include "4510macros.inc"

.export initRuntimeStack, rtPopA, rtPopAX, rtPopQ, rtPushA, rtPushAX, rtPushQ
.export rtPushQZero, rtPushBlock, rtPopBlock

.bss

incNum: .res 1

.code

; Initialize the runtime stack pointer
.proc initRuntimeStack
    ; Initialize SP to $60000
    lda #6
    sta stackPointer+2
    lda #0
    sta stackPointer
    sta stackPointer+1
    sta stackPointer+3
    rts
.endproc

; This routine decrements the stack pointer by the amount in A.
; This is used when pushing a value onto the stack.
.proc decStackPointer
    sta incNum
    lda stackPointer
    sec
    sbc incNum
    sta stackPointer
    bcs :+
    lda stackPointer+1
    sbc #0
    sta stackPointer+1
    lda stackPointer+2
    sbc #0
    sta stackPointer+2
    bcs :+
    lda stackPointer+3
    sbc #0
    sta stackPointer+3
:   rts
.endproc

; This routine increments the stack pointer by the amount in A.
; This is used when popping a value off the stack.
.proc incStackPointer
    sta incNum
    lda stackPointer
    clc
    adc incNum
    sta stackPointer
    bcc :+
    lda stackPointer+1
    adc #0
    sta stackPointer+1
    bcc :+
    lda stackPointer+2
    adc #0
    sta stackPointer+2
    bcc :+
    lda stackPointer+3
    adc #0
    sta stackPointer+3
:   rts
.endproc

; Pop one byte off the runtime stack into A
.proc rtPopA
    ldz #0
    nop
    lda (stackPointer),z
    pha
    lda #1
    jsr incStackPointer
    pla
    rts
.endproc

; Pop two bytes off the runtime stack into A/X
; X then A is popped off the stack
.proc rtPopAX
    ldz #1
    nop
    lda (stackPointer),z
    tax
    dez
    nop
    lda (stackPointer),z
    pha
    lda #2
    jsr incStackPointer
    pla
    rts
.endproc

; Pop four bytes off the runtime stack into A, X, Y, and Z
; Z, Y, X, then A are popped off the stack in that order
.proc rtPopQ
    ldz #3
    nop
    lda (stackPointer),z
    pha
    dez
    nop
    lda (stackPointer),z
    tay
    dez
    nop
    lda (stackPointer),z
    tax
    dez
    nop
    lda (stackPointer),z
    pha
    lda #4
    jsr incStackPointer
    pla
    plz
    rts
.endproc

; Push the A register onto the runtime stack
.proc rtPushA
    pha
    lda #1
    jsr decStackPointer
    pla
    ldz #0
    nop
    sta (stackPointer),z
    rts
.endproc

; Push the A and X registers onto the runtime stack
; A then X is pushed onto the stack in that order
.proc rtPushAX
    pha
    lda #2
    jsr decStackPointer
    ldz #1
    txa
    nop
    sta (stackPointer),z
    pla
    dez
    nop
    sta (stackPointer),z
    rts
.endproc

; Push A, X, Y, and Z registers onto the runtime stack
; A, X, Y, then Z are pushed onto the stack in that order
.proc rtPushQ
    pha
    lda #4
    jsr decStackPointer
    pla
    phz
    ldz #0
    nop
    sta (stackPointer),z
    txa
    inz
    nop
    sta (stackPointer),z
    tya
    inz
    nop
    sta (stackPointer),z
    pla
    inz
    nop
    sta (stackPointer),z
    rts
.endproc

.proc rtPushQZero
    lda #0
    tax
    tay
    taz
    jmp rtPushQ
.endproc

; This routine pushes a block onto the stack.
; The number of bytes is passed in A.
.proc rtPushBlock
    jmp decStackPointer
.endproc

; This routine pops a block from the stack.
; The number of bytes is passed in A.
.proc rtPopBlock
    jmp incStackPointer
.endproc
