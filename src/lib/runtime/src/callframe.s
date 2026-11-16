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

.export pushFrame, pushVarAddr
.export pushVarInline, assignVar, assignStrVar
.export pushFrameCall, callRoutine, callLibRoutine, popFrameN
.export pushFrameCall2, callRoutine2, callLibRoutine2
.export branchIfFalse, branchIfTrue, convertInline, convertStrParam
.export pushRetAddr, popAndFree, pushByteInline, pushIntInline
.export pushGlobalInline, pushGlobalAddr, assignInline, assignStrInline
.export compInline, addInline, subInline

.import pushStackFrameHeader, libStackCleanup, calcStackOffset
.import pushAddrStack, pushVar, popeax, pushax, assign, assignString
.import incsp4
.import popToIntOp1And2, pushFromIntOp1And2, convertType, convertString
.import heapFree, pusheax, pushByteStack, pushIntStack
.import comp, add, subtract

.code

; This routine pushes a new stack frame header (pushStackFrameHeader) and
; leaves the new frame's base on the CPU stack, low byte first, under the
; caller's return address. callRoutine and a call through a routine
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

; This routine is pushFrame for a routine call made by callRoutine or
; callLibRoutine, which store the return address. The routine's nesting
; level is passed in Y.
.proc pushFrameCall
    lda #0
    tax
    jmp pushFrame
.endproc

; This routine is pushFrameCall for a routine at nesting level 2: one
; declared in the program, or a library routine.
.proc pushFrameCall2
    ldy #2
    bne pushFrameCall
.endproc

; These routines call a routine. The routine's nesting level and its
; address (low byte first) are the three bytes after the JSR, or for
; callRoutine2 and callLibRoutine2, which call a routine at level 2, only
; its address. They make the stack frame that pushFrame left on the CPU
; stack the current one, save the caller's nesting level on the CPU stack
; (the generated code once did this itself) and put the address past those bytes in the
; stack frame as the return address, for returnFromRoutine. A library
; routine (callLibRoutine and callLibRoutine2) returns with RTS, so that
; address is left on the CPU stack as well.
.proc callRoutine
    lda #0
    beq callCommon
.endproc

.proc callLibRoutine
    lda #1
    bne callCommon
.endproc

.proc callRoutine2
    lda #2
    bne callCommon
.endproc

.proc callLibRoutine2
    lda #3
    ; Fall through to callCommon
.endproc

; Bit 0 of A is set for a library routine and bit 1 for level 2
.proc callCommon
    sta tmp2
    pla                     ; This routine's return address, the JSR's
    sta tmp3                ; last byte
    pla
    sta tmp4
    ldy #1
    lda tmp2
    and #2
    beq LV
    lda #2                  ; Level 2
    sta tmp1
    bne AD
LV: lda (tmp3),y            ; level
    sta tmp1
    iny
AD: lda (tmp3),y            ; The routine's address
    sta ptr2
    iny
    lda (tmp3),y
    sta ptr2+1
    tya                     ; The return address less one: the last byte
    clc
    adc tmp3
    sta tmp3
    bcc :+
    inc tmp4
:   pla                     ; The new stack frame (pushFrame)
    sta stackP+1
    pla
    sta stackP
    lda stackP              ; The frame's return address is at stackP - 8
    sec
    sbc #8
    sta ptr1
    lda stackP+1
    sbc #0
    sta ptr1+1
    ldy #0
    lda tmp3
    sta (ptr1),y
    iny
    lda tmp4
    sta (ptr1),y
    lda currentNestingLevel
    pha
    lda tmp1
    sta currentNestingLevel
    lda tmp2
    and #1                  ; A library routine?
    beq :+
    lda tmp4                ; It returns past the bytes with RTS
    pha
    lda tmp3
    pha
:   jmp (ptr2)
.endproc

.proc popFrameN
    pla                     ; The return address, the JSR's last byte
    sta tmp3
    pla
    sta tmp4
    ldy #1
    lda (tmp3),y
    sta tmp1
    inc tmp3                ; Return past the byte
    bne :+
    inc tmp4
:   lda tmp4
    pha
    lda tmp3
    pha
    lda tmp1
    and #$7f
    beq DN
    sta tmp2
:   jsr incsp4
    dec tmp2
    bne :-
DN: lda tmp1
    and #$80
    jmp libStackCleanup
.endproc

