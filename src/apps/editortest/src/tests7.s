;
; tests7.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Editor tests: stepping through the build's errors and warnings with F11
; (next) and F9 (previous) (buildnav.s). With 25 rows there are 22 text
; rows, so a line is centered with rowOff 11 lines above it. With 50 rows
; there are 47 and rowOff is 23 lines above.
;
; The disk's files are in the order OPENFILE gives: hello.txt (2 lines) is
; row 2 and lines200.txt (lines "1" to "200") row 3.

.include "editor.inc"
.include "buildresult.inc"
.include "tests.inc"

.export tests

F9 = CH_F9
F11 = CH_F11

.data

tests:
    .addr noEntries, noEntriesSuccess, fromTitle, twoFiles, backToOpen
    .addr wrapAround, missingFile, lineZero, pastEnd, noFileOpen, rows50
    .addr ignoredCodes
    .addr 0

; The key scripts

KEYS

keysNoEntries:
    NEWFILE
    .byte "a", F11, F9, 0

; The title screen is showing
keysNext:
    .byte F11, 0

; hello.txt, then lines200.txt (not open), back to hello.txt and on to
; lines200.txt, now open. The edit in progress is kept.
keysTwoFiles:
    OPENFILE 2
    .byte "x", F11, F11, F11, 0

; The selection is cleared. F9 from the summary goes to the last entry,
; in the file that's open. Then on to lines200.txt and back.
keysBackToOpen:
    OPENFILE 2
    .byte SELECT, DOWN, F9, "x", F11, F11, 0

; Back from the summary, past the first, then on past the last
keysWrap:
    OPENFILE 3
    .byte F9, F9, F9, F9, F11, F11, 0

; A file that isn't on the disk and an entry with no file: the editor
; stays where it is
keysMissing:
    OPENFILE 2
    .byte DOWN, F11, F11, 0

keysLineZero:
    OPENFILE 3
    .byte DOWN, DOWN, DOWN, F11, 0

keysPastEnd:
    OPENFILE 3
    .byte F11, 0

; Every file closed
keysNoFileOpen:
    NEWFILE
    .byte BACK, "c", F11, 0

keysRows50:
    .byte ESC, "5", F11, 0

; The function keys F10, F12 and F13 and the codes the Esc commands make
; do nothing
keysIgnored:
    NEWFILE
    .byte "abcd", LEFT, LEFT, $fa, $fc, $fd, $80, $82, $83, $84, 0

; The tests

TEXT

noEntries:
    TEST "no entries", keysNoEntries, 0, 1, 0, 0, 1
    .asciiz "a"
    CHKBUILD BUILDRESULT::current, BUILD_SUMMARY
    CHKSCREEN 23, 0, "No build  "
    ENDTEST

noEntriesSuccess:
    TEST "success, no entries", keysNoEntries, 0, 1, 0, 0, 1, buildEmpty
    .asciiz "a"
    CHKBUILD BUILDRESULT::current, BUILD_SUMMARY
    CHKSCREEN 23, 0, "Build Success: Error(s): 0, Warning(s): 0  "
    ENDTEST

; The file is opened, the cursor goes to line 100 and the line is in the
; middle of the screen
fromTitle:
    TEST "next from the title", keysNext, F_SKIPLINES, 0, 99, 200, 0, buildOne
    CHKNAME "lines200.txt"
    CHKFILES 1
    CHKWORD EDITFILE::rowOff, 88
    CHKBUILD BUILDRESULT::current, 0
    CHKSCREEN 11, 0, "100 "
    CHKSCREEN 23, 0, "Error an error, line 100, lines200.txt  "
    CHKSCREEN 23, 66, "Showing 1 of 2"
    ENDTEST

; Line 195 can't be centered: the last line is at the bottom
twoFiles:
    TEST "two files", keysTwoFiles, F_SKIPLINES, 0, 194, 200, 0, buildTwo
    CHKNAME "lines200.txt"
    CHKFILES 2
    CHKWORD EDITFILE::rowOff, 178
    CHKBUILD BUILDRESULT::current, 2
    CHKSCREEN 21, 0, "200 "
    CHKSCREEN 23, 0, "Warning a warning, line 195, lines200.txt  "
    CHKSCREEN 23, 66, "Showing 3 of 3"
    ENDTEST

backToOpen:
    TEST "back to an open file", keysBackToOpen, 0, 0, 1, 2, 2, buildBack
    .asciiz "hello"
    .asciiz "xworld"
    CHKNAME "hello.txt"
    CHKFILES 2
    CHKBYTE EDITFILE::inSelection, 0
    CHKBYTE EDITFILE::dirty, 1
    CHKWORD EDITFILE::rowOff, 0
    CHKBUILD BUILDRESULT::current, 1
    CHKSCREEN 23, 0, "Error an error, line 2, hello.txt  "
    CHKSCREEN 23, 66, "Showing 2 of 2"
    ENDTEST

