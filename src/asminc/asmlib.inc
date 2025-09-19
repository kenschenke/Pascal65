;
; asmlib.inc
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; ASM LIB entry points

ASMBASE = $a000

allocMemBuf = ASMBASE + 0
freeMemBuf = ASMBASE + 3
getMemBufPos = ASMBASE + 6
readFromMemBuf = ASMBASE + 9
setMemBufPos = ASMBASE + 12
writeToMemBuf = ASMBASE + 15
getline = ASMBASE + 18
addInt16 = ASMBASE + 21
eqInt16 = ASMBASE + 24
leInt16 = ASMBASE + 27
ltInt16 = ASMBASE + 30
gtInt16 = ASMBASE + 33
geInt16 = ASMBASE + 36
subInt16 = ASMBASE + 39
initMemHeap = ASMBASE + 42
heapAlloc = ASMBASE + 45
heapFree = ASMBASE + 48
ltUint16 = ASMBASE + 51
geUint32 = ASMBASE + 54
writeInt16 = ASMBASE + 57
isMemBufAtEnd = ASMBASE + 60
_exit = ASMBASE + 63
scratchFile = ASMBASE + 66
renameFile = ASMBASE + 69
makeFilename = ASMBASE + 72
doesFileExist = ASMBASE + 75
readInt32 = ASMBASE + 78
leUint32 = ASMBASE + 81
stackInit = ASMBASE + 84
pushA = ASMBASE + 87
pushAX = ASMBASE + 90
pushQ = ASMBASE + 93
popA = ASMBASE + 96
popAX = ASMBASE + 99
popQ = ASMBASE + 102
initCompilerErrors = ASMBASE + 105
compilerError = ASMBASE + 108
