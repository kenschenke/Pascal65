; Runtime Stack

.include "float.inc"
.include "runtime.inc"

; exports

.export rtStackCleanup, rtStackInit, pushIntStack, calcStackOffset
.export storeIntStack, pushAddrStack, readIntStack, popToIntOp1
.export popToIntOp2, pushFromIntOp1, pushRealStack, storeRealStack
.export popToReal, readRealStack, readByteStack, pushByteStack
.export storeByteStack, pushStackFrameHeader, returnFromRoutine
.export popToIntOp1And2, popToIntOp32, readInt32Stack
.export storeInt32Stack, pushFromIntOp1And2

; imports

.import popeax, pusheax, incsp4

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  The runtime stack is used to store every global and local variable as well
;;  as the call stack for functions and procedures.  The stack starts at
;;  $CFFF and grows downward in memory to a maximum size of 2k.
;;
;;  A stack frame exists for each scope: global and each function/procedure.
;;  The stack frame for the global stack is set up during program
;;  initialization.  The stack frame for each routine is set up and torn down
;;  during runtime as needed.
;;
;;  A stack frame consists of a 16-byte header followed by each variable in
;;  that scope.  There are four values in each stack frame header, appearing
;;  in the following order bottom to top.
;;
;;     1. Function return value (zero for program scope or procedures).
;;     2. Return address of routine caller (zero for program scope).
;;     3. Static link (point to base of stack frame for parent scope).
;;     4. Dynamic link (point to base of stack frame of caller).
;;
;;  The zeropage value stackP points to the base of the current scope's
;;  stack frame.  More accurately, it points to the next byte following
;;  the bottom of the stack frame.  For example, on program startup
;;  stackP is $D000.  When a Pascal function or procedure is called,
;;  stackP temporarily points to the routine's stack frame then is
;;  restored to the caller's stack frame when the function or procedure
;;  returns.  The global stack frame's return value is actually at
;;  $CFFC through $CFFF.  The return address is at $CFF8 through $CFFB.
;;  Values are stored least-significant to most-significant in
;;  increasing address order.  So, the least-significant byte of the
;;  return value is at $CFFC.
;;
;;  The zeropage value sp points to the current top of the stack.
;;  Just like stackP, it points to the next byte following the
;;  top of the stack.  When a value is pushed onto the stack,
;;  sp decreases by the number of bytes pushed.
;;
;;  Each variable on the stack frame takes up 4 bytes to ease stack math.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Calculate stack offset
; value offset in X
; nesting level in A
; address returned in ptr1
.proc calcStackOffset
    ; Calculate the nesting level delta
    sta tmp1
    txa             ; Move value offset to A
    pha             ; Push it on the stack
    lda currentNestingLevel
    sec
    sbc tmp1
    sta tmp1        ; nesting level delta in tmp1

    ; Start off ptr1 at the current stack frame
    lda stackP
    sta ptr1
    lda stackP + 1
    sta ptr1 + 1

    ; Walk up the call stack to the desired nesting level
    lda tmp1        ; look at current delta
    beq L2          ; if it's zero, ptr1 is at the desired stack frame
L1:
    ; Subtract 12 from ptr1 to look at the static link
    lda ptr1
    sec
    sbc #12
    sta ptr1
    lda ptr1 + 1
    sbc #0
    sta ptr1 + 1
    ; Load the static link address into ptr1
    ldy #1
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    sta ptr1
    stx ptr1 + 1
    dec tmp1
    bne L1

L2:
    pla             ; Pull the value offset back off the stack
    tax             ; And put it back in X
    ; Subtract 16 for the stack frame header
    sec
    lda ptr1
    sbc #16
    sta ptr1
    lda ptr1 + 1
    sbc #0
    sta ptr1 + 1
    ; Multiply offset by 4
    lda #0
    sta tmp2
    stx tmp1
    asl tmp1
    rol tmp2
    asl tmp1
    rol tmp2
    ; Subtract tmp1/tmp2 from ptr1
    sec
    lda ptr1
    sbc tmp1
    sta ptr1
    lda ptr1 + 1
    sbc tmp2
    sta ptr1 + 1
    ; Subtract 4 from offset (bottom of value on stack)
    sec
    lda ptr1
    sbc #4
    sta ptr1
    lda ptr1 + 1
    sbc #0
    sta ptr1 + 1
    rts
