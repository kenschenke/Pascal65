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
.import scratchFile, renameFile, makeFilename, doesFileExist, readInt32, leUint32
.import initRuntimeStack, rtPushA, rtPushAX, rtPushQ, rtPopA, rtPopAX, rtPopQ
.import rtInitCompilerErrors, rtCompilerError, isQZero, rtPushQZero
.import invertInt16, invertInt32, runtimeError, multInt16
.import initScopeStack, scopeBind, scopeBindSymtab, scopeLevel, scopeLookup, scopeLookupParent
.import scopeEnter, scopeEnterSymtab, scopeExit, symtabLookup
.import declCreate, nameCreate, paramListCreate, typeCreate, stmtCreate
.import exprCreate, unitCreate, nameClone, freeAst
.import addTreeNode, findInTree, freeTree, symbolCreate
.import typeClone, freeType, freeSymbol, isHeapAllocated, writeInt32, divInt32
.import rtPushBlock, rtPopBlock, isConcatOperand, getBaseType, freeSymtab

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
jmp scratchFile
jmp renameFile
jmp makeFilename
jmp doesFileExist
jmp readInt32
jmp leUint32
jmp initRuntimeStack
jmp rtPushA
jmp rtPushAX
jmp rtPushQ
jmp rtPopA
jmp rtPopAX
jmp rtPopQ
jmp rtInitCompilerErrors
jmp rtCompilerError
jmp isQZero
jmp rtPushQZero
jmp invertInt16
jmp invertInt32
jmp runtimeError
jmp multInt16
jmp initScopeStack
jmp scopeBind
jmp scopeBindSymtab
jmp scopeLevel
jmp scopeLookup
jmp scopeLookupParent
jmp scopeEnter
jmp scopeEnterSymtab
jmp scopeExit
jmp symtabLookup
jmp declCreate
jmp nameCreate
jmp paramListCreate
jmp typeCreate
jmp stmtCreate
jmp exprCreate
jmp unitCreate
jmp nameClone
jmp freeAst
jmp addTreeNode
jmp findInTree
jmp freeTree
jmp symbolCreate
jmp typeClone
jmp freeType
jmp freeSymbol
jmp isHeapAllocated
jmp writeInt32
jmp divInt32
jmp rtPushBlock
jmp rtPopBlock
jmp isConcatOperand
jmp getBaseType
jmp freeSymtab
