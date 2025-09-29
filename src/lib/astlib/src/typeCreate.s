.include "zeropage.inc"
.include "asmlib.inc"
.include "ast.inc"
.include "4510macros.inc"

kindOffset = 9
isConstOffset = 8
subtypeOffset = 4
paramsOffset = 0

.export typeCreate

.import storeFromStack

; Allocate a type structure and populate it with parameters.
; Inputs on runtime stack, bottom to top:
;    TYPE_* type      - 1 byte
;    isConst          - 1 byte
;    subtype pointer  - 4 bytes
;    params pointer   - 4 bytes
; Returns pointer to type structure in Q
.proc typeCreate
    ; Allocate the structure
    lda #.sizeof(type)
    ldx #0
    jsr heapAlloc
    stq ptr1

    ; Zero out the type structure
    lda #0
    ldz #.sizeof(type)-1
:   nop
    sta (ptr1),z
    dez
    bpl :-

    ; Store the type kind
    ldz #kindOffset
    nop
    lda (stackPointer),z
    ldz #type::kind
    nop
    sta (ptr1),z

    ; Store the isConst
    ldz #isConstOffset
    nop
    lda (stackPointer),z
    beq :+
    lda #TYPE_FLAG_ISCONST
    ldz #type::flags
    nop
    sta (ptr1),z

    ; Store the subtype pointer
:   lda #subtypeOffset
    ldx #type::subtype
    jsr storeFromStack

    ; Store the params pointer
    lda #paramsOffset
    ldx #type::paramFields
    jsr storeFromStack

    ; Pop the parameters off the stack
    jsr popQ
    jsr popQ
    jsr popA
    jsr popA

    ldq ptr1
    rts
.endproc
