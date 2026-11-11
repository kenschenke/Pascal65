;
; tests1.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Editor tests: editing lines (see tests.inc)

.include "editor.inc"
.include "tests.inc"

.export tests

.data

tests:
    .addr typing, enterMid, joinLines, enterEnd, enterLast
    .addr pascalFirstLine, copyTwice, pasteEmpty
    .addr rightWrap, leftWrap, leftRight, rightAtEnd, leftAtStart
    .addr upDownClamp, upDownEnds, ctrlJK, escJK, deleteSOL
    .addr deleteSOLEnd, deleteSOLStart, deleteEOL, tabStops, insKey
    .addr bsMid, bsEnd, bsFirst, joinNoBuf, joinFits, joinPascal
    .addr splitPascal, quitClean, quitNo, quitYes, enterTop, moveNoBuf
    .addr enterEmptied, pageShort, scrollUpTop, commentOneLine
    .addr commentEmptyLine, oddChars
    .addr 0

; The key scripts

KEYS

keysTyping:
    NEWFILE
    .byte "hello", 0

; Return in the middle of a line splits it
keysEnterMid:
    NEWFILE
    .byte "abcd", LEFT, LEFT, CR, 0

; Backspace in the first column joins the line to the one before
keysJoin:
    NEWFILE
    .byte "ab", CR, "cd", LEFT, LEFT, BS, 0

; Return at the end of a line, then typing on the new line. The new line
; gets no text, so nothing may be copied into it. The first Return makes an
; empty first line (see keysPascalFirst).
keysEnterEnd:
    NEWFILE
    .byte CR, "ab", CR, "cd", CR, "ef", 0

; Return on the last line leaves an empty line
keysEnterLast:
    NEWFILE
    .byte "ab", CR, 0

; Return after typing the first line of an empty Pascal file
keysPascalFirst:
    NEWFILE
    .byte "ab", CR, "cd", 0

; Copying frees the clipboard it replaces
keysCopyTwice:
    NEWFILE
    .byte "ab", SELECT, "c", SELECT, "c", 0

; Pasting an empty line
keysPasteEmpty:
    NEWFILE
    .byte "ab", CR, SELECT, "c", PASTE, 0

; Right at the end of a line moves to the start of the next
keysRightWrap:
    NEWFILE
    .byte "ab", CR, "cd", UP, RIGHT, "x", 0

; Left at the start of a line moves to the end of the one before
keysLeftWrap:
    NEWFILE
    .byte "ab", CR, "cd", HOME, LEFT, "x", 0

; Left and right inside the line being edited
keysLeftRight:
    NEWFILE
    .byte "abc", LEFT, LEFT, "x", RIGHT, "y", 0

; Right at the end of the last line does nothing
keysRightAtEnd:
    NEWFILE
    .byte "ab", RIGHT, "c", 0

; Left at the start of the first line does nothing
keysLeftAtStart:
    NEWFILE
    .byte "ab", HOME, LEFT, "c", 0

; Up and down keep the cursor inside the line
keysUpDownClamp:
    NEWFILE
    .byte "x", CR, "abcd", UP, DOWN, "z", 0

; Down on the last line and up on the first do nothing
keysUpDownEnds:
    NEWFILE
    .byte "ab", DOWN, UP, "c", 0

; Ctrl+J: the first column. Ctrl+K: the end of the line.
keysCtrlJK:
    NEWFILE
    .byte "abc", CTRL_J, "x", CTRL_K, "y", HOME, "z", 0

; Esc J and Esc K are Ctrl+J and Ctrl+K
keysEscJK:
    NEWFILE
    .byte "abc", ESC, "j", "x", ESC, "k", "y", 0

; Esc P deletes to the start of the line
keysDeleteSOL:
    NEWFILE
    .byte "abcd", LEFT, LEFT, ESC, "p", 0

keysDeleteSOLEnd:
    NEWFILE
    .byte "abcd", ESC, "p", 0

keysDeleteSOLStart:
    NEWFILE
    .byte "abcd", HOME, ESC, "p", 0

; Esc Q deletes to the end of the line
keysDeleteEOL:
    NEWFILE
    .byte "abcd", LEFT, LEFT, ESC, "q", 0

; Tab inserts spaces up to the next multiple of four
keysTabStops:
    NEWFILE
    .byte "ab", TABKEY, "c", TABKEY, "d", 0

; Insert puts a space under the cursor
keysInsKey:
    NEWFILE
    .byte "abc", LEFT, LEFT, INS, "x", 0

; Backspace in the middle of a line, at its end and at the very start
keysBsMid:
    NEWFILE
    .byte "abcd", LEFT, BS, 0

keysBsEnd:
    NEWFILE
    .byte "abc", BS, 0

keysBsFirst:
    NEWFILE
    .byte "ab", HOME, BS, 0

; Backspace in the first column with no line being edited
keysJoinNoBuf:
    NEWFILE
    .byte "ab", CR, "cd", UP, DOWN, HOME, BS, 0

