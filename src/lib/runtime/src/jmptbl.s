; Jump table at the start of the runtime library

.import rtStackCleanup, rtStackInit, pushIntStack, calcStackOffset
.import storeIntStack, pushAddrStack, readIntStack, popToIntOp1
.import popToIntOp2, pushFromIntOp1, pushRealStack, storeRealStack
.import popToReal, readRealStack, readByteStack, pushByteStack
.import storeByteStack, pushStackFrameHeader, returnFromRoutine
.import popToIntOp1And2, popToIntOp32, readInt32Stack
.import storeInt32Stack, pushFromIntOp1And2

.import runtimeError, runtimeErrorInit, popa, popax, popeax, incsp4

.import heapInit, heapAlloc, heapFree, rtInitTensTable32, clearInputBuf

.segment "JMPTBL"

jmp rtStackCleanup       ; BASE + 0
jmp rtStackInit          ; BASE + 3
jmp pushIntStack         ; BASE + 6
jmp calcStackOffset      ; BASE + 9
jmp storeIntStack        ; BASE + 12
jmp pushAddrStack        ; BASE + 15
jmp readIntStack         ; BASE + 18
jmp popToIntOp1          ; BASE + 21
jmp popToIntOp2          ; BASE + 24
jmp pushFromIntOp1       ; BASE + 27
jmp pushRealStack        ; BASE + 30
jmp storeRealStack       ; BASE + 33
jmp popToReal            ; BASE + 36
jmp readRealStack        ; BASE + 39
jmp readByteStack        ; BASE + 42
jmp pushByteStack        ; BASE + 45
jmp storeByteStack       ; BASE + 48
jmp pushStackFrameHeader ; BASE + 51
jmp returnFromRoutine    ; BASE + 54
jmp popToIntOp1And2      ; BASE + 57
jmp popToIntOp32         ; BASE + 60
jmp readInt32Stack       ; BASE + 63
jmp storeInt32Stack      ; BASE + 66
jmp pushFromIntOp1And2   ; BASE + 69
jmp runtimeError         ; BASE + 72
jmp runtimeErrorInit     ; BASE + 75
jmp popa                 ; BASE + 78
jmp popax                ; BASE + 81
jmp heapInit             ; BASE + 84
jmp heapAlloc            ; BASE + 87
jmp heapFree             ; BASE + 90
jmp rtInitTensTable32    ; BASE + 93
jmp clearInputBuf        ; BASE + 96
jmp popeax               ; BASE + 99
jmp incsp4               ; BASE + 102
jmp $0000       ; BASE + 105
jmp $0000       ; BASE + 108
jmp $0000       ; BASE + 111
jmp $0000       ; BASE + 114
jmp $0000       ; BASE + 117
jmp $0000       ; BASE + 120
jmp $0000       ; BASE + 123
jmp $0000       ; BASE + 126
jmp $0000       ; BASE + 129
jmp $0000       ; BASE + 132
jmp $0000       ; BASE + 135
jmp $0000       ; BASE + 138
jmp $0000       ; BASE + 141
jmp $0000       ; BASE + 144
jmp $0000       ; BASE + 147
jmp $0000       ; BASE + 150
jmp $0000       ; BASE + 153
jmp $0000       ; BASE + 156
jmp $0000       ; BASE + 159
jmp $0000       ; BASE + 162
jmp $0000       ; BASE + 165
jmp $0000       ; BASE + 168
jmp $0000       ; BASE + 171
jmp $0000       ; BASE + 174
jmp $0000       ; BASE + 177
