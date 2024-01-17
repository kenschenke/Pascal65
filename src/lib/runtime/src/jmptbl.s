; Jump table at the start of the runtime library

.import leftpad, printz, printlnz, writeValue, assign, divide, comp, negate
.import add, divint, modulus, pred, succ, subtract, multiply
.import _strToFloat, FPOUT, PRECRD
.import floatToInt16, getFPBUF, floatNeg
.import incsp4, popeax, pushax, pusheax, popToReal, popToIntOp1, popToIntOp2
.import pushAddrStack, pushByteStack, pushIntStack, pushFromIntOp1, pushRealStack
.import readByteStack, readIntStack, readRealStack
.import storeIntStack, storeRealStack
.import calcStackOffset, rtStackInit, rtStackCleanup, runtimeErrorInit
.import pushStackFrameHeader, returnFromRoutine
.import initArrayHeap, calcRecordOffset, memcopy, heapInit, heapAlloc, heapFree
.import clearInputBuf, readFloatFromInput, readIntFromInput, calcArrayOffset, writeCharArray
.import readCharArrayFromInput
.import readInt32Stack, storeInt32Stack
.import abs, sqr

.segment "JMPTBL"

jmp printz      ; BASE + 0
jmp printlnz    ; BASE + 3
jmp leftpad     ; BASE + 6
jmp assign      ; BASE + 9
jmp add         ; BASE + 12
jmp comp        ; BASE + 15
jmp negate      ; BASE + 18
jmp divint      ; BASE + 21
jmp writeValue  ; BASE + 24
jmp sqr         ; BASE + 27
jmp modulus     ; BASE + 30
jmp abs         ; BASE + 33
jmp readInt32Stack       ; BASE + 36
jmp storeInt32Stack       ; BASE + 39
jmp multiply    ; BASE + 42
jmp pred        ; BASE + 45
jmp succ        ; BASE + 48
jmp divide      ; BASE + 51
jmp subtract    ; BASE + 54
jmp floatNeg    ; BASE + 57
jmp getFPBUF    ; BASE + 60
jmp _strToFloat ; BASE + 63
jmp FPOUT       ; BASE + 66
jmp readCharArrayFromInput       ; BASE + 69
jmp writeCharArray       ; BASE + 72
jmp calcArrayOffset       ; BASE + 75
jmp clearInputBuf ; BASE + 78
jmp readFloatFromInput ; BASE + 81
jmp readIntFromInput   ; BASE + 84
jmp floatToInt16 ; BASE + 87
jmp runtimeErrorInit ; BASE + 90
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
jmp memcopy       ; BASE + 141
jmp storeIntStack ; BASE + 144
jmp storeRealStack ; BASE + 147
jmp calcStackOffset ; BASE + 150
jmp rtStackInit ; BASE + 153
jmp rtStackCleanup ; BASE + 156
jmp pushStackFrameHeader ; BASE + 159
jmp returnFromRoutine ; BASE + 162
jmp initArrayHeap   ; BASE + 165
jmp calcRecordOffset ; BASE + 168
jmp heapFree    ; BASE + 171
jmp heapInit    ; BASE + 174
jmp heapAlloc   ; BASE + 177
