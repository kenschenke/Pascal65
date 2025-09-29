.include "4510macros.inc"
.include "zeropage.inc"
.include "asmlib.inc"

.export handleParse, parserError, setUnitsList, getUnitsList, units
.export parserIcode, parserToken, currentLineNumber, parserString, parserValue, parserType
.export parserModuleType, runtimeStackSize, isInUnitInterface

.import getToken, parseModule

.bss

parserIcode: .res 4
parserToken: .res 1
currentLineNumber: .res 2
parserString: .res 81
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

    jsr getToken
    jmp parseModule
.endproc

.proc parserError
    ldx currentLineNumber
    ldy currentLineNumber
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
