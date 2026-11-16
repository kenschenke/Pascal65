;
; irqcall.s
; Ken Schenke (kenschenke@gmail.com)
;
; Lets a library call a Pascal routine from an interrupt handler
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; A library's IRQ handler can stop the program anywhere, even in the middle
; of a runtime routine. A Pascal routine it calls (a callback) uses the
; same zero page and the same runtime variables, so the handler brackets
; the call with irqCallBegin and irqCallEnd:
;
;     jsr rtIrqCallBegin
;     (push the routine, rtLibStackHeader, push the parameters,
;      push the routine, rtLibCallRoutine, pop the parameters,
;      rtLibStackCleanup)
;     jsr rtIrqCallEnd
;
; irqCallBegin saves the runtime's zero page and every runtime variable an
; expression, assignment or declaration uses for a moment (the block
; below). It moves the stack pointer down a little, so the callback can't
; change a value the program has just popped and is still reading. And it
; sets stackP and currentNestingLevel to the program's own stack frame and
; level: the program may have been stopped between setting one and the
; other, and the callback's static link, which it reaches the program's
; variables by, is worked out from them. So a callback must be declared at
; the program's outer level. irqCallEnd puts it all back. Calls don't nest.
;
; Strings, files, the heap and real-number output keep state of their own
; that isn't saved, so a callback must not use them.

.include "runtime.inc"

.export irqCallBegin, irqCallEnd, programFrame
.export oper1Type, oper2Type, resultType, compOper, rightType, leftPtr
.export heapAddr, declAddr, declType
.export initPtr, isRealNeg, numElems, ndxElems, numLiterals, charPtr
.export charCount, dividend, divisor, ADDR1, ADDR2, ADDR3

; The runtime's zero page (runtime.inc)
ZP_SAVE_START = sp
ZP_SAVE_SIZE = inputBufUsed + 1 - sp

; The callback's stack frame starts this many bytes below the stack
; pointer
CB_STACK_GAP = 32

.bss

stateStart:
; math.s
oper1Type: .res 1
oper2Type: .res 1
resultType: .res 1
; comp.s
compOper: .res 1
; assign.s
rightType: .res 1
leftPtr: .res 2                 ; Preserve pointer to variable
; decl.s
heapAddr: .res 2
declAddr: .res 2
declType: .res 1
; array.s
initPtr: .res 2
isRealNeg: .res 1
numElems: .res 2                ; Used by initArrayDeclaration
ndxElems: .res 2
numLiterals: .res 2
charPtr: .res 2                 ; Used by writeCharArray
charCount: .res 2
; mod.s
dividend: .res 4
divisor: .res 4
; floatutil.s
ADDR1: .res 1
ADDR2: .res 1
ADDR3: .res 1
stateEnd:

STATE_SIZE = stateEnd - stateStart

programFrame: .res 2            ; stackP of the program (rtStackInit)
stateSave: .res STATE_SIZE
zpSave: .res ZP_SAVE_SIZE

.assert STATE_SIZE <= 128, error, "runtime state is over 128 bytes"
.assert ZP_SAVE_SIZE <= 128, error, "zero page save is over 128 bytes"

.code

.proc irqCallBegin
    ldx #ZP_SAVE_SIZE-1
:   lda ZP_SAVE_START,x
    sta zpSave,x
    dex
    bpl :-
    ldx #STATE_SIZE-1
:   lda stateStart,x
    sta stateSave,x
    dex
    bpl :-

    sec
    lda sp
    sbc #CB_STACK_GAP
    sta sp
    lda sp+1
    sbc #0
    sta sp+1
    lda programFrame
    sta stackP
    lda programFrame+1
    sta stackP+1
    lda #1                      ; The program's nesting level
    sta currentNestingLevel
    rts
.endproc

.proc irqCallEnd
    ldx #STATE_SIZE-1
:   lda stateSave,x
    sta stateStart,x
    dex
    bpl :-
    ldx #ZP_SAVE_SIZE-1
:   lda zpSave,x
    sta ZP_SAVE_START,x
    dex
    bpl :-
    rts
.endproc
