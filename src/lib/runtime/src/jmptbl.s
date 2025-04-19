;
; jmptbl.s
; Ken Schenke (kenschenke@gmail.com)
;
; Runtime library entry points
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

; Jump table at the start of the runtime library

.import rtStackCleanup, rtStackInit, pushIntStack, calcStackOffset
.import storeIntStack, pushAddrStack, popToIntOp1
.import popToIntOp2, pushFromIntOp1, pushRealStack, storeRealStack
.import popToReal, pushByteStack
.import pushStackFrameHeader, returnFromRoutine
.import popToIntOp1And2
.import storeInt32Stack, pushFromIntOp1And2, getKey, clearKeyBuf

.import runtimeErrorInit, popeax, incsp4, pushax

.import heapInit, heapAlloc, heapFree, rtInitTensTable32, clearInputBuf
.import writeValue, leftpad, printz, strCase, trim, initFileIo, setFh
.import resetStringBuffer, getStringBuffer, writeStringLiteral
.import strCompare, abs, add, assign, multiply, divide, divint, comp
.import subtract, modulus, sqr, floatNeg, negate, pred, succ, PRECRD
.import calcArrayElem, calcRecordOffset, pusheax, initArrays
.import writeCharArray, readCharArrayFromInput, floatToInt16, FPOUT
.import memcopy, readFloatFromInput, readIntFromInput, _strToFloat
.import concatString, assignString, convertString, readStringFromInput
.import stringSubscriptRead, stringSubscriptCalc
.import loadParam, storeVarParam, returnVal, strPos, beginswith, endswith
.import contains, readCharFromInput, andBitwise, orBitwise
.import lshiftBitwise, rshiftBitwise, invertBitwise, sine, cosine, tangent
.import decrement, increment, stringInit, pushVar, readVar, writeBytes
.import fileOpen, fileClose, readBytes, isEOF, setIOResult, getIOResult
.import fileErase, fileAssign, fileRename, fileFree, convertType
.import libStackHeader, libCallRoutine, addIrqHandler, irqCleanup

.segment "JMPTBL"

jmp rtStackCleanup       ; BASE + 0
jmp rtStackInit          ; BASE + 3
jmp pushIntStack         ; BASE + 6
jmp calcStackOffset      ; BASE + 9
jmp storeIntStack        ; BASE + 12
jmp pushAddrStack        ; BASE + 15
jmp fileOpen             ; BASE + 18
jmp popToIntOp1          ; BASE + 21
jmp popToIntOp2          ; BASE + 24
jmp pushFromIntOp1       ; BASE + 27
jmp pushRealStack        ; BASE + 30
jmp storeRealStack       ; BASE + 33
jmp popToReal            ; BASE + 36
jmp fileClose            ; BASE + 39
jmp isEOF                ; BASE + 42
jmp pushByteStack        ; BASE + 45
jmp setIOResult          ; BASE + 48
jmp pushStackFrameHeader ; BASE + 51
jmp returnFromRoutine    ; BASE + 54
jmp popToIntOp1And2      ; BASE + 57
jmp getIOResult          ; BASE + 60
jmp fileErase            ; BASE + 63
jmp storeInt32Stack      ; BASE + 66
jmp pushFromIntOp1And2   ; BASE + 69
jmp fileAssign           ; BASE + 72
jmp runtimeErrorInit     ; BASE + 75
jmp fileRename           ; BASE + 78
jmp fileFree             ; BASE + 81
jmp heapInit             ; BASE + 84
jmp heapAlloc            ; BASE + 87
jmp heapFree             ; BASE + 90
jmp rtInitTensTable32    ; BASE + 93
jmp clearInputBuf        ; BASE + 96
jmp popeax               ; BASE + 99
jmp incsp4               ; BASE + 102
jmp writeValue           ; BASE + 105
jmp leftpad              ; BASE + 108
jmp printz               ; BASE + 111
jmp strCase              ; BASE + 114
jmp trim                 ; BASE + 117
jmp initFileIo           ; BASE + 120
jmp setFh                ; BASE + 123
jmp resetStringBuffer    ; BASE + 126
jmp getStringBuffer      ; BASE + 129
jmp writeStringLiteral   ; BASE + 132
jmp clearKeyBuf          ; BASE + 135
jmp getKey               ; BASE + 138
jmp strCompare           ; BASE + 141
jmp pushax               ; BASE + 144
jmp abs                  ; BASE + 147
jmp add                  ; BASE + 150
jmp assign               ; BASE + 153
jmp multiply             ; BASE + 156
jmp divide               ; BASE + 159
jmp divint               ; BASE + 162
jmp comp                 ; BASE + 165
jmp subtract             ; BASE + 168
jmp modulus              ; BASE + 171
jmp sqr                  ; BASE + 174
jmp floatNeg             ; BASE + 177
jmp negate               ; BASE + 180
jmp pred                 ; BASE + 183
jmp succ                 ; BASE + 186
jmp PRECRD               ; BASE + 189
jmp calcArrayElem        ; BASE + 192
jmp calcRecordOffset     ; BASE + 195
jmp pusheax              ; BASE + 198
jmp initArrays           ; BASE + 201
jmp writeCharArray       ; BASE + 204
jmp readCharArrayFromInput ; BASE + 207
jmp floatToInt16         ; BASE + 210
jmp FPOUT                ; BASE + 213
jmp memcopy              ; BASE + 216
jmp readFloatFromInput   ; BASE + 219
jmp readIntFromInput     ; BASE + 222
jmp _strToFloat          ; BASE + 225
jmp concatString         ; BASE + 228
jmp assignString         ; BASE + 231
jmp convertString        ; BASE + 234
jmp readStringFromInput  ; BASE + 237
jmp stringSubscriptRead  ; BASE + 240
jmp stringSubscriptCalc  ; BASE + 243
jmp loadParam            ; BASE + 246
jmp returnVal            ; BASE + 249
jmp storeVarParam        ; BASE + 252
jmp strPos               ; BASE + 255
jmp beginswith           ; BASE + 258
jmp endswith             ; BASE + 261
jmp contains             ; BASE + 264
jmp readCharFromInput    ; BASE + 267
jmp andBitwise           ; BASE + 270
jmp orBitwise            ; BASE + 273
jmp lshiftBitwise        ; BASE + 276
jmp rshiftBitwise        ; BASE + 279
jmp invertBitwise        ; BASE + 282
jmp sine                 ; BASE + 285
jmp cosine               ; BASE + 288
jmp tangent              ; BASE + 291
jmp decrement            ; BASE + 294
jmp increment            ; BASE + 297
jmp stringInit           ; BASE + 300
jmp pushVar              ; BASE + 303
jmp readVar              ; BASE + 306
jmp writeBytes           ; BASE + 309
jmp readBytes            ; BASE + 312
jmp convertType          ; BASE + 315
jmp libStackHeader       ; BASE + 318
jmp libCallRoutine       ; BASE + 321
jmp addIrqHandler        ; BASE + 324
jmp irqCleanup           ; BASE + 327
