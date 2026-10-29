;
; testhdr.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Tests the pre-compiled library headers. For each library unit, the unit's
; .pas file is tokenized and parsed and the AST is dumped with the dumpast
; overlay. The unit's .hdr file is then loaded and its AST is dumped the same
; way. The two dumps must be identical.

.include "c64.inc"
.include "asmlib.inc"
.include "parser.inc"
.include "dumpast.inc"
.include "zeropage.inc"
.include "tokenizer.inc"
.include "cbm_kernal.inc"
.include "ast.inc"
.include "4510macros.inc"

KEYBUF = $d610
MAX_LINE = 200

.export runTests, unitList

.import initTokenizer, initParser, initDumpAst, errorCount, loadHeader

.bss

unitIdx: .res 1
srcFn: .res 20
hdrFn: .res 20
unitList: .res 4
tokens: .res 4
astRoot: .res 4
dumpSrc: .res 4             ; dump of the AST parsed from the .pas file
dumpHdr: .res 4             ; dump of the AST loaded from the .hdr file
rlBuf: .res 4               ; membuf readLine reads from
rlIdx: .res 1
ch: .res 1
eofSrc: .res 1
eofHdr: .res 1
foundDiff: .res 1
lineNumber: .res 2
lineSrc: .res MAX_LINE+2
lineBuf: .res MAX_LINE+2
intBuf: .res 10
passCount: .res 1
failCount: .res 1

.data

unitNames:
    .word nameSystem, nameScreen, nameSprites, nameSpriteMove, nameTime
    .word 0
nameSystem: .asciiz "system"
nameScreen: .asciiz "screen"
nameSprites: .asciiz "sprites"
nameSpriteMove: .asciiz "spritemove"
nameTime: .asciiz "time"

dummyUnit: .asciiz "testhdr"
strPas: .asciiz ".pas"
strHdr: .asciiz ".hdr"
strTesting: .asciiz "Testing "
strParsing: .asciiz " : Parsing, "
strDumping: .asciiz "Dumping, "
strLoading: .asciiz "Loading header, "
strPass: .asciiz "Pass"
strFail: .asciiz "FAIL"
strParseErrors: .asciiz "Parsing errors encountered - press a key"
strNoHeader: .asciiz "Could not load the header - press a key"
strDiff: .byte "A line was different. The line from the", $0d
         .byte "source is shown followed by the header.", $0d, $0d, $0
strLineNum: .asciiz "Line number: "
strBadEof: .asciiz "Unequal number of lines"
strPrompt: .asciiz "Press a key to continue."
strPassed: .asciiz " passed, "
strFailed: .asciiz " failed."

.code

; Run the test for each library unit
.proc runTests
    lda #0
    sta unitIdx
    sta passCount
    sta failCount

Next:
    lda unitIdx
    asl
    tax
    lda unitNames,x
    sta ptr1
    lda unitNames+1,x
    sta ptr1+1
    ora ptr1
    beq Done
    jsr runTest
    inc unitIdx
    bra Next

Done:
    lda #13
    jsr CHROUT
    lda passCount
    jsr printByte
    lda #<strPassed
    ldx #>strPassed
    jsr printLine
    lda failCount
    jsr printByte
    lda #<strFailed
    ldx #>strFailed
    jsr printLine
    lda #13
    jsr CHROUT
    rts
.endproc

; Test one unit. ptr1 points to its null-terminated name.
.proc runTest
    jsr makeFilenames

    lda #<strTesting
    ldx #>strTesting
    jsr printLine
    lda #<srcFn
    ldx #>srcFn
    jsr printLine
    lda #<strParsing
    ldx #>strParsing
    jsr printLine

    lda #0
    sta foundDiff
    sta errorCount

    ; Tokenize the source
    jsr initTokenizer
    lda #<srcFn
    ldx #>srcFn
    jsr tokenize
    stq tokens
    jsr isQZero
    bne :+
    jmp Failed

    ; The parser adds the System unit implicitly when the unit list is
    ; empty. Seed the list with a placeholder so the unit is parsed alone.
:   lda #<dummyUnit
    ldx #>dummyUnit
    jsr unitCreate
    stq unitList

    jsr initParser
    jsr parserInit
    ldq unitList
    jsr setParserUnitsList
    ldq tokens
    jsr parse
    stq astRoot
    jsr getParserUnitsList
    stq unitList
    ldq tokens
    jsr freeMemBuf

    lda errorCount
    beq :+
    lda #<strParseErrors
    ldx #>strParseErrors
    jsr printLine
    jsr getKey
    ldq astRoot
    jsr astFree
    jmp Failed

    ; Dump the AST parsed from source