; Joining lines when the line before has room for both. Its buffer is
; four bytes, but it holds two.
keysJoinFits:
    NEWFILE
    .byte "abcd", CR, UP, CTRL_K, BS, BS, DOWN, "x", HOME, BS, 0

; Joining lines of a Pascal file
keysJoinPascal:
    NEWFILE
    .byte "ab", CR, "cd", LEFT, LEFT, BS, 0

; Splitting a line of a Pascal file
keysSplitPascal:
    NEWFILE
    .byte "ab cd", LEFT, LEFT, LEFT, CR, 0

; Ctrl+X quits at once if every file is saved. The keys after it aren't
; read.
keysQuitClean:
    NEWFILE
    .byte CTRL_X, "zz", 0

; Ctrl+X asks first if a file isn't saved
keysQuitNo:
    NEWFILE
    .byte "a", CTRL_X, "n", "b", 0

; It quits with the line still in the edit buffer: the change is thrown
; away
keysQuitYes:
    NEWFILE
    .byte "a", CTRL_X, "y", "b", 0

; Return at the start of the first line puts an empty line above it
keysEnterTop:
    NEWFILE
    .byte "ab", HOME, CR, 0

; Left and right with no line in the edit buffer
keysMoveNoBuf:
    NEWFILE
    .byte "abc", CTRL_K, LEFT, LEFT, RIGHT, "x", 0

; Return on a line emptied by backspace, which still has its buffer
keysEnterEmptied:
    NEWFILE
    .byte "a", CR, "b", UP, DOWN, BS, CR, "c", 0

; Paging in a file shorter than the screen
keysPageShort:
    NEWFILE
    .byte "a", CR, "b", CTRL_N, CTRL_P, 0

; Moving up past the top row of the screen scrolls it
keysScrollUpTop:
    NEWFILE
    .byte "a", CR, "b", CR, "c", CTRL_W, UP, UP, 0

; A comment that opens and closes on one line
keysCommentOneLine:
    NEWFILE
    .byte "(* x *) y", 0

; Opening a comment above an empty line and a line that closes it
keysCmtEmpty:
    NEWFILE
    .byte "a", CR, CR, "b*)", UP, UP, HOME, "(*", 0

; Characters the screen and the highlighter see less often
keysOddChars:
    NEWFILE
    .byte "a-b", $7b, $a1, $ff, 0

; The tests. numLines is the number of the last line (one less than the
; number of lines).

TEXT

typing:
    TEST "typing", keysTyping, 0, 5, 0, 0, 1
    .asciiz "hello"
    ENDTEST

enterMid:
    TEST "return in the middle of a line", keysEnterMid, 0, 0, 1, 1, 2
    .asciiz "ab"
    .asciiz "cd"
    ENDTEST

joinLines:
    TEST "backspace joins lines", keysJoin, 0, 2, 0, 0, 1
    .asciiz "abcd"
    ENDTEST

enterEnd:
    TEST "return at end of line", keysEnterEnd, F_PASCAL, 2, 3, 3, 4
    .asciiz ""
    .asciiz "ab"
    .asciiz "cd"
    .asciiz "ef"
    ENDTEST

enterLast:
    TEST "return on the last line", keysEnterLast, 0, 0, 1, 1, 2
    .asciiz "ab"
    .asciiz ""
    ENDTEST

pascalFirstLine:
    TEST "first line of a pascal file", keysPascalFirst, F_PASCAL, 2, 1, 1, 2
    .asciiz "ab"
    .asciiz "cd"
    ENDTEST

copyTwice:
    TEST "copy twice", keysCopyTwice, 0, 2, 0, 0, 1
    .asciiz "ab"
    ENDTEST

pasteEmpty:
    TEST "paste an empty line", keysPasteEmpty, 0, 0, 2, 2, 3
    .asciiz "ab"
    .asciiz ""
    .asciiz ""
    ENDTEST

rightWrap:
    TEST "right wraps", keysRightWrap, 0, 1, 1, 1, 2
    .asciiz "ab"
    .asciiz "xcd"
    ENDTEST

leftWrap:
    TEST "left wraps", keysLeftWrap, 0, 3, 0, 1, 2
    .asciiz "abx"
    .asciiz "cd"
    ENDTEST

leftRight:
    TEST "left and right", keysLeftRight, 0, 4, 0, 0, 1
    .asciiz "axbyc"
    ENDTEST

rightAtEnd:
    TEST "right at the end", keysRightAtEnd, 0, 3, 0, 0, 1
    .asciiz "abc"
    ENDTEST

leftAtStart:
    TEST "left at the start", keysLeftAtStart, 0, 1, 0, 0, 1
    .asciiz "cab"
    ENDTEST

upDownClamp:
    TEST "up and down clamp", keysUpDownClamp, 0, 2, 1, 1, 2
    .asciiz "x"
    .asciiz "azbcd"
    ENDTEST

