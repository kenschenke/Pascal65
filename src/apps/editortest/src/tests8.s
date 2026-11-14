;
; tests8.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Editor tests: the line of the entry the build line shows is highlighted
; (calcBuildHighlight in buildnav.s, editorDrawRows in screen.s). Every
; column of its row is reversed, in the theme's error or warning color
; (COLOR_* in tests.inc). The cursor on it is the character not reversed,
; in the cursor color.
;
; The disk's files are in the order OPENFILE gives: hello.txt (2 lines) is
; row 2 and lines200.txt (lines "1" to "200") row 3. Neither is a Pascal
; file, so their text is in the UI color. With 25 rows there are 22 text
; rows.

.include "editor.inc"
.include "buildresult.inc"
.include "tests.inc"

.export tests

F9 = CH_F9
F11 = CH_F11

.data

tests:
    .addr errorLine, warningLine, cursorLeaves, scrolledOff, scrolledBack
    .addr typing, noFile, otherFile, rows50
    .addr 0

; The key scripts

KEYS

; lines200.txt, then the first entry: line 10
keysFirst:
    OPENFILE 3
    .byte F11, 0

; On to the second: line 12, a warning
keysSecond:
    OPENFILE 3
    .byte F11, F11, 0

keysLeave:
    OPENFILE 3
    .byte F11, DOWN, 0

; Line 10 scrolls off the top
keysOff:
    OPENFILE 3
    .byte F11
    .repeat 25
        .byte DOWN
    .endrep
    .byte 0

; And back to the top row
keysBack:
    OPENFILE 3
    .byte F11
    .repeat 25
        .byte DOWN
    .endrep
    .repeat 25
        .byte UP
    .endrep
    .byte 0

; An edit in the line keeps it highlighted
keysTyping:
    OPENFILE 3
    .byte F11, "x", 0

; hello.txt's line 1, then an entry with no file
keysNoFile:
    OPENFILE 2
    .byte F11, F11, 0

; lines200.txt's line 5, then hello.txt is opened
keysOther:
    OPENFILE 3
    .byte F11
    OPENFILE 2
    .byte 0

keysRows50:
    .byte ESC, "5", F11, 0

; The tests

TEXT

errorLine:
    TEST "error line", keysFirst, F_SKIPLINES, 0, 9, 200, 0, buildLines
    CHKWORD EDITFILE::rowOff, 0
    CHKSCREEN 9, 0, "10 "
    CHKATTR 9, 0, 1, 0, COLOR_CURSOR
    CHKATTR 9, 1, 79, 1, COLOR_ERROR
    CHKATTR 8, 0, 80, 0, COLOR_UI
    CHKATTR 10, 0, 80, 0, COLOR_UI
    ENDTEST

; The old line is drawn again without the highlight
warningLine:
    TEST "warning line", keysSecond, F_SKIPLINES, 0, 11, 200, 0, buildLines
    CHKWORD EDITFILE::rowOff, 0
    CHKSCREEN 11, 0, "12 "
    CHKATTR 11, 0, 1, 0, COLOR_CURSOR
    CHKATTR 11, 1, 79, 1, COLOR_WARNING
    CHKATTR 9, 0, 80, 0, COLOR_UI
    ENDTEST

; Erasing the cursor reverses its character again
cursorLeaves:
    TEST "cursor leaves", keysLeave, F_SKIPLINES, 0, 10, 200, 0, buildLines
    CHKATTR 9, 0, 80, 1, COLOR_ERROR
    CHKATTR 10, 0, 1, 1, COLOR_CURSOR
    CHKATTR 10, 1, 79, 0, COLOR_UI
    ENDTEST

; No row is highlighted
scrolledOff:
    TEST "line scrolled off", keysOff, F_SKIPLINES, 0, 34, 200, 0, buildLines
    CHKWORD EDITFILE::rowOff, 13
    CHKSCREEN 0, 0, "14 "
    CHKATTR 0, 0, 80, 0, COLOR_UI
    CHKATTR 9, 0, 80, 0, COLOR_UI
    CHKATTR 20, 0, 80, 0, COLOR_UI
    ENDTEST

scrolledBack:
    TEST "line scrolled back", keysBack, F_SKIPLINES, 0, 9, 200, 0, buildLines
    CHKWORD EDITFILE::rowOff, 9
    CHKSCREEN 0, 0, "10 "
    CHKATTR 0, 0, 1, 0, COLOR_CURSOR
    CHKATTR 0, 1, 79, 1, COLOR_ERROR
    CHKATTR 1, 0, 80, 0, COLOR_UI
    ENDTEST

typing:
    TEST "typing in the line", keysTyping, F_SKIPLINES, 1, 9, 200, 0, buildLines
    CHKLINE 9, "x10"
    CHKSCREEN 9, 0, "x10 "
    CHKATTR 9, 0, 1, 1, COLOR_ERROR
    CHKATTR 9, 1, 1, 0, COLOR_CURSOR
    CHKATTR 9, 2, 78, 1, COLOR_ERROR
    ENDTEST

; The editor doesn't move, but the highlight goes
noFile:
    TEST "entry with no file", keysNoFile, 0, 0, 0, 2, 2, buildNoFile
    .asciiz "hello"
    .asciiz "world"
    CHKBUILD BUILDRESULT::current, 1
    CHKATTR 0, 0, 1, 1, COLOR_CURSOR
    CHKATTR 0, 1, 79, 0, COLOR_UI
    ENDTEST

otherFile:
    TEST "entry in another file", keysOther, 0, 0, 0, 2, 2, buildLines5
    .asciiz "hello"
    .asciiz "world"
    CHKNAME "hello.txt"
    CHKFILES 2
    CHKBUILD BUILDRESULT::current, 0
    CHKATTR 0, 1, 79, 0, COLOR_UI
    CHKATTR 1, 0, 80, 0, COLOR_UI
    ENDTEST

; Line 100 is row 23 of 47
rows50:
    TEST "50 rows", keysRows50, F_SKIPLINES, 0, 99, 200, 0, buildLines100
    CHKWORD EDITFILE::rowOff, 76
    CHKSCREEN 23, 0, "100 "
    CHKATTR 23, 0, 1, 0, COLOR_CURSOR
    CHKATTR 23, 1, 79, 1, COLOR_ERROR
    CHKATTR 22, 0, 80, 0, COLOR_UI
    CHKATTR 24, 0, 80, 0, COLOR_UI
    ENDTEST

; The build results

buildLines:
    BUILD BUILD_FAILED, 1, 1, BUILD_SUMMARY
    BFILE "lines200.txt"
    BENTRY BUILD_ERROR, 0, 10, msgError
    BENTRY BUILD_WARNING, 0, 12, msgWarning
    ENDBUILD

buildLines5:
    BUILD BUILD_FAILED, 1, 0, BUILD_SUMMARY
    BFILE "lines200.txt"
    BENTRY BUILD_ERROR, 0, 5, msgError
    ENDBUILD

buildLines100:
    BUILD BUILD_FAILED, 1, 0, BUILD_SUMMARY
    BFILE "lines200.txt"
    BENTRY BUILD_ERROR, 0, 100, msgError
    ENDBUILD

buildNoFile:
    BUILD BUILD_FAILED, 1, 1, BUILD_SUMMARY
    BFILE "hello.txt"
    BENTRY BUILD_ERROR, 0, 1, msgError
    BENTRY BUILD_WARNING, BUILD_FILE_UNKNOWN, 5, msgWarning
    ENDBUILD

msgError: .asciiz "an error"
msgWarning: .asciiz "a warning"
