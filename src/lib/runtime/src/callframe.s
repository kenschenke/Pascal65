;
; callframe.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routines that make the generated code shorter: a routine call, reading
; a variable or its address, and an assignment. Each does what code
; generation used to write out in full every time.

.include "runtime.inc"

.export pushFrame, activateFrame, popFrameProc, popFrameFunc, pushVarAddr
.export pushVarInline, assignVar, assignStrVar

.import pushStackFrameHeader, libStackCleanup, calcStackOffset
.import pushAddrStack, pushVar, popeax, pushax, assign, assignString

.code

; This routine pushes a new stack frame header (pushStackFrameHeader) and
; leaves the new frame's base on the CPU stack, low byte first, under the
; caller's return address. activateFrame and a call through a routine
; pointer pull it back off.
; A/X and Y are as for pushStackFrameHeader: the return address of the
; routine call and the routine's nesting level.
.proc pushFrame
    jsr pushStackFrameHeader
    sta tmp1
    stx tmp2
    pla                     ; This routine's return address
    sta tmp3
    pla
    sta tmp4
    lda tmp1
    pha
    lda tmp2
    pha
    lda tmp4
    pha
    lda tmp3
    pha
    rts
.endproc

; This routine makes the stack frame that pushFrame left on the CPU stack
; the current one, and saves the caller's nesting level on the CPU stack
; in its place. The callee's nesting level is passed in A.
.proc activateFrame
    sta tmp1
    pla                     ; This routine's return address
    sta tmp3
    pla
    sta tmp4
    pla
    sta stackP+1
    pla
    sta stackP
    lda currentNestingLevel
    pha
    lda tmp1
    sta currentNestingLevel
    lda tmp4
    pha
    lda tmp3
    pha
    rts
.endproc

; These routines remove the stack frame after a call to a procedure or
; a function (libStackCleanup).
.proc popFrameProc
    lda #0
    jmp libStackCleanup
.endproc

.proc popFrameFunc
    lda #1
    jmp libStackCleanup
.endproc

; This routine pushes the address of a variable. Its nesting level is
; passed in A and its offset in its stack frame in X.
.proc pushVarAddr
    jsr calcStackOffset
    lda ptr1
    ldx ptr1+1
    jmp pushAddrStack
.endproc

; This routine pushes the value of a variable (pushVar). Its nesting level,
; its offset in its stack frame and its type are the three bytes after
; the JSR, and it returns past them.
.proc pushVarInline
    pla                     ; The return address, the JSR's last byte
    sta tmp3
    pla
    sta tmp4
    ldy #3
    lda (tmp3),y            ; type
    pha
    dey
    lda (tmp3),y            ; offset
    tax
    dey
    lda (tmp3),y            ; level
    sta tmp1
    lda tmp3                ; Return past the three bytes
    clc
    adc #3
    sta tmp3
    bcc :+
    inc tmp4
:   pla
    tay
    lda tmp4
    pha
    lda tmp3
    pha
    lda tmp1
    jmp pushVar
.endproc

; This routine assigns the value under the variable's address on the
; runtime stack to the variable, which isn't a string (assign). The
; value's type is passed in A and the variable's in X.
.proc assignVar
    pha
    txa
    pha
    jsr popeax              ; The variable's address
    sta ptr1
    stx ptr1+1
    pla
    tax
    pla
    jmp assign
.endproc

; This routine assigns the value under the variable's address on the
; runtime stack to the string variable (assignString). The value's type
; is passed in A.
.proc assignStrVar
    pha
    jsr popeax              ; The variable's address
    sta ptr1
    stx ptr1+1
    jsr popeax              ; The value
    sta tmp1
    stx tmp2
    pla
    jsr pushax              ; The value's type
    lda ptr1
    ldx ptr1+1
    jsr pushax              ; The variable's address
    lda tmp1
    ldx tmp2
    jmp assignString
.endproc
