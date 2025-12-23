.include "ast.inc"
.include "asmlib.inc"
.include "tokenizer.inc"
.include "parser.inc"
.include "resolver.inc"
.include "showtree.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export showAST, unitList

.import initTokenizer, initParser, initResolver, initShowTree
.import tokenizeAndParseUnits

.bss

tokenHeap: .res 4
astRoot: .res 4
unitList: .res 4

.data

sourceFn: .asciiz "source.pas"

.code

.proc showAST
    lda #0
    tax
    tay
    taz
    stq unitList

    jsr initTokenizer
    lda #<sourceFn
    ldx #>sourceFn
    jsr tokenize
    stq tokenHeap

    jsr initParser
    ldq unitList
    jsr setParserUnitsList
    ldq tokenHeap
    jsr parse
    stq astRoot
    jsr getParserUnitsList
    stq unitList

    ldq tokenHeap
    jsr heapFree

    jsr tokenizeAndParseUnits

    jsr initResolver
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jsr initResolve
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldq unitList
    jsr setResolverUnitsList
    jsr initScopeStack
    jsr injectSystemUnit
    jsr resolveUnits

    ldq astRoot
    jsr pushQ
    jsr pushQZero
    jsr declResolve
    ldq astRoot
    jsr pushQ
    lda #0
    tax
    jsr pushAX
    lda #0
    jsr pushA
    jsr setDeclOffsets
    jsr setUnitOffsets
    ldq astRoot
    jsr fixGlobalOffsets
    ldq astRoot
    jsr verifyFwdDeclarations
    jsr getResolverUnitsList
    stq unitList

    jsr initShowTree
    ldq astRoot
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; ldq unitList
    ; stq ptr1
    ; ldz #unit::astRoot
    ; neg
    ; neg
    ; nop
    ; lda (ptr1),z
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jsr showTree

    rts
.endproc
