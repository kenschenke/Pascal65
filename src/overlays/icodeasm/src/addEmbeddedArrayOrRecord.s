.include "ast.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

elemLabelSize = 20

; Local variables
indexOffset = 0
elemNumOffset = indexOffset + 2
elemLabelOffset = elemNumOffset + 2
; Routine parameters
exprInitOffset = elemLabelOffset + elemLabelSize
declPtrOffset = exprInitOffset + 4
elemTypeOffset = declPtrOffset + 4
highBoundOffset = elemTypeOffset + 4
lowBoundOffset = highBoundOffset + 2
labelOffset = lowBoundOffset + 2

.export addEmbeddedArrayOrRecord

.import loadStackValue, icodeArrayInit, icodeRecordInit
.import icodeOper1Label, icodeWriteInstruction, icodeLabel

.bss

intbuf: .res 10

.code

; Parameters passed on stack, bottom to top
;    parent array's label pointer (32-bit)
;    lowBound (16-bit)
;    highBound (16-bit)
;    elemType ptr (32-bit)
;    declaration ptr (32-bit)
;    init expression (32-bit)
.proc addEmbeddedArrayOrRecord
    ; Push local variables onto the stack
    lda #elemLabelSize
    jsr pushBlock
    lda #1
    ldx #0
    jsr pushAX          ; elemNum (initialize to 1)
    lda #0
    tax
    jsr pushAX          ; index

    ; Initialize index to lowBound
    ldz #lowBoundOffset+1
    nop
    lda (stackPointer),z
    tax
    dez
    nop
    lda (stackPointer),z
    ldz #indexOffset
    nop
    sta (stackPointer),z
    inz
    txa
    nop
    sta (stackPointer),z

    ; Loop while index <= highBound
L1: jsr formatElemLabel
    ldz #elemTypeOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    bne :+
    jsr embeddedArray
    bra L2
:   jsr embeddedRecord

L2: ldz #exprInitOffset
    jsr loadStackValue
    jsr isQZero
    beq NX
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq NX
    ; exprInit = exprInit.right
    stq ptr1
    ldz #exprInitOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

    ; Next element
NX: ldz #indexOffset
    nop
    lda (stackPointer),z
    clc
    adc #1
    sta intOp1
    nop
    sta (stackPointer),z
    inz
    nop
    lda (stackPointer),z
    adc #0
    sta intOp1+1
    nop
    sta (stackPointer),z
    ; Put highBound in intOp2
    ldz #highBoundOffset
    nop
    lda (stackPointer),z
    sta intOp2
    inz
    nop
    lda (stackPointer),z
    sta intOp2+1
    jsr gtInt16
    bne DN
    ; Increment elemNum
    ldz #elemNumOffset
    nop
    lda (stackPointer),z
    clc
    adc #1
    nop
    sta (stackPointer),z
    inz
    nop
    lda (stackPointer),z
    adc #0
    nop
    sta (stackPointer),z
    jmp L1

DN: jsr popAX           ; index
    jsr popAX           ; elemNum
    lda #elemLabelSize
    jsr popBlock        ; elemLabel
    jsr popQ            ; exprInit
    jsr popQ            ; declPtr
    jsr popQ            ; elemType
    jsr popAX           ; highBound
    jsr popAX           ; lowBound
    jsr popQ            ; labelPtr
    rts
.endproc

.proc embeddedArray
    lda #elemLabelOffset
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq stackPointer
    clc
    adcq intOp32
    stq ptr1

    ldz #elemTypeOffset
    jsr loadStackValue
    stq ptr2

    ldz #exprInitOffset
    jsr loadStackValue
    stq ptr3
    jsr isQZero
    beq :+
    ldz #expr::left
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr3

:   ldz #declPtrOffset
    jsr loadStackValue
    stq ptr4

    ldq ptr1
    jsr pushQ           ; label
    ldq ptr2
    jsr pushQ           ; elemType
    ldq ptr3
    jsr pushQ           ; exprInit.left
    ldq ptr4
    jsr pushQ           ; declPtr
    jsr icodeArrayInit

    ; Copy elemLabel to icodeLabel
    lda #elemLabelOffset
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq stackPointer
    clc
    adcq intOp32
    stq ptr1
    ldz #0
    ldx #0
:   nop
    lda (ptr1),z
    sta icodeLabel,x
    beq :+
    inx
    inz
    bne :-
:   jsr icodeOper1Label
    lda #IC_DIA
    jsr icodeWriteInstruction

    rts
.endproc

.proc embeddedRecord
    lda #elemLabelOffset
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq stackPointer
    clc
    adcq intOp32
    stq ptr1

    ldz #elemTypeOffset
    jsr loadStackValue
    stq ptr2

    ldz #declPtrOffset
    jsr loadStackValue
    stq ptr3

    ldq ptr1
    jsr pushQ           ; label
    ldq ptr2
    jsr pushQ           ; elemType
    ldq ptr3
    jsr pushQ           ; declPtr
    jsr icodeRecordInit

    ; Copy elemLabel to icodeLabel
    lda #elemLabelOffset
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq stackPointer
    clc
    adcq intOp32
    stq ptr1
    ldz #0
    ldx #0
:   nop
    lda (ptr1),z
    sta icodeLabel,x
    beq :+
    inx
    inz
    bne :-
:   jsr icodeOper1Label
    lda #IC_DIR
    jsr icodeWriteInstruction

    rts
.endproc

.proc formatElemLabel
    ldz #elemNumOffset
    nop
    lda (stackPointer),z
    sta intOp1
    inz
    nop
    lda (stackPointer),z
    sta intOp1+1
    lda #<intbuf
    ldx #>intbuf
    jsr writeInt16
    ; Copy the caller's label (ptr1) to elemLabel (ptr2)
    ldz #labelOffset
    jsr loadStackValue
    stq ptr1
    lda #elemLabelOffset
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq stackPointer
    clc
    adcq intOp32
    stq ptr2
    ldz #0
:   nop
    lda (ptr1),z
    beq :+
    nop
    sta (ptr2),z
    inz
    bne :-
:   ; Add "."
    lda #'.'
    nop
    sta (ptr2),z
    inz
    ; Copy intbuf
    ldx #0
:   lda intbuf,x
    nop
    sta (ptr2),z
    beq :+
    inz
    inx
    bne :-
:   rts
.endproc
