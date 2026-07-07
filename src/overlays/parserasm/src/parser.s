.include "4510macros.inc"
.include "zeropage.inc"
.include "asmlib.inc"

.export handleParse, parserError, setUnitsList, getUnitsList, units
.export parserIcode, parserToken, currentLineNumber, parserString, parserValue, parserType
.export parserModuleType, runtimeStackSize, isInUnitInterface, getRuntimeStackSize
.export lastParserString, saveParserString, calcNamePtr

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
