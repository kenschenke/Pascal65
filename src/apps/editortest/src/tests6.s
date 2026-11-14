;
; tests6.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Editor tests: the build line (buildline.s), the row between the status
; bar and the message bar. With 25 rows the text takes rows 0 to 21, the
; status bar is row 22, the build line 23 and the message bar 24. With 50
; rows they are 47, 48 and 49.

.include "editor.inc"
.include "buildresult.inc"
.include "tests.inc"

.export tests

.data

tests:
    .addr noBuild, success, failed, longEntry, noLine, noFile
    .addr noBuild50, failed50, entry50, back25, fileScreen, dirScreen
    .addr longMsg
    .addr 0

; The key scripts

KEYS

keysNone:
    .byte 0

keysType:
    NEWFILE
    .byte "a", 0

keysNoFile50:
    .byte ESC, "5", 0

keysType50:
    NEWFILE
    .byte "a", ESC, "5", 0

; 50 rows and back to 25
keysBack25:
    NEWFILE
    .byte "a", ESC, "5", ESC, "8", 0

; The open files screen and the directory screen draw over the build line
keysFileScreen:
    NEWFILE
    .byte "a", BACK, "m", BACK, 0

keysDirScreen:
    NEWFILE
    .byte "a", F1, BACK, 0

; The tests

TEXT

; With no build and no file open
noBuild:
    TEST "no build", keysNone, F_NOFILE, 0, 0, 0, 0
    CHKSCREEN 23, 0, "No build          "
    CHKSCREEN 24, 0, "F1: open"
    ENDTEST

success:
    TEST "build success", keysType, 0, 1, 0, 0, 1, buildSuccess
    .asciiz "a"
    CHKSCREEN 22, 0, "[No Name]"
    CHKSCREEN 22, 69, "C:2"
    CHKSCREEN 23, 0, "Build Success: Error(s): 0, Warning(s): 3     "
    CHKSCREEN 24, 0, "F1: open"
    ENDTEST

; The counts are unsigned words
failed:
    TEST "build failed", keysType, 0, 1, 0, 0, 1, buildFailed
    .asciiz "a"
    CHKSCREEN 23, 0, "Build Failed: Error(s): 40, Warning(s): 65535   "
    ENDTEST

; The longest entry the compiler can make: a 23-character message, a
; 5-digit line and a 16-character filename. "Showing x of y" ends in the
; last column.
longEntry:
    TEST "longest entry", keysType, 0, 1, 0, 0, 1, buildLong
    .asciiz "a"
    CHKSCREEN 23, 0, "Warning Incompatible assignment"
    CHKSCREEN 23, 31, ", line 65535, abcdefghijkl.pas   "
    CHKSCREEN 23, 64, "Showing 10 of 32"
    ENDTEST

; An entry with line 0 leaves out the line
noLine:
    TEST "entry with no line", keysType, 0, 1, 0, 0, 1, buildNoLine
    .asciiz "a"
    CHKSCREEN 23, 0, "Error File not found, unit.pas    "
    CHKSCREEN 23, 66, "Showing 1 of 2"
    ENDTEST

; An entry with no filename leaves out the file
noFile:
    TEST "entry with no file", keysType, 0, 1, 0, 0, 1, buildNoFile
    .asciiz "a"
    CHKSCREEN 23, 0, "Warning a warning, line 7    "
    CHKSCREEN 23, 66, "Showing 2 of 2"
    ENDTEST

noBuild50:
    TEST "no build, 50 rows", keysNoFile50, F_NOFILE, 0, 0, 0, 0
    CHKSCREEN 48, 0, "No build          "
    CHKSCREEN 49, 0, "F1: open"
    ENDTEST

failed50:
    TEST "build failed, 50 rows", keysType50, 0, 1, 0, 0, 1, buildFailed
    .asciiz "a"
    CHKSCREEN 47, 0, "[No Name]"
    CHKSCREEN 48, 0, "Build Failed: Error(s): 40, Warning(s): 65535   "
    CHKSCREEN 49, 0, "F1: open"
    ENDTEST

