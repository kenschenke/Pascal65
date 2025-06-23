;
; libutil.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Utility routines for shared libraries to process
; parameters and return values.

.include "runtime.inc"

.export storeVarParam, loadParam, returnVal
.export libStackHeader, libCallRoutine, libStackCleanup

.import pushStackFrameHeader, popeax, pusheax, incsp4

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

; This routine pushes a stack frame header in preparation
; for a library to call a Pascal routine.
.proc libStackHeader
    ; Save the return address because the new stack frame header
    ; has to go under the return address on the CPU stack.
    pla
    sta tmp3
    pla
    sta tmp4
    ; Pop the routine pointer off the stack
    jsr popeax
    ldy sreg                    ; nesting level
    lda #0                      ; $0000 for return address for now
    tax
    jsr pushStackFrameHeader
    pha                         ; Save the new stack frame ptr on the stack.
    txa                         ; libCallRoutine pops it back off
    pha
    lda tmp4                    ; Put the return address back on the stack
    pha
    lda tmp3
    pha
    rts
.endproc

; This routine removes a stack frame header from the runtime stack
; and restores the caller's stack frame pointer.
; Caller passes 0 in A if the routine was a procedure or 1 if a function.
; If 1, the return value is left on the runtime stack.
.proc libStackCleanup
    ; Store the flag to indicate whether or not to leave the return value
    sta tmp1

    ; Save the caller's return address
    pla
    sta tmp3
    pla
    sta tmp4

    ; Restore the caller's nesting level
    pla
    sta currentNestingLevel

    ; Put the caller's return address back on the stack
    lda tmp4
    pha
    lda tmp3
    pha

    ; Restore the caller's stack frame base pointer
    jsr popeax
    sta stackP
    stx stackP+1

    ; Pop the stack link off the stack
    jsr incsp4

    ; Pop the dynamic link off the stack
    jsr incsp4

    ; Load a 0 or 1 to indicate whether or not to leave
    ; the return value on the runtime stack (if it was a function).
    lda tmp1
    bne :+
    jsr incsp4
:   rts
.endproc

; This routine calls a Pascal routine from a library
.proc libCallRoutine
    ; Pop the return address off the CPU stack
    pla
    sta tmp3
    pla
    sta tmp4
    ; Pop the routine pointer off the stack
    jsr popeax
    sta tmp1
    stx tmp2
    ; Pop the new stack frame header pointer off the stack
    ; and put in stackP
    pla
    sta stackP+1
    pla
    sta stackP
    ; Copy the stack frame header pointer to ptr1, subtracting 8.
    ; This is the location of the return address on the stack
    ; when returning from the Pascal routine.
    lda stackP
    sec
    sbc #8
    sta ptr1
    lda stackP+1
    sbc #0
    sta ptr1+1
    ; Store the return address in the stack frame header
    ldy #0
    lda tmp3
    sta (ptr1),y
    iny
    lda tmp4
    sta (ptr1),y
    lda currentNestingLevel
    pha
    lda sreg
    sta currentNestingLevel
    jmp (tmp1)                  ; Jump into the routine
.endproc