.endproc

; Clean up the stack frame header
.proc rtStackCleanup
    jsr incsp4
    jsr incsp4
    jsr incsp4
    jsr incsp4
    rts
.endproc

; Initialize the runtime stack
; Stack size is passed in A/X
.proc rtStackInit
    ; Initialize the program's stack frame at the bottom
    lda #0
    tax
    jsr pushIntStack    ; Function return value
    jsr pushIntStack    ; Return address
    jsr pushIntStack    ; Static link               ; Stack frame of parent scope
    jsr pushIntStack    ; Dynamic link              ; Stack frame of caller
    rts
.endproc

; This routine pushes a new stack frame header for a routine.
; The caller's return address is passed in A/X
; The caller's nesting level is passed in Y
; The base of the new stack frame is returned in A/X
.proc pushStackFrameHeader
    ; Store the return address and subtract 1
    stx ptr1 + 1
    sec
    sbc #1
    sta ptr1
    lda ptr1 + 1
    sbc #0
    sta ptr1 + 1
    ; Store the caller's nesting level
    tya
    pha

	; Store the caller's stack frame base in ptr2
	lda stackP
	sta ptr2
	lda stackP + 1
	sta ptr2 + 1

	; Store the current stack pointer in ptr3 so it
    ; can be returned to the caller.
	lda sp
    sta ptr3
    lda sp + 1
    sta ptr3 + 1

	; Placeholder for return value
	lda #0
	tax
	jsr pushIntStack

	; Return address
    lda ptr1
    ldx ptr1 + 1
	jsr pushIntStack

	; Placeholder for static link
    ; Caller's stack frame for now.
    pla                 ; Pull caller's nesting level off stack
    jsr calcStaticLink
	; lda ptr2
	; ldx ptr2 + 1
	jsr pushIntStack

	; Dynamic link
	lda ptr2
	ldx ptr2 + 1
	jsr pushIntStack

    ; Return the new stack frame base in A/X
    lda ptr3
    ldx ptr3 + 1

    rts
.endproc

; This routine calculates the static link from the new procedure
; to containing procedures.  The static link pointer is returned in A/X.
; The new routine's nesting level in passed in A.
.proc calcStaticLink
    sta tmp1
    lda currentNestingLevel
    cmp tmp1
    bne L1
    ; The callee is the same nesting level as the caller.
    ; Return the address of the common parent's stack frame.
    lda stackP
    sta ptr1
    lda stackP + 1
    sta ptr1 + 1
    lda ptr1
    sec
    sbc #12
    sta ptr1
    lda ptr1 + 1
    sbc #0
    sta ptr1 + 1
    ldy #1
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    rts
L1:
    clc
    adc #1
    cmp tmp1
    bne L2
    ; The callee is nested within the caller.
    ; Return the address of the caller's stack frame.
    lda stackP
    ldx stackP + 1
    rts
L2:
    ; The callee is nested less deeply than the caller.
    ; Return the address of the nearest common ancestor's stack frame.
    lda currentNestingLevel
    sec
    sbc tmp1
    tax
    lda stackP
    sta ptr1
    lda stackP + 1
    sta ptr1 + 1
    cpx #0
    bmi L4
L3:
    jsr sub8
    ldy #1
    lda (ptr1),y
    pha
    dey
    lda (ptr1),y
    sta ptr1
    pla
    sta ptr1 + 1
    dex
    bmi L4
    cpx #0
    beq L3
L4:
    lda ptr1
    ldx ptr1 + 1
    rts
.endproc

; Subtract 8 from ptr1
.proc sub8
    lda ptr1
    sec
    sbc #8
    sta ptr1
    lda ptr1 + 1
    sbc #0
    sta ptr1 + 1
    rts
.endproc

; This uses the return address stored in the stack frame header and places
; that address on the CPU stack then does an RTS.  It expects the return
; address to be at the top of the stack.  Callers should call this with
; a jmp, NOT a jsr.
.proc returnFromRoutine
    jsr popeax
    tay                 ; Transfer low byte to Y
    txa                 ; Transfer high byte to A
    pha                 ; Push high byte to stack
    tya                 ; Transfer low byte back to A
    pha                 ; Push low byte to stack
    rts                 ; Go to the return address
