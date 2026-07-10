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

; Magic File Handles
; Used by read/write routines that are called by read/readln/write/writeln
FH_STDIO   = $80    ; Use screen/keyboard for IO
FH_STRING  = $81    ; Use string for IO
FH_FILENUM = $82    ; File handle is on stack

ASMBASE = $9000

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
isQZero = ASMBASE + 111
pushQZero = ASMBASE + 114
invertInt16 = ASMBASE + 117
invertInt32 = ASMBASE + 120
runtimeError = ASMBASE + 123
multInt16 = ASMBASE + 126
initScopeStack = ASMBASE + 129
scopeBind = ASMBASE + 132
scopeBindSymtab = ASMBASE + 135
scopeLevel = ASMBASE + 138
scopeLookup = ASMBASE + 141
scopeLookupParent = ASMBASE + 144
scopeEnter = ASMBASE + 147
scopeEnterSymtab = ASMBASE + 150
scopeExit = ASMBASE + 153
symtabLookup = ASMBASE + 156
declCreate = ASMBASE + 159
nameCreate = ASMBASE + 162
paramListCreate = ASMBASE + 165
typeCreate = ASMBASE + 168
stmtCreate = ASMBASE + 171
exprCreate = ASMBASE + 174
unitCreate = ASMBASE + 177
nameClone = ASMBASE + 180
astFree = ASMBASE + 183
addTreeNode = ASMBASE + 186
findInTree = ASMBASE + 189
freeTree = ASMBASE + 192
symbolCreate = ASMBASE + 195
typeClone = ASMBASE + 198
freeType = ASMBASE + 201
freeSymbol = ASMBASE + 204
isHeapAllocatedUnused = ASMBASE + 207
writeInt32 = ASMBASE + 210
divInt32 = ASMBASE + 213
pushBlock = ASMBASE + 216
popBlock = ASMBASE + 219
isConcatOperand = ASMBASE + 222
getBaseType = ASMBASE + 225
freeSymtab = ASMBASE + 228
hexstr = ASMBASE + 231
linkAddressLookup = ASMBASE + 234
linkAddressSet = ASMBASE + 237
initLinkerTags = ASMBASE + 240
freeLinkerTags = ASMBASE + 243
getLinkerTagsToFind = ASMBASE + 246
findLinkerTag = ASMBASE + 249