entry50:
    TEST "entry, 50 rows", keysType50, 0, 1, 0, 0, 1, buildLong
    .asciiz "a"
    CHKSCREEN 48, 0, "Warning Incompatible assignment"
    CHKSCREEN 48, 64, "Showing 10 of 32"
    ENDTEST

back25:
    TEST "back to 25 rows", keysBack25, 0, 1, 0, 0, 1, buildSuccess
    .asciiz "a"
    CHKSCREEN 22, 0, "[No Name]"
    CHKSCREEN 23, 0, "Build Success: Error(s): 0, Warning(s): 3     "
    CHKSCREEN 24, 0, "F1: open"
    ENDTEST

fileScreen:
    TEST "after the file screen", keysFileScreen, 0, 1, 0, 0, 1, buildNoLine
    .asciiz "a"
    CHKSCREEN 22, 0, "[No Name]"
    CHKSCREEN 23, 0, "Error File not found, unit.pas    "
    CHKSCREEN 23, 66, "Showing 1 of 2"
    CHKSCREEN 24, 0, "F1: open"
    ENDTEST

dirScreen:
    TEST "after the dir screen", keysDirScreen, 0, 1, 0, 0, 1, buildNoLine
    .asciiz "a"
    CHKSCREEN 22, 0, "[No Name]"
    CHKSCREEN 23, 0, "Error File not found, unit.pas    "
    CHKSCREEN 23, 66, "Showing 1 of 2"
    CHKSCREEN 24, 0, "F1: open"
    ENDTEST

; A message longer than the compiler's is cut off at the end of the line,
; and "Showing x of y" with it
longMsg:
    TEST "message too long", keysType, 0, 1, 0, 0, 1, buildLongMsg
    .asciiz "a"
    CHKSCREEN 23, 0, "Error xxxxxxxxxx"
    CHKSCREEN 23, 70, "xxxxxx, li"
    ENDTEST

; The build results

buildSuccess:
    BUILD BUILD_SUCCESS, 0, 3, BUILD_SUMMARY
    BFILE "prog.pas"
    BENTRY BUILD_WARNING, 0, 1, msgWarning
    BENTRY BUILD_WARNING, 0, 2, msgWarning
    BENTRY BUILD_WARNING, 0, 3, msgWarning
    ENDBUILD

buildFailed:
    BUILD BUILD_FAILED, 40, 65535, BUILD_SUMMARY
    BFILE "prog.pas"
    BENTRY BUILD_ERROR, 0, 1, msgError
    ENDBUILD

; 32 entries, the 10th shown
buildLong:
    BUILD BUILD_FAILED, 31, 1, 9
    BFILE "abcdefghijkl.pas"
    .repeat 9
        BENTRY BUILD_ERROR, 0, 1, msgError
    .endrep
    BENTRY BUILD_WARNING, 0, 65535, msgIncompat
    .repeat 22
        BENTRY BUILD_ERROR, 0, 1, msgError
    .endrep
    ENDBUILD

buildNoLine:
    BUILD BUILD_FAILED, 1, 1, 0
    BFILE "unit.pas"
    BENTRY BUILD_ERROR, 0, 0, msgNotFound
    BENTRY BUILD_WARNING, BUILD_FILE_UNKNOWN, 7, msgWarning
    ENDBUILD

buildNoFile:
    BUILD BUILD_FAILED, 1, 1, 1
    BFILE "unit.pas"
    BENTRY BUILD_ERROR, 0, 0, msgNotFound
    BENTRY BUILD_WARNING, BUILD_FILE_UNKNOWN, 7, msgWarning
    ENDBUILD

buildLongMsg:
    BUILD BUILD_FAILED, 1, 0, 0
    BFILE "prog.pas"
    BENTRY BUILD_ERROR, 0, 1, msgLong
    ENDBUILD

msgError: .asciiz "an error"
msgWarning: .asciiz "a warning"
msgIncompat: .asciiz "Incompatible assignment"
msgNotFound: .asciiz "File not found"
msgLong:
    .repeat 70
        .byte "x"
    .endrep
    .byte 0