.endproc

; Push the byte in A to the runtime stack
.proc pushByteStack
    ldx #0
    stx sreg
    stx sreg + 1
    jmp pusheax
.endproc

; Push the integer in A/X to the runtime stack
; A and X are not destroyed
.proc pushIntStack
    pha
    lda #0
    sta sreg
    sta sreg + 1
    pla
    jmp pusheax
.endproc

; Push the real in FPACC to the runtime stack
.proc pushRealStack
    ldx FPBASE + FPNSW
    lda FPBASE + FPMSW
    sta sreg
    lda FPBASE + FPACCE
    sta sreg + 1
    lda FPBASE + FPLSW
    jsr pusheax
    rts
.endproc

; Store the real at the top of the stack into the addr in ptr1
.proc storeRealStack
    jsr popeax
    ldy #3
    pha
    lda sreg + 1
    sta (ptr1),y
    dey
    lda sreg
    sta (ptr1),y
    dey
    txa
    sta (ptr1),y
    dey
    pla
    sta (ptr1),y
    rts
.endproc

; Pushes the address in ptr1 to the stack
.proc pushAddrStack
    lda #0
    sta sreg
    sta sreg + 1
    lda ptr1
    ldx ptr1 + 1
    jmp pusheax
.endproc

; Read the integer from the address in ptr1
; Returned in A/X
.proc readIntStack
    ldy #1
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    rts
.endproc

; Read the byte from the address in ptr1
; Returned in A
.proc readByteStack
    ldy #0
    lda (ptr1),y
    ldx #0
    rts
.endproc

; Store the integer at the top of the stack
; to the address in ptr1
.proc storeIntStack
    jsr popeax
    ldy #0
    sta (ptr1),y
    txa
    iny
    sta (ptr1),y
    rts
.endproc

; Store the 32-bit integer at the top of the stack
; to the address in ptr1
.proc storeInt32Stack
    jsr popeax
    ldy #0
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

; Store the byte at the top of the stack
; to the address in ptr1
.proc storeByteStack
    jsr popeax
    ldy #0
    sta (ptr1),y
    rts
.endproc

; Pops the integer at the top of the runtime stack
; and stores in intOp1
.proc popToIntOp1
     jsr popeax
     sta intOp1
     stx intOp1 + 1
     rts
.endproc

; Pops the integer at the top of the runtime stack
; and stores in intOp2
.proc popToIntOp2
     jsr popeax
     sta intOp2
     stx intOp2 + 1
     rts
.endproc

; Pops the 32-bit integer at the top of the runtime
; stack and stores it in intOp1/intOp2
.proc popToIntOp1And2
    jsr popeax
    sta intOp1
    stx intOp1 + 1
    lda sreg
    sta intOp2
    lda sreg + 1
    sta intOp2 + 1
    rts
.endproc

; Pops the 32-bit integer at the top of the runtime
; stack and stores it in intOp32
.proc popToIntOp32
    jsr popeax
    sta intOp32
    stx intOp32 + 1
    lda sreg
    sta intOp32 + 2
    lda sreg + 1
    sta intOp32 + 3
    rts
.endproc

; Pushes intOp1 onto the runtime stack
.proc pushFromIntOp1
    lda #0
    sta sreg
    sta sreg + 1
    lda intOp1
    ldx intOp1 + 1
    jsr pusheax
    rts
.endproc

; Pushes the 32-bit integer in intOp1/intOp2 onto the runtime stack
.proc pushFromIntOp1And2
    lda intOp2
    sta sreg
    lda intOp2 + 1
    sta sreg + 1
    lda intOp1
    ldx intOp1 + 1
    jsr pusheax
    rts
.endproc

; Pops the real at the top of the runtime stack
; and stores in the FPACC
.proc popToReal
    jsr popeax
    sta FPBASE + FPLSW
    stx FPBASE + FPNSW
    lda sreg
    sta FPBASE + FPMSW
    lda sreg + 1
    sta FPBASE + FPACCE
    rts
.endproc

; Read the real and/or 32-bit integer from the address and leave in A/X/sreg
readRealStack:
readInt32Stack:
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