wrapAround:
    TEST "wrap around", keysWrap, F_SKIPLINES, 0, 19, 200, 0, buildThree
    CHKNAME "lines200.txt"
    CHKFILES 1
    CHKWORD EDITFILE::rowOff, 8
    CHKBUILD BUILDRESULT::current, 1
    CHKSCREEN 23, 0, "Error an error, line 20, lines200.txt  "
    CHKSCREEN 23, 66, "Showing 2 of 3"
    ENDTEST

missingFile:
    TEST "file not on the disk", keysMissing, 0, 0, 1, 2, 2, buildMissing
    .asciiz "hello"
    .asciiz "world"
    CHKNAME "hello.txt"
    CHKFILES 1
    CHKBUILD BUILDRESULT::current, 1
    CHKSCREEN 23, 0, "Warning a warning, line 7  "
    CHKSCREEN 23, 66, "Showing 2 of 2"
    ENDTEST

; Line 0 switches to the file and leaves the cursor
lineZero:
    TEST "entry with line 0", keysLineZero, F_SKIPLINES, 0, 3, 200, 0, buildZero
    CHKNAME "lines200.txt"
    CHKWORD EDITFILE::rowOff, 0
    CHKBUILD BUILDRESULT::current, 0
    CHKSCREEN 23, 0, "Error an error, lines200.txt  "
    ENDTEST

; The file is shorter than the line: the cursor goes after the last line
pastEnd:
    TEST "line past the end", keysPastEnd, 0, 0, 2, 2, 2, buildPastEnd
    .asciiz "hello"
    .asciiz "world"
    CHKNAME "hello.txt"
    CHKFILES 2
    CHKWORD EDITFILE::rowOff, 0
    CHKBUILD BUILDRESULT::current, 0
    ENDTEST

noFileOpen:
    TEST "no file open", keysNoFileOpen, F_SKIPLINES, 0, 99, 200, 0, buildOne
    CHKNAME "lines200.txt"
    CHKFILES 1
    CHKWORD EDITFILE::rowOff, 88
    ENDTEST

rows50:
    TEST "50 rows", keysRows50, F_SKIPLINES, 0, 99, 200, 0, buildOne
    CHKNAME "lines200.txt"
    CHKWORD EDITFILE::rowOff, 76
    CHKSCREEN 23, 0, "100 "
    CHKSCREEN 48, 0, "Error an error, line 100, lines200.txt  "
    CHKSCREEN 48, 66, "Showing 1 of 2"
    ENDTEST

; The key help names the keys
ignoredCodes:
    TEST "ignored key codes", keysIgnored, 0, 2, 0, 0, 1
    .asciiz "abcd"
    CHKSCREEN 24, 0, "F1: open"
    CHKSCREEN 24, 52, "F9/11: errors  Ctrl-X: quit "
    ENDTEST

; The build results

buildEmpty:
    BUILD BUILD_SUCCESS, 0, 0, BUILD_SUMMARY
    ENDBUILD

buildOne:
    BUILD BUILD_FAILED, 1, 1, BUILD_SUMMARY
    BFILE "lines200.txt"
    BENTRY BUILD_ERROR, 0, 100, msgError
    BENTRY BUILD_WARNING, 0, 195, msgWarning
    ENDBUILD

buildTwo:
    BUILD BUILD_FAILED, 2, 1, BUILD_SUMMARY
    BFILE "lines200.txt"
    BFILE "hello.txt"
    BENTRY BUILD_ERROR, 0, 5, msgError
    BENTRY BUILD_ERROR, 1, 2, msgError
    BENTRY BUILD_WARNING, 0, 195, msgWarning
    ENDBUILD

buildBack:
    BUILD BUILD_FAILED, 2, 0, BUILD_SUMMARY
    BFILE "lines200.txt"
    BFILE "hello.txt"
    BENTRY BUILD_ERROR, 0, 5, msgError
    BENTRY BUILD_ERROR, 1, 2, msgError
    ENDBUILD

buildThree:
    BUILD BUILD_FAILED, 3, 0, BUILD_SUMMARY
    BFILE "lines200.txt"
    BENTRY BUILD_ERROR, 0, 10, msgError
    BENTRY BUILD_ERROR, 0, 20, msgError
    BENTRY BUILD_ERROR, 0, 30, msgError
    ENDBUILD

buildMissing:
    BUILD BUILD_FAILED, 1, 1, BUILD_SUMMARY
    BFILE "nosuch.pas"
    BENTRY BUILD_ERROR, 0, 3, msgError
    BENTRY BUILD_WARNING, BUILD_FILE_UNKNOWN, 7, msgWarning
    ENDBUILD

buildZero:
    BUILD BUILD_FAILED, 1, 0, BUILD_SUMMARY
    BFILE "lines200.txt"
    BENTRY BUILD_ERROR, 0, 0, msgError
    ENDBUILD

buildPastEnd:
    BUILD BUILD_FAILED, 1, 0, BUILD_SUMMARY
    BFILE "hello.txt"
    BENTRY BUILD_ERROR, 0, 300, msgError
    ENDBUILD

msgError: .asciiz "an error"
msgWarning: .asciiz "a warning"
