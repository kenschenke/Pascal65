; Jump table at the start of the runtime library

.import leftpad, printz, printlnz, writeValue, assign, divide, comp, negate
.import add, divint, modulus, pred, succ, subtract, multiply
.import _strToFloat, FPOUT, PRECRD
.import floatToInt16, getFPBUF, floatNeg
.import incsp4, popeax, pushax, pusheax, popToReal, popToIntOp1, popToIntOp2
.import pushAddrStack, pushByteStack, pushIntStack, pushFromIntOp1, pushRealStack
.import readByteStack, readIntStack, readRealStack
.import storeByteStack, storeIntStack, storeRealStack
.import calcStackOffset, rtStackInit, rtStackCleanup, runtimeErrorInit
.import pushStackFrameHeader, returnFromRoutine
.import initArrayHeap, calcRecordOffset, memcopy, heapInit, heapAlloc, heapFree
.import clearInputBuf, readFloatFromInput, readIntFromInput, calcArrayOffset, writeCharArray
.import readCharArrayFromInput
.import popToIntOp1And2, popToIntOp32, readInt32Stack, storeInt32Stack, pushFromIntOp1And2
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
jmp $0000       ; BASE + 33
jmp $0000       ; BASE + 36
jmp $0000       ; BASE + 39
jmp $0000       ; BASE + 42
jmp $0000       ; BASE + 45
jmp $0000       ; BASE + 48
jmp divide      ; BASE + 51
jmp $0000       ; BASE + 54
jmp $0000       ; BASE + 57
jmp $0000       ; BASE + 60
jmp _strToFloat ; BASE + 63
jmp FPOUT       ; BASE + 66
jmp $0000       ; BASE + 69
jmp $0000       ; BASE + 72
jmp $0000       ; BASE + 75
jmp $0000       ; BASE + 78
jmp $0000       ; BASE + 81
jmp floatToInt16 ; BASE + 84
jmp $0000       ; BASE + 87
jmp $0000       ; BASE + 90
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
jmp getFPBUF    ; BASE + 198
jmp writeCharArray  ; BASE + 201
jmp readCharArrayFromInput ; BASE + 204
jmp floatNeg   ; BASE + 207
jmp subtract    ; BASE + 210
jmp $0000       ; BASE + 213
jmp $0000       ; BASE + 216
jmp $0000       ; BASE + 219
jmp $0000       ; BASE + 222
jmp pred        ; BASE + 225
jmp succ        ; BASE + 228
jmp multiply    ; BASE + 231
jmp $0000       ; BASE + 234
jmp popToIntOp1And2 ; BASE + 237
jmp popToIntOp32    ; BASE + 240
jmp readInt32Stack  ; BASE + 243
jmp storeInt32Stack ; BASE + 246
jmp pushFromIntOp1And2  ; BASE + 249
jmp abs         ; BASE + 252
jmp $0000       ; UNUSED 255
jmp $0000       ; BASE + 258
jmp $0000       ; BASE + 261
jmp $0000       ; BASE + 264
jmp $0000       ; BASE + 267
jmp $0000       ; BASE + 270
jmp $0000       ; BASE + 273
jmp $0000       ; BASE + 276
jmp $0000       ; BASE + 279
jmp $0000       ; BASE + 282
jmp $0000       ; BASE + 285
jmp $0000       ; BASE + 288
jmp $0000       ; BASE + 291
