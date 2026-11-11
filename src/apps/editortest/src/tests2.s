;
; tests2.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Editor tests: opening files, moving around a long file and syntax
; highlighting (see tests.inc)

.include "editor.inc"
.include "tests.inc"

.export tests

.data

tests:
    .addr openHello, openNoEol, openPascal, ctrlE, ctrlB, pageDown
    .addr pageUp, pageDownEnd, scrollW, scrollV, ctrlWPastEnd, ctrlBEdit
    .addr ctrlEEdit, lineAfterLast, ctrlKAfterLast, rightAfterLast
    .addr rows50, commentEmpty, highlight, openLong
    .addr 0

; The key scripts

KEYS

keysOpenHello:
    OPENFILE 2
    .byte 0

; A file that doesn't end with a CR
keysOpenNoEol:
    OPENFILE 4
    .byte 0

keysOpenPascal:
    OPENFILE 5
    .byte 0

; lines200.txt has the lines 1 to 200. Ctrl+E goes to the bottom.
keysCtrlE:
    OPENFILE 3
    .byte CTRL_E, 0

; Ctrl+B goes to the top
keysCtrlB:
    OPENFILE 3
    .byte CTRL_E, CTRL_B, 0

; Ctrl+N and Esc Down page down
keysPageDown:
    OPENFILE 3
    .byte CTRL_N, ESC, DOWN, 0

; Ctrl+P and Esc Up page up
keysPageUp:
    OPENFILE 3
    .byte CTRL_N, CTRL_N, ESC, UP, 0

; Paging down stops at the end of the file
keysPageDownEnd:
    OPENFILE 3
    .repeat 9
        .byte CTRL_N
    .endrep
    .byte 0

; Ctrl+W and Esc W scroll down a line. Ctrl+V scrolls up a line, but not
; above the top.
keysScrollW:
    OPENFILE 3
    .byte CTRL_V, CTRL_W, ESC, "w", CTRL_V, 0

; Ctrl+V keeps the cursor on the screen
keysScrollV:
    OPENFILE 3
    .byte CTRL_N
    .repeat 22
        .byte DOWN
    .endrep
    .byte CTRL_V, 0

; Ctrl+W doesn't scroll past the end of the file
keysCtrlWPastEnd:
    NEWFILE
    .byte "a", CTRL_W, CTRL_W, 0

; Ctrl+B and Ctrl+E with a line in the edit buffer
keysCtrlBEdit:
    NEWFILE
    .byte "a", CR, "b", CTRL_B, "x", 0

keysCtrlEEdit:
    NEWFILE
    .byte "a", CR, "b", UP, "x", CTRL_E, "y", 0

; A file read from the disk can have the cursor on the line after its last
; line. Typing there adds a line.
keysLineAfterLast:
    OPENFILE 2
    .byte DOWN, CTRL_K, DOWN, "x", 0

keysCtrlKAfterLast:
    OPENFILE 2
    .byte CTRL_E, CTRL_K, "x", 0

keysRightAfterLast:
    OPENFILE 2
    .byte CTRL_E, RIGHT, "x", 0

; Esc 5 shows 50 rows, so a page is 48 lines. Esc 8 goes back to 25.
keysRows50:
    OPENFILE 3
    .byte ESC, "5", CTRL_N, ESC, "8", 0

; Deleting the last character of a line inside a comment. "(*" opens a
; comment that continues on the next line.
keysCommentEmpty:
    NEWFILE
    .byte "a", CR, "b", UP, HOME, "(*", DOWN, CTRL_K, BS, 0

; A line longer than the editor allows is cut off
keysOpenLong:
    OPENFILE 7
    .byte 0

keysHighlight:
    NEWFILE
    .byte "BEGIN abcdefghijklmnopq", CR
    .byte "'ab", CR
    .byte "$a %x $ .5 1e5 2.5e-3;", CR
    .byte "x//y", CR
    .byte "(a) a.b", 0

; The tests

TEXT

openHello:
    TEST "open a file", keysOpenHello, 0, 0, 0, 2, 2
    .asciiz "hello"
    .asciiz "world"
    CHKNAME "hello.txt"
    CHKFILES 1
    CHKBYTE EDITFILE::dirty, 0
    CHKBYTE EDITFILE::isPascal, 0
    CHKBYTE EDITFILE::readOnly, 0
    ENDTEST

openNoEol:
    TEST "open a file without a cr", keysOpenNoEol, 0, 0, 0, 1, 1
    .asciiz "abc"
    ENDTEST

