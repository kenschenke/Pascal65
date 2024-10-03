;
; demolib.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Jump table for demo library
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.export publicInt, publicArray, publicRecord, publicString

.import demoArea, doubleParam, biggest, lastChar, sumOfRecord, appendToString
.import doubleArray, doubleRecord, doublePublicInt, doublePublicArray
.import doublePublicRecord, appendToPublicString
.import registerCallbackProc, testCallbackProc, registerCallbackFunc, testCallbackFunc

.segment "JMPTBL"

rts                 ; initialization
nop                 ; pad to three bytes
nop
rts                 ; cleanup
nop                 ; pad to three bytes
nop

publicInt: .res 2
publicArray: .res 2
publicRecord: .res 2
publicString: .res 2

jmp demoArea
jmp doubleParam
jmp biggest
jmp lastChar
jmp sumOfRecord
jmp appendToString
jmp doubleArray
jmp doubleRecord
jmp doublePublicInt
jmp doublePublicArray
jmp doublePublicRecord
jmp appendToPublicString
jmp registerCallbackProc
jmp testCallbackProc
jmp registerCallbackFunc
jmp testCallbackFunc
