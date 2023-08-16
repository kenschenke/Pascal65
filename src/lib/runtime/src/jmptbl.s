; Jump table at the start of the runtime library

.import leftpad, printz, printlnz
.import absInt16, addInt16, divInt16, int16Sqr, modInt16, multInt16, subInt16, writeInt16
.import eqInt16, leInt16, ltInt16, geInt16, gtInt16
.import copyFPACCtoFPOP, FPADD, FPDIV, FPINP, FPMULT, FPOUT, FPSUB, floatAbs, PRECRD
.import floatEq, floatGt, floatGte, floatLt, floatLte, floatToInt16, int16ToFloat
.import incsp4, popeax, pushax, pusheax, popToReal, popToIntOp1, popToIntOp2
.import pushAddrStack, pushByteStack, pushIntStack, pushFromIntOp1, pushRealStack
.import readByteStack, readIntStack, readRealStack
.import storeByteStack, storeIntStack, storeRealStack
.import calcStackOffset, rtStackInit, rtStackCleanup, runtimeErrorInit
.import pushStackFrameHeader, returnFromRoutine
.import initArrayHeap, calcRecordOffset, memcopy, heapInit, heapAlloc, heapFree
.import clearInputBuf, readFloatFromInput, readIntFromInput, calcArrayOffset

.segment "JMPTBL"

jmp printz      ; BASE + 0
jmp printlnz    ; BASE + 3
jmp leftpad     ; BASE + 6
jmp writeInt16  ; BASE + 9
jmp addInt16    ; BASE + 12
jmp subInt16    ; BASE + 15
jmp multInt16   ; BASE + 18
jmp divInt16    ; BASE + 21
jmp absInt16    ; BASE + 24
jmp int16Sqr    ; BASE + 27
jmp modInt16    ; BASE + 30
jmp eqInt16     ; BASE + 33
jmp leInt16     ; BASE + 36
jmp ltInt16     ; BASE + 39
jmp geInt16     ; BASE + 42
jmp gtInt16     ; BASE + 45
jmp copyFPACCtoFPOP ; BASE + 48
jmp FPADD       ; BASE + 51
jmp FPSUB       ; BASE + 54
jmp FPMULT      ; BASE + 57
jmp FPDIV       ; BASE + 60
jmp FPINP       ; BASE + 63
jmp FPOUT       ; BASE + 66
jmp floatEq     ; BASE + 69
jmp floatGt     ; BASE + 72
jmp floatGte    ; BASE + 75
jmp floatLt     ; BASE + 78
jmp floatLte    ; BASE + 81
jmp floatToInt16 ; BASE + 84
jmp int16ToFloat ; BASE + 87
jmp floatAbs    ; BASE + 90
jmp incsp4      ; BASE + 93
jmp popeax      ; BASE + 96
jmp pushax      ; BASE + 99
jmp pusheax     ; BASE + 102
jmp popToReal   ; BASE + 105
jmp popToIntOp1 ; BASE + 108
jmp popToIntOp2 ; BASE + 111
jmp PRECRD      ; BASE + 114
jmp pushAddrStack ; BASE + 117
jmp pushByteStack ; BASE + 120
jmp pushIntStack ; BASE + 123
jmp pushFromIntOp1 ; BASE + 126
jmp pushRealStack ; BASE + 129
jmp readByteStack ; BASE + 132
jmp readIntStack ; BASE + 135
jmp readRealStack ; BASE + 138
jmp storeByteStack ; BASE + 141
jmp storeIntStack ; BASE + 144
jmp storeRealStack ; BASE + 147
jmp calcStackOffset ; BASE + 150
jmp rtStackInit ; BASE + 153
jmp rtStackCleanup ; BASE + 156
jmp pushStackFrameHeader ; BASE + 159
jmp returnFromRoutine ; BASE + 162
jmp initArrayHeap   ; BASE + 165
jmp calcRecordOffset ; BASE + 168
jmp memcopy     ; BASE + 171
jmp heapInit    ; BASE + 174
jmp heapAlloc   ; BASE + 177
jmp heapFree    ; BASE + 180
jmp runtimeErrorInit    ; BASE + 183
jmp clearInputBuf   ; BASE + 186
jmp readFloatFromInput  ; BASE + 189
jmp readIntFromInput    ; BASE + 192
jmp calcArrayOffset ; BASE + 195