openPascal:
    TEST "open a pascal file", keysOpenPascal, 0, 0, 0, 8, 8
    .asciiz "program p;"
    .asciiz "(* a"
    .asciiz "b *) x"
    .asciiz "var i: integer; // c"
    .asciiz "begin"
    .asciiz "i := $1f + %101 + 12.5e3;"
    .asciiz "writeln('it''s', 1..2, #65);"
    .asciiz "end."
    CHKBYTE EDITFILE::isPascal, 1
    CHKHL 0, "2222222865"
    CHKHL 1, "4444"
    CHKHL 2, "444486"
    CHKHL 3, "22286582222222584444"
    CHKHL 4, "22222"
    CHKHL 5, "6855811185811118581111115"
    CHKHL 6, "6666666533333335815515881155"
    CHKHL 7, "2225"
    ENDTEST

ctrlE:
    TEST "ctrl+e", keysCtrlE, F_SKIPLINES, 0, 200, 200, 0
    CHKWORD EDITFILE::rowOff, 178
    CHKLINE 199, "200"
    ENDTEST

ctrlB:
    TEST "ctrl+b", keysCtrlB, F_SKIPLINES, 0, 0, 200, 0
    CHKWORD EDITFILE::rowOff, 0
    ENDTEST

pageDown:
    TEST "page down", keysPageDown, F_SKIPLINES, 0, 46, 200, 0
    CHKWORD EDITFILE::rowOff, 46
    CHKLINE 46, "47"
    ENDTEST

pageUp:
    TEST "page up", keysPageUp, F_SKIPLINES, 0, 23, 200, 0
    CHKWORD EDITFILE::rowOff, 23
    ENDTEST

pageDownEnd:
    TEST "page down to the end", keysPageDownEnd, F_SKIPLINES, 0, 200, 200, 0
    CHKWORD EDITFILE::rowOff, 178
    ENDTEST

scrollW:
    TEST "scroll a line", keysScrollW, F_SKIPLINES, 0, 2, 200, 0
    CHKWORD EDITFILE::rowOff, 1
    ENDTEST

scrollV:
    TEST "scroll up a line", keysScrollV, F_SKIPLINES, 0, 44, 200, 0
    CHKWORD EDITFILE::rowOff, 22
    ENDTEST

ctrlWPastEnd:
    TEST "scroll past the end", keysCtrlWPastEnd, 0, 1, 0, 0, 1
    .asciiz "a"
    CHKWORD EDITFILE::rowOff, 0
    ENDTEST

ctrlBEdit:
    TEST "ctrl+b while editing", keysCtrlBEdit, 0, 1, 0, 1, 2
    .asciiz "xa"
    .asciiz "b"
    ENDTEST

ctrlEEdit:
    TEST "ctrl+e while editing", keysCtrlEEdit, 0, 1, 1, 1, 2
    .asciiz "ax"
    .asciiz "yb"
    ENDTEST

lineAfterLast:
    TEST "type after the last line", keysLineAfterLast, 0, 1, 2, 2, 3
    .asciiz "hello"
    .asciiz "world"
    .asciiz "x"
    ENDTEST

ctrlKAfterLast:
    TEST "ctrl+k after the last line", keysCtrlKAfterLast, 0, 1, 2, 2, 3
    .asciiz "hello"
    .asciiz "world"
    .asciiz "x"
    ENDTEST

rightAfterLast:
    TEST "right after the last line", keysRightAfterLast, 0, 1, 2, 2, 3
    .asciiz "hello"
    .asciiz "world"
    .asciiz "x"
    ENDTEST

rows50:
    TEST "50 rows", keysRows50, F_SKIPLINES, 0, 48, 200, 0
    CHKWORD EDITFILE::rowOff, 48
    ENDTEST

commentEmpty:
    TEST "empty line in a comment", keysCommentEmpty, F_PASCAL, 0, 1, 1, 2
    .asciiz "(*a"
    .asciiz ""
    CHKHL 0, "444"
    ENDTEST

highlight:
    TEST "highlighting", keysHighlight, F_PASCAL, 7, 4, 4, 5
    .asciiz "BEGIN abcdefghijklmnopq"
    .asciiz "'ab"
    .asciiz "$a %x $ .5 1e5 2.5e-3;"
    .asciiz "x//y"
    .asciiz "(a) a.b"
    CHKHL 0, "22222866666666666666666"
    CHKHL 1, "333"
    CHKHL 2, "1188688811816681111115"
    CHKHL 3, "6444"
    CHKHL 4, "5658656"
    ENDTEST

openLong:
    TEST "open a file with a long line", keysOpenLong, 0, 0, 0, 2, 2
    .repeat 8
        .byte "0123456789"
    .endrep
    .byte 0
    .asciiz "end"
    ENDTEST
