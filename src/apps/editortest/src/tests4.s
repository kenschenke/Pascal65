;
; tests4.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Editor tests: the directory screen, closing files, the help file and the
; editor state (see tests.inc)
;
; The tests open files by their row in the directory screen (see OPENFILE),
; so they don't save any. A test that runs or compiles saves the editor
; state, and the next test's editorRun restores it. Scratching a file moves
; the files after it up a row, so that test comes last.

.include "editor.inc"
.include "tests.inc"

.export tests

.data

tests:
    .addr closeSecond, closeFirst, dirMove, dirScroll, dirAll, dirSeqOnly
    .addr dirRename, help, helpCopy, run, restoreRun, compile
    .addr restoreCompile, runSaves, restoreSaved, dirScratch
    .addr 0

; The key scripts

KEYS

keysCloseSecond:
    OPENFILE 2
    OPENFILE 6
    .byte BACK, "c", 0

keysCloseFirst:
    OPENFILE 2
    OPENFILE 6
    .byte BACK, "m", "1", BACK, "c", 0

; The directory screen has two columns of 17 rows. Right and left move
; between them, and up from the top of the right column goes to the bottom
; of the left one.
keysDirMove:
    .byte F1
    .repeat 17
        .byte DOWN
    .endrep
    .byte RIGHT, LEFT, RIGHT, UP, CR, 0

; Down from the bottom of the right column scrolls, and so does up
keysDirScroll:
    .byte F1
    .repeat 35
        .byte DOWN
    .endrep
    .repeat 18
        .byte UP
    .endrep
    .byte CR, 0

; * shows every file, not just SEQ files. Q shows SEQ files again.
keysDirAll:
    .byte F1, "*", DOWN, DOWN, DOWN, CR, 0

keysDirSeqOnly:
    .byte F1, "*", "q", DOWN, DOWN, CR, 0

; R renames a file. Esc or a blank name doesn't.
keysDirRename:
    .byte F1, DOWN, DOWN, DOWN, "r", "zz", ESC, "r", CR
    .byte "r", "l2.txt", CR, DOWN, DOWN, DOWN, CR, 0

; The help file is read-only
keysHelp:
    .byte HELP, "x", F5, 0

; It can still be copied, but not cut
keysHelpCopy:
    .byte HELP, SELECT, "x", "c"
    NEWFILE
    .byte PASTE, 0

; F5 saves the editor state and returns, to run the program
keysRun:
    OPENFILE 6
    .byte CTRL_K, F5, 0

; The next editorRun opens the files in the state again
keysRestore:
    .byte 0

; F7 does the same, to compile. The help file is in the state too.
keysCompile:
    .byte HELP
    OPENFILE 6
    .byte F7, 0

; F5 saves the changed files first
keysRunSaves:
    OPENFILE 6
    .byte "z", F5, 0

; S scratches a file, after asking. Saving save.txt moved it to the end of
; the directory, so prog.pas is still five rows down afterwards.
keysDirScratch:
    .byte F1, DOWN, DOWN, DOWN, DOWN, "s", "n", "s", "y"
    .byte DOWN, DOWN, DOWN, DOWN, CR, 0

; The tests

TEXT

closeSecond:
    TEST "close the second file", keysCloseSecond, 0, 0, 0, 2, 2
    .asciiz "hello"
    .asciiz "world"
    CHKNAME "hello.txt"
    CHKFILES 1
    ENDTEST

closeFirst:
    TEST "close the first file", keysCloseFirst, 0, 0, 0, 2, 2
    .asciiz "one"
    .asciiz "two"
    CHKNAME "save.txt"
    CHKFILES 1
    ENDTEST

dirMove:
    TEST "directory columns", keysDirMove, 0, 0, 0, 1, 1
    .asciiz "x"
    CHKNAME "m09.txt"
    ENDTEST

dirScroll:
    TEST "directory scrolling", keysDirScroll, 0, 0, 0, 1, 1
    .asciiz "x"
    CHKNAME "m10.txt"
    ENDTEST

dirAll:
    TEST "directory, all files", keysDirAll, F_SKIPLINES, 0, 0, 20, 0
    CHKNAME "title.txt"
    ENDTEST

dirSeqOnly:
    TEST "directory, seq files", keysDirSeqOnly, 0, 0, 0, 2, 2
    .asciiz "hello"
    .asciiz "world"
    CHKNAME "hello.txt"
    ENDTEST

dirRename:
    TEST "directory rename", keysDirRename, F_SKIPLINES, 0, 0, 200, 0
    CHKNAME "l2.txt"
    CHKNOTONDISK "lines200.txt"
    ENDTEST

help:
    TEST "help file", keysHelp, F_SKIPLINES, 0, 0, 33, 0
    CHKNAME "Help File"
    CHKBYTE EDITFILE::readOnly, 1
    CHKBYTE EDITFILE::dirty, 0
    CHKLINE 0, "Welcome to Pascal65"
    ENDTEST

helpCopy:
    TEST "copy from the help file", keysHelpCopy, 0, 0, 1, 1, 1
    .asciiz "Welcome to Pascal65"
    CHKFILES 2
    ENDTEST

run:
    TEST "run", keysRun, F_NOFILE, 0, 0, 0, 0
    CHKLOOP EDITOR_LOOP_RUN
    CHKFN "save.txt"
    CHKFILES 0
    ENDTEST

restoreRun:
    TEST "restore the state after running", keysRestore, 0, 3, 0, 2, 2
    .asciiz "one"
    .asciiz "two"
    CHKNAME "save.txt"
    CHKFILES 1
    CHKNOTONDISK "zzstate"
    ENDTEST

compile:
    TEST "compile", keysCompile, F_NOFILE, 0, 0, 0, 0
    CHKLOOP EDITOR_LOOP_COMPILE
    CHKFN "save.txt"
    ENDTEST

restoreCompile:
    TEST "restore two files", keysRestore, 0, 0, 0, 2, 2
    .asciiz "one"
    .asciiz "two"
    CHKNAME "save.txt"
    CHKFILES 2
    ENDTEST

runSaves:
    TEST "run saves the files", keysRunSaves, F_NOFILE, 0, 0, 0, 0
    CHKLOOP EDITOR_LOOP_RUN
    CHKDISK "save.txt"
    .byte "zone", CR, "two", CR, 0
    ENDTEST

restoreSaved:
    TEST "restore a saved file", keysRestore, 0, 1, 0, 2, 2
    .asciiz "zone"
    .asciiz "two"
    CHKNAME "save.txt"
    ENDTEST

dirScratch:
    TEST "directory scratch", keysDirScratch, F_SKIPLINES, 0, 0, 8, 0
    CHKNAME "prog.pas"
    CHKNOTONDISK "noeol.txt"
    ENDTEST
