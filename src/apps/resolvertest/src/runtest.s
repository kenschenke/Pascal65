;
; runtest.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routines to run a resolver test. The resolver is tested by dumping the symbol table
; to a text file using the dumpsymtab overlay. The dump of the table is compared
; to the table at the start of the source file. The source file must be
; formatted as shown:
;
; (* TestXXX
; Dump of Symbol Table
; ...
; ...
; *)
;
; The first line of the file is ignored. The dump of symbol table starts on the second
; line and continues until "*)" is found at the start of a line.

.include "c64.inc"
.include "ast.inc"
.include "asmlib.inc"
.include "parser.inc"
.include "showtree.inc"
.include "dumpsymtab.inc"
.include "zeropage.inc"
.include "resolver.inc"
.include "tokenizer.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

.export runTest, unitList

.import initTokenizer, initParser, initDumpSymtab, viewDump, getKey, errorCount
.import tokenizeAndParseUnits, initResolver, initShowTree, freeUnits

.bss

ch: .res 1
testNum: .res 2
sourceFn: .res 16
intBuf: .res 10
tokens: .res 4
astRoot: .res 4
symtabBuf: .res 4
sourceBuf: .res 81
dumpBuf: .res 81
eofReached: .res 1
lineNumber: .res 2
foundDiff: .res 1
unitList: .res 4

.data

strFnPrefix: .asciiz "test"
strFnSuffix: .asciiz ".pas"
strDOSSuffix: .asciiz ",s,r"
strEof: .byte "*)", $0d, $0
strDiff: .byte "A line was different. The source line is shown", $0d
         .byte "followed by the dump of the AST.", $0d, $0d, $0
strLineNum: .asciiz "Line number: "
strPrompt: .asciiz "Press return to continue or 'V' to view the dump."
strTitle: .asciiz "Running test "
strBadEof: .asciiz "Unequal number of lines"
strTokenizing: .asciiz " : Tokenizing, "
strParsing: .asciiz "Parsing, "
strResolving: .asciiz "Resolving, "
strDumping: .asciiz "Dumping AST, "
strPass: .asciiz "Pass"
strErrorCount: .asciiz "Parsing errors encountered - press a key"

.code

; This routine runs a resolver test. The test number is in A/X.
; The carry flag is set if the test should inject the system unit
; into the program's global symbol table.
.proc runTest
    sta testNum
    sta intOp1
    stx testNum+1
    stx intOp1+1

    ; Save CPU flags
    php

    ; Reset error count
    lda #0
    sta errorCount

    ; Clear the unit list
    lda #0
    tax
    tay
    taz
    stq unitList
    
    ; Print the "running" title
    lda #<strTitle
    ldx #>strTitle
    jsr printLine

    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    lda #<intBuf
    ldx #>intBuf
    jsr printLine

    ; Format the filename for the tokenizer
    jsr makeSourceFn

    ; Tokenize the source file
    lda #<strTokenizing
    ldx #>strTokenizing
    jsr printLine
    jsr initTokenizer
    lda #<sourceFn
    ldx #>sourceFn
    jsr tokenize
    stq tokens

    ; Parse the tokens
    lda #<strParsing
    ldx #>strParsing
    jsr printLine
    jsr initParser
    ldq unitList
    jsr setParserUnitsList
    ldq tokens
    jsr parse
    stq astRoot
    jsr getParserUnitsList
    stq unitList

    ; Check the error count
    lda errorCount
    beq :+

    ; Show an error message and pause
    jsr errorCountMessage

    ; Free the tokens
:   ldq tokens
    jsr freeMemBuf

    jsr tokenizeAndParseUnits

    lda #<strResolving
    ldx #>strResolving
    jsr printLine
    jsr initResolver
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; jsr initResolve
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldq unitList
    jsr setResolverUnitsList
    jsr initScopeStack
    jsr injectSystemUnit
    plp
    bcc :+
    jsr resolveUnits