; These routines read the one or two bytes after the JSR that called the
; routine that calls them into tmp1 (and tmp2), and make that JSR return
; past them. The return address is changed where it is on the CPU stack.
.proc fetchInline1
    tsx
    lda $0103,x
    sta tmp3
    lda $0104,x
    sta tmp4
    ldy #1
    lda (tmp3),y
    sta tmp1
    lda #1
    bne skipInline
.endproc

.proc fetchInline2
    tsx
    lda $0103,x
    sta tmp3
    lda $0104,x
    sta tmp4
    ldy #1
    lda (tmp3),y
    sta tmp1
    iny
    lda (tmp3),y
    sta tmp2
    lda #2
    ; Fall through to skipInline
.endproc

.proc skipInline
    clc
    adc $0103,x
    sta $0103,x
    bcc :+
    inc $0104,x
:   rts
.endproc

; These routines pop a Boolean and branch to the address after the JSR
; if it is False (branchIfFalse) or True (branchIfTrue). Otherwise they
; return past the address.
.proc branchIfFalse
    jsr fetchInline2
    jsr popeax
    cmp #0
    beq BR
    rts
BR: pla                     ; Branch instead of returning
    pla
    jmp (tmp1)
.endproc

.proc branchIfTrue
    jsr fetchInline2
    jsr popeax
    cmp #0
    bne branchIfFalse::BR
    rts
.endproc

; This routine converts the integer on the runtime stack (convertType)
; from the type in the byte after the JSR to the type in the next byte.
.proc convertInline
    jsr fetchInline2
    lda tmp1
    pha
    lda tmp2
    pha
    jsr popToIntOp1And2
    pla
    tax
    pla
    jsr convertType
    jmp pushFromIntOp1And2
.endproc

; This routine converts the string on the runtime stack to a new string
; for a parameter (convertString). Its type is passed in A.
.proc convertStrParam
    pha
    jsr popeax
    sta tmp1
    stx tmp2
    pla
    tay
    lda tmp1
    ldx tmp2
    jsr convertString
    jmp pusheax
.endproc

; This routine pushes the address of the current routine's return value.
.proc pushRetAddr
    lda stackP
    sec
    sbc #4
    pha
    lda stackP+1
    sbc #0
    tax
    pla
    jmp pusheax
.endproc

; This routine pops an address and frees the memory there.
.proc popAndFree
    jsr popeax
    jmp heapFree
.endproc

; These routines push the byte, or the integer, after the JSR.
.proc pushByteInline
    jsr fetchInline1
    lda tmp1
    jmp pushByteStack
.endproc

.proc pushIntInline
    jsr fetchInline2
    lda tmp1
    ldx tmp2
    jmp pushIntStack
.endproc

; These routines push the value (pushVar) or the address of a global
; variable, at nesting level 1. Its offset (and its type) follow the JSR.
.proc pushGlobalInline
    jsr fetchInline2
    lda #1
    ldx tmp1
    ldy tmp2
    jmp pushVar
.endproc

.proc pushGlobalAddr
    jsr fetchInline1
    lda #1
    ldx tmp1
    jmp pushVarAddr
.endproc

; These routines are assignVar and assignStrVar with the types after the
; JSR: the variable's, then the value's (assignInline), or the value's
; (assignStrInline).
.proc assignInline
    jsr fetchInline2
    ldx tmp1
    lda tmp2
    jmp assignVar
.endproc

.proc assignStrInline
    jsr fetchInline1
    lda tmp1
    jmp assignStrVar
.endproc

; This routine reads the three bytes after the JSR that called the routine
; that calls it into tmp1, tmp2 and tmp3, and makes that JSR return past
; them (fetchInline2).
.proc fetchInline3
    tsx
    lda $0103,x
    sta tmp3
    lda $0104,x
    sta tmp4
    ldy #1
    lda (tmp3),y
    sta tmp1
    iny
    lda (tmp3),y
    sta tmp2
    iny
    lda (tmp3),y
    sta tmp3
    lda #3
    jmp skipInline
.endproc

; These routines compare (comp), add or subtract the values on the
; runtime stack. The two types and the third byte (the comparison, or the
; result's type) follow the JSR.
.proc compInline
    jsr fetchInline3
    jsr loadInline3
    jmp comp
.endproc

.proc addInline
    jsr fetchInline3
    jsr loadInline3
    jmp add
.endproc

.proc subInline
    jsr fetchInline3
    jsr loadInline3
    jmp subtract
.endproc

.proc loadInline3
    lda tmp1
    ldx tmp2
    ldy tmp3
    rts
.endproc
