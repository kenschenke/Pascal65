.include "ast.inc"
.include "4510macros.inc"
.include "zeropage.inc"
.include "asmlib.inc"

.export handleParse, parserError, setUnitsList, getUnitsList, units
.export parserIcode, parserToken, currentLineNumber, parserString, parserValue, parserType
.export parserModuleType, runtimeStackSize, isInUnitInterface, getRuntimeStackSize
.export lastParserString, saveParserString, calcNamePtr, copyParserStringToType, copyNameToType
.export loadStackValue

.import getToken, parseModule

.bss

parserIcode: .res 4
parserToken: .res 1
currentLineNumber: .res 2
parserString: .res 81
lastParserString: .res 81
parserValue: .res 4
parserType: .res 1
runtimeStackSize: .res 2
parserModuleType: .res 1
isInUnitInterface: .res 1
units: .res 4

.code

.proc handleParse
    stq parserIcode

    stq ptr1
    lda #0
    ldx #0
    jsr setMemBufPos

    ; Default of 512 bytes
    lda #0
    sta runtimeStackSize
    lda #2
    sta runtimeStackSize+1

    jsr getToken
    jmp parseModule
.endproc

.proc parserError
    ldx currentLineNumber
    ldy currentLineNumber+1
    jmp compilerError
.endproc

.proc setUnitsList
    stq units
    rts
.endproc

.proc getUnitsList
    ldq units
    rts
.endproc

.proc getRuntimeStackSize
    lda runtimeStackSize
    ldx runtimeStackSize+1
    rts
.endproc

; Copy parserString to lastParserString
.proc saveParserString
    ldx #0
:   lda parserString,x
    sta lastParserString,x
    inx
    cpx #81
    bne :-
    rts
.endproc

; Structure pointer in A/X/Y and structure offset in Z.
; Address returned in Q.
.proc calcNamePtr
    stz intOp32
    ldz #0
    stz intOp32+1
    stz intOp32+2
    stz intOp32+3
    clc
    adcq intOp32
    rts
.endproc

; Copies parserString to the type in ptr1
.proc copyParserStringToType
    ldx #0
    ldz #type::name
L1: lda parserString,x
    beq L2
    nop
    sta (ptr1),z
    inx
    inz
    bne L1
L2: nop
    sta (ptr1),z
    rts
.endproc

; Copies the null-terminated name in ptr2
; to the type in ptr1
.proc copyNameToType
    lda #0
    sta tmp2                ; source index in tmp2
    lda #type::name
    sta tmp1                ; dest index in tmp1
L1: ldz tmp2
    nop
    lda (ptr2),z
    beq L2
    ldz tmp1
    nop
    sta (ptr1),z
    inc tmp1
    inc tmp2
    bne L1
L2: ldz tmp1
    nop
    sta (ptr1),z
    rts
.endproc

; This routine retrieves a 4-byte value off the runtime stack.
; The offset on the stack is passed in Z.
; The value is returned in Q.
.proc loadStackValue
    neg
    neg
    nop
    lda (stackPointer),z
    rts
.endproc