upDownEnds:
    TEST "up and down at the ends", keysUpDownEnds, 0, 3, 0, 0, 1
    .asciiz "abc"
    ENDTEST

ctrlJK:
    TEST "ctrl+j and ctrl+k", keysCtrlJK, 0, 1, 0, 0, 1
    .asciiz "zxabcy"
    ENDTEST

escJK:
    TEST "esc j and esc k", keysEscJK, 0, 5, 0, 0, 1
    .asciiz "xabcy"
    ENDTEST

deleteSOL:
    TEST "delete to start of line", keysDeleteSOL, 0, 0, 0, 0, 1
    .asciiz "cd"
    ENDTEST

deleteSOLEnd:
    TEST "delete sol at the end", keysDeleteSOLEnd, 0, 0, 0, 0, 1
    .asciiz ""
    ENDTEST

deleteSOLStart:
    TEST "delete sol at the start", keysDeleteSOLStart, 0, 0, 0, 0, 1
    .asciiz "abcd"
    ENDTEST

deleteEOL:
    TEST "delete to end of line", keysDeleteEOL, 0, 2, 0, 0, 1
    .asciiz "ab"
    ENDTEST

tabStops:
    TEST "tab stops", keysTabStops, 0, 9, 0, 0, 1
    .asciiz "ab  c   d"
    ENDTEST

insKey:
    TEST "insert key", keysInsKey, 0, 2, 0, 0, 1
    .asciiz "ax bc"
    ENDTEST

bsMid:
    TEST "backspace in the middle", keysBsMid, 0, 2, 0, 0, 1
    .asciiz "abd"
    ENDTEST

bsEnd:
    TEST "backspace at the end", keysBsEnd, 0, 2, 0, 0, 1
    .asciiz "ab"
    ENDTEST

bsFirst:
    TEST "backspace at the start", keysBsFirst, 0, 0, 0, 0, 1
    .asciiz "ab"
    ENDTEST

joinNoBuf:
    TEST "join with no edit buffer", keysJoinNoBuf, 0, 2, 0, 0, 1
    .asciiz "abcd"
    ENDTEST

joinFits:
    TEST "join into a big buffer", keysJoinFits, 0, 2, 0, 0, 1
    .asciiz "abx"
    ENDTEST

joinPascal:
    TEST "join pascal lines", keysJoinPascal, F_PASCAL, 2, 0, 0, 1
    .asciiz "abcd"
    CHKHL 0, "6666"
    ENDTEST

splitPascal:
    TEST "split a pascal line", keysSplitPascal, F_PASCAL, 0, 1, 1, 2
    .asciiz "ab"
    .asciiz " cd"
    CHKHL 0, "66"
    CHKHL 1, "866"
    ENDTEST

quitClean:
    TEST "quit with no changes", keysQuitClean, 0, 0, 0, 0, 0
    CHKLOOP EDITOR_LOOP_QUIT
    ENDTEST

quitNo:
    TEST "quit, then no", keysQuitNo, 0, 2, 0, 0, 1
    .asciiz "ab"
    ENDTEST

quitYes:
    TEST "quit, then yes", keysQuitYes, 0, 1, 0, 0, 0
    CHKBYTE EDITFILE::dirty, 1
    ENDTEST

enterTop:
    TEST "return at the very start", keysEnterTop, 0, 0, 1, 1, 2
    .asciiz ""
    .asciiz "ab"
    ENDTEST

moveNoBuf:
    TEST "left and right, not editing", keysMoveNoBuf, 0, 3, 0, 0, 1
    .asciiz "abxc"
    ENDTEST

enterEmptied:
    TEST "return on an emptied line", keysEnterEmptied, 0, 1, 2, 2, 3
    .asciiz "a"
    .asciiz ""
    .asciiz "c"
    ENDTEST

pageShort:
    TEST "page in a short file", keysPageShort, 0, 1, 0, 1, 2
    .asciiz "a"
    .asciiz "b"
    CHKWORD EDITFILE::rowOff, 0
    ENDTEST

scrollUpTop:
    TEST "scroll up past the top", keysScrollUpTop, 0, 1, 0, 2, 3
    .asciiz "a"
    .asciiz "b"
    .asciiz "c"
    CHKWORD EDITFILE::rowOff, 0
    ENDTEST

commentOneLine:
    TEST "a comment on one line", keysCommentOneLine, F_PASCAL, 9, 0, 0, 1
    .asciiz "(* x *) y"
    CHKHL 0, "444444486"
    ENDTEST

commentEmptyLine:
    TEST "comment over an empty line", keysCmtEmpty, F_PASCAL, 2, 0, 2, 3
    .asciiz "(*a"
    .asciiz ""
    .asciiz "b*)"
    CHKHL 0, "444"
    CHKHL 2, "444"
    ENDTEST

oddChars:
    TEST "odd characters", keysOddChars, F_PASCAL, 6, 0, 0, 1
    .byte "a-b", $7b, $a1, $ff, 0
    CHKHL 0, "656888"
    ENDTEST