:   lda #<strDumping
    ldx #>strDumping
    jsr printLine
    jsr initDumpAst
    ldq astRoot
    jsr dumpAst
    stq dumpSrc
    ldq astRoot
    jsr astFree

    ; Load the header and dump it
    lda #<strLoading
    ldx #>strLoading
    jsr printLine
    lda #<hdrFn
    ldx #>hdrFn
    jsr loadHeader
    bcs :+
    lda #13
    jsr CHROUT
    lda #<strNoHeader
    ldx #>strNoHeader
    jsr printLine
    jsr getKey
    ldq dumpSrc
    jsr freeMemBuf
    jmp Failed

:   stq astRoot
    jsr dumpAst
    stq dumpHdr
    ldq astRoot
    jsr astFree

    ; Compare the dumps
    jsr compareDumps

    ldq dumpSrc
    jsr freeMemBuf
    ldq dumpHdr
    jsr freeMemBuf

    ; Free the placeholder unit
    ldq unitList
    jsr heapFree

    lda foundDiff
    bne Failed
    lda #<strPass
    ldx #>strPass
    jsr printLine
    lda #13
    jsr CHROUT
    inc passCount
    rts

Failed:
    lda #<strFail
    ldx #>strFail
    jsr printLine
    lda #13
    jsr CHROUT
    inc failCount
    rts
.endproc

; Compare the two dumps line by line. Sets foundDiff if they differ.
.proc compareDumps
    ; Rewind both membufs
    ldq dumpSrc
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos
    ldq dumpHdr
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos

    lda #0
    sta lineNumber
    sta lineNumber+1

Next:
    ; Read a line from each dump
    ldq dumpSrc
    stq rlBuf
    jsr readLine
    lda #0
    rol
    sta eofSrc
    ldx #0
:   lda lineBuf,x
    sta lineSrc,x
    beq :+
    inx
    bne :-
:   ldq dumpHdr
    stq rlBuf
    jsr readLine
    lda #0
    rol
    sta eofHdr

    lda eofSrc
    and eofHdr
    bne Done                    ; both ended together
    lda eofSrc
    eor eofHdr
    bne BadEof                  ; one ended before the other

    inc lineNumber
    bne :+
    inc lineNumber+1
:   ldx #0
:   lda lineSrc,x
    cmp lineBuf,x
    bne ShowDiff
    cmp #0
    beq Next                    ; same line
    inx
    bne :-
    bra ShowDiff

Done:
    rts

BadEof:
    lda #13
    jsr CHROUT
    lda #<strBadEof
    ldx #>strBadEof
    jsr printLine
    lda #13
    jsr CHROUT
    lda #1
    sta foundDiff
    rts

ShowDiff:
    lda #1
    sta foundDiff
    lda #13
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
    lda #<lineSrc
    ldx #>lineSrc
    jsr printLine
    lda #<lineBuf
    ldx #>lineBuf
    jsr printLine
    lda #13
    jsr CHROUT
    lda #<strPrompt
    ldx #>strPrompt
    jsr printLine
    lda #13
    jsr CHROUT
    jmp getKey
.endproc

; Read a line from the membuf in rlBuf into lineBuf, null-terminated. The
; carriage return is kept, as in the dump.
; Carry is set (and lineBuf is empty) if the membuf was already at its end.
.proc readLine
    lda #0
    sta rlIdx
    sta lineBuf

Next:
    ldq rlBuf
    jsr isMemBufAtEnd
    bne More                    ; not at the end

    ; At the end. If nothing was read, report end of buffer.
    lda rlIdx
    beq :+
    clc
    rts
:   sec
    rts

More:
    ldq rlBuf
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
    jsr readFromMemBuf

    ldx rlIdx
    lda ch
    sta lineBuf,x
    inx
    stx rlIdx
    lda #0
    sta lineBuf,x
    lda ch
    cmp #13
    beq Eol
    cpx #MAX_LINE
    bne Next
Eol:
    clc
    rts
.endproc

; Format srcFn and hdrFn from the unit name in ptr1
.proc makeFilenames
    ldy #0
:   lda (ptr1),y
    beq :+
    sta srcFn,y
    sta hdrFn,y
    iny
    bne :-
:   ldx #0
:   lda strPas,x
    sta srcFn,y
    lda strHdr,x
    sta hdrFn,y
    beq :+
    iny
    inx
    bne :-
:   rts
.endproc

; Print the null-terminated string in A/X
.proc printLine
    sta ptr1
    stx ptr1+1
    ldy #0
:   lda (ptr1),y
    beq :+
    jsr CHROUT
    iny
    bne :-
:   rts
.endproc

; Print the byte in A in decimal
.proc printByte
    sta intOp1
    lda #0
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    lda #<intBuf
    ldx #>intBuf
    jmp printLine
.endproc

.proc getKey
:   ldx KEYBUF
    beq :-
    lda #0
    sta KEYBUF
    rts
.endproc