:   ldq astRoot

    jsr pushQ
    jsr pushQZero
    jsr declResolve

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; ldq astRoot
    ; jsr astFree
    ; jsr freeUnits
    ; rts
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Free the PROGRAM scope symbol table
    jsr scopeExit
    jsr heapFree

    ldq astRoot
    jsr pushQ
    lda #0
    tax
    jsr pushAX
    lda #0
    jsr pushA
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; lda #'1'
    ; jsr $ffd2
    ; lda #':'
    ; jsr $ffd2
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jsr setDeclOffsets
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; ldq stackPointer
    ; brk
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jsr setUnitOffsets
    ldq astRoot
    jsr fixGlobalOffsets
    ldq astRoot
    jsr verifyFwdDeclarations
    jsr getResolverUnitsList
    stq unitList

    ; Show the AST tree
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; jsr initShowTree
    ; ldq astRoot
    ; ldq unitList
    ; stq ptr1
    ; ldz #unit::astRoot
    ; neg
    ; neg
    ; nop
    ; lda (ptr1),z
    ; jsr showTree
    ; ldq astRoot
    ; jsr astFree
    ; jsr freeUnits
    ; rts
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Dump the symbol table
    jsr initDumpSymtab
    ldq astRoot
    jsr dumpSymtabForDecl
    stq symtabBuf
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; jsr viewDump
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ldq astRoot
    jsr astFree

    jsr freeUnits

    jsr openSourceFile

    ; Rewind the membuf
    ldq symtabBuf
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos

    lda #0
    sta foundDiff
    jsr compareLines

    lda foundDiff
    bne :+
    lda #<strPass
    ldx #>strPass
    jsr printLine

:   lda #13
    jsr CHROUT

    ldq symtabBuf
    jsr freeMemBuf

    rts
.endproc

.proc errorCountMessage
    lda #13
    jsr CHROUT
    jsr CHROUT

    lda #<strErrorCount
    ldx #>strErrorCount
    jsr printLine
    jsr getKey
    rts
.endproc

.proc compareLines
L1: lda eofReached
    bne L2

    jsr readSourceLine
    lda eofReached
    bne L2
    jsr readDumpLine
    lda foundDiff
    bne L2
    jsr compareLine
    bcc L1

:   lda #1
    sta foundDiff

    ; The end of the source file was reached.
    ; Close the file and look if the membuf
    ; is also at the end.
L2: lda #1
    jsr CLOSE
    ldx #0
    jsr CHKIN
    jmp checkMemBufEof
.endproc

; This routine reads lines from the AST membuf until
; the end of the buffer is reached.
; If a non-empty line is found it flags an error.
.proc checkMemBufEof
L1: ldq symtabBuf
    jsr isMemBufAtEnd
    beq L3

    jsr readDumpLine

    ; Is the line empty?
    lda dumpBuf
    cmp #13
    bne L2
    lda dumpBuf+1
    bne L2
    bra L1

    ; A non-empty line was found - that's an error.
L2: lda #13
    jsr CHROUT
    jsr CHROUT
    lda #<strBadEof
    ldx #>strBadEof
    jsr printLine
    lda #13
    jsr CHROUT
    lda #1
    sta foundDiff

L3: rts
.endproc

; This routine compares sourceBuf with dumpBuf.
; If they differ:
;    1) Both lines are shown to the user.
;    2) The line number is shown.
;    3) The user is prompted to press enter to continue
;       or 'V' to view the AST dump.
;
; On exit, the carry flag is set if the lines were different.
; That indicates the current test should stop.
.proc compareLine
    ldx #0

L1: lda sourceBuf,x
    beq L2
    cmp dumpBuf,x
    bne L3
    inx
    bne L1

L2: lda dumpBuf,x
    bne L3
    clc
    rts

    ; The lines are different.
L3: lda #$0d
    jsr CHROUT
    lda #<strDiff
    ldx #>strDiff
    jsr printLine

    lda #<strLineNum
    ldx #>strLineNum
    jsr printLine

    lda lineNumber
    sta intOp1
    lda lineNumber+1
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    lda #<intBuf
    ldx #>intBuf
    jsr printLine
    lda #13
    jsr CHROUT
    jsr CHROUT

    lda #<sourceBuf
    ldx #>sourceBuf
    jsr printLine

    lda #<dumpBuf
    ldx #>dumpBuf
    jsr printLine

    lda #13
    jsr CHROUT
    lda #<strPrompt
    ldx #>strPrompt
    jsr printLine

L4: jsr getKey
    cmp #'v'
    bne :+
    ldq symtabBuf
    jsr viewDump
    jmp L3
:   cmp #'V'
    bne :+
    ldq symtabBuf
    jsr viewDump
    jmp L3
:   cmp #13
    bne L4
    sec
    rts
.endproc

; This routine prints a null-terminated string. The address
; for the line is in A/X.
.proc printLine
    sta ptr1
    stx ptr1+1
    ldy #0

L1: lda (ptr1),y
    beq L2
    jsr CHROUT
    iny
    bne L1

