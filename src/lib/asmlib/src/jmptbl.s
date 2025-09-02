;
; jmptbl.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; ASM LIB jump table

.import allocMemBuf, freeMemBuf, getMemBufPos, readFromMemBuf, setMemBufPos
.import writeToMemBuf, getline, addInt16, eqInt16, leInt16, ltInt16, gtInt16
.import geInt16, subInt16, initMemHeap, heapAlloc, heapFree, ltUint16
.import geUint32, writeInt16, _exit, isMemBufAtEnd

.segment "JMPTBL"

jmp allocMemBuf
jmp freeMemBuf
jmp getMemBufPos
jmp readFromMemBuf
jmp setMemBufPos
jmp writeToMemBuf
jmp getline
jmp addInt16
jmp eqInt16
jmp leInt16
jmp ltInt16
jmp gtInt16
jmp geInt16
jmp subInt16
jmp initMemHeap
jmp heapAlloc
jmp heapFree
jmp ltUint16
jmp geUint32
jmp writeInt16
jmp isMemBufAtEnd
jmp _exit