L2: rts
.endproc

; This routine opens the source file and reads the first line
; to reach the dump of the AST.
.proc openSourceFile
    ; Append ",s,r" to the source filename.
    jsr appendDOSSuffix

    ; Call SETLFS
    ldx DEVNUM
    lda #1
    tay
    iny
    jsr SETLFS

    ; Call SETNAM
    jsr setSourceFn

    ; Open the file
    jsr OPEN
    ldx #1
    jsr CHKIN

    lda #0
    sta eofReached

    ; Read the first line
    jsr readSourceLine
    lda #0
    sta lineNumber
    sta lineNumber+1

    rts
.endproc

; This routine formats the source filename using the test number.
; The format is testXXXX.pas and the buffer is null-terminated.
.proc makeSourceFn
    ; Copy the prefix
    ldx #0
:   lda strFnPrefix,x
    beq :+
    sta sourceFn,x
    inx
    bne :-
:   phx                 ; Save the sourceFn index
    ; Format the test number in PETSCII
    lda testNum
    sta intOp1
    lda testNum+1
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    ; Copy the test number into the filename
    plx
    ldy #0
:   lda intBuf,y
    beq :+
    sta sourceFn,x
    inx
    iny
    bne :-
:   ldy #0              ; Copy the suffix
:   lda strFnSuffix,y
    beq :+
    sta sourceFn,x
    inx
    iny
    bne :-
:   ; Null-terminate the filename
    lda #0
    sta sourceFn,x
    rts
.endproc

; This routine appends the DOS suffix of ",s,r" to the source filename.
.proc appendDOSSuffix
    ldx #0
:   lda sourceFn,x
    beq :+
    inx
    bne :-
:   ldy #0
:   lda strDOSSuffix,y
    beq :+
    sta sourceFn,x
    inx
    iny
    bne :-
:   lda #0
    sta sourceFn,x
    rts
.endproc

; This routine calls the Kernal SETNAM routine.
.proc setSourceFn
    ldx #0
:   lda sourceFn,x
    beq :+
    inx
    bne :-
:   txa
    ldx #<sourceFn
    ldy #>sourceFn
    jmp SETNAM
.endproc

; This routine reads a source line from the file.
; It stops when it finds a carriage return.
; The line is stored in sourceBuf and is null-terminated.
.proc readSourceLine
    lda eofReached
    beq :+
    rts

:   ldy #0

L1: jsr CHRIN
    cmp #13
    bne L2
    ; CR found - end of line
    sta sourceBuf,y
    iny
    lda #0
    sta sourceBuf,y
    inc lineNumber
    bne :+
    inc lineNumber+1
:   jmp lookForEof

L2: sta sourceBuf,y
    iny
    bra L1
.endproc

; This routine looks at the last source line and determines
; if is "*)<cr>" which is the end of the dump at the start
; of the source file.
;
; eofReached is set to non-zero if the string matches.
.proc lookForEof
    ldx #0
L1: lda sourceBuf,x
    beq L3          ; Branch if null-termintor found in source buffer
    cmp strEof,x
    bne L2          ; Branch if character does not match
    inx
    bne L1

    ; End of file string does not match
L2: rts

    ; The null-terminator was found in sourceBuf.
    ; Make sure there's also one in strEof
L3: lda strEof,x
    bne :+          ; Branch if strings do not match
    lda #1
    sta eofReached
:   rts
.endproc

; This routine reads a byte from the dump membuf
.proc readByte
    ldq symtabBuf
    stq ptr1

    lda #<ch
    sta ptr2
    lda #>ch
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3

    lda #1
    ldx #0
    jmp readFromMemBuf
.endproc

; This routine reads a line from the AST dump membuf.
; It reads until it reaches a carriage return then
; null-terminates the buffer.
.proc readDumpLine
    lda #0
    pha

L1: ldq symtabBuf
    jsr isMemBufAtEnd
    bne :+
    lda #13
    jsr CHROUT
    jsr CHROUT
    lda #<strBadEof
    ldx #>strBadEof
    jsr printLine
    lda #13
    jsr CHROUT
    lda #1
    sta foundDiff
    pla
    rts
:   jsr readByte
    lda ch
    cmp #13
    bne :+

    ; End of line
    plx
    sta dumpBuf,x
    inx
    lda #0
    sta dumpBuf,x
    rts

:   plx
    sta dumpBuf,x
    inx
    phx
    bra L1
.endproc
