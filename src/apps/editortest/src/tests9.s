;
; tests9.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Editor tests with a work disk (see tests.inc and plans/workdisks.md).
; Every test has F_TWODISK: the system disk, which the program runs from,
; is unit 8, and the work disk unit 9.
;
; The work disk starts with one SEQ file, hello.txt, holding "from work".
; The system disk has the files OPENFILE lists, hello.txt among them, so
; a hello.txt from the wrong disk shows. F1 lists the work disk, and D the
; system disk (SYSFILE). A file from the system disk is read-only, and
; the status bar shows which disk a file is from.
;
; The tests run in order. Building a file from the system disk copies it
; over the work disk's hello.txt, so the tests that open that one come
; first.

.include "editor.inc"
.include "tests.inc"

.export tests

STATUSROW = 22              ; The status bar, with 25 rows

.data

tests:
    .addr workOpen, sysOpen, sysNoEdit, sysNoScratch, dirBack, helpNoBuild
    .addr sysBuild, sysBuildRestore, sysSaveAs, sysState, sysStateRestore
    .addr wdSwitch, wdKeep, wdDrop, wdNoFile, wdDir, wdDirNoFile
    .addr 0

; The key scripts

KEYS

keysWorkOpen:
    OPENFILE 0
    .byte 0

keysSysOpen:
    SYSFILE 2
    .byte 0

; Typing and F3 do nothing to a read-only file
keysSysNoEdit:
    SYSFILE 2
    .byte "x", F3, 0

; S and R do nothing in the system disk's directory. The keys after them
; aren't a name or an answer, so they do nothing either, and Return
; opens the file.
keysSysNoScratch:
    .byte F1, $64, DOWN, DOWN, "s", "y", "r", "zz", CR, 0

; D again lists the work disk
keysDirBack:
    .byte F1, $64, $64, CR, 0

; The help file isn't copied to the work disk or built
keysHelpNoBuild:
    .byte HELP, F7, 0

; F7 copies a file from the system disk over the work disk's file of that
; name, then compiles it
keysSysBuild:
    SYSFILE 2
    .byte F7, 0

; The state has the work disk's copy
keysRestore:
    .byte 0

; Save As writes a file from the system disk to the work disk, and the
; buffer is then that file
keysSysSaveAs:
    SYSFILE 4
    .byte BACK, "a", "copy.txt", CR, "z", 0

; F4 saves the state with a file from the system disk
keysSysState:
    SYSFILE 2
    .byte F4, 0

keysDbg1:
    .byte F1, BACK, 0

; W in the file screen returns to change the work disk. The files with
; names are saved first, and the files are closed, not kept in the state.
; The work disk's first file is copy.txt now: building hello.txt wrote it
; again, after the slot copy.txt took.
keysWdSwitch:
    OPENFILE 0
    .byte "x", BACK, "w", 0

; Changes with no file name to save them in are kept if the user says N
keysWdKeep:
    NEWFILE
    .byte "a", BACK, "w", "n", 0

; and dropped if Y
keysWdDrop:
    NEWFILE
    .byte "a", BACK, "w", "y", 0

; W works with no file open
keysWdNoFile:
    .byte BACK, "w", 0

; W in the directory screen does the same. Saving copy.txt moved it after
; hello.txt, which is the first file again.
keysWdDir:
    OPENFILE 0
    .byte "y", F1, "w", 0

keysWdDirNoFile:
    .byte F1, "w", 0

; The tests

TEXT

dbg0:
    TEST "dbg0", keysRestore, F_TWODISK|F_NOFILE, 0, 0, 0, 0
    ENDTEST
dbg1:
    TEST "dbg1", keysDbg1, F_TWODISK|F_NOFILE, 0, 0, 0, 0
    ENDTEST

workOpen:
    TEST "open from the work disk", keysWorkOpen, F_TWODISK, 0, 0, 1, 1
    .asciiz "from work"
    CHKNAME "hello.txt"
    CHKBYTE EDITFILE::device, WORK_UNIT
    CHKBYTE EDITFILE::readOnly, 0
    CHKSCREEN STATUSROW, STATUSCOL_DISK, "Work  "
    CHKSCREEN STATUSROW, STATUSCOL_RO, "   "
    ENDTEST

sysOpen:
    TEST "open from the system disk", keysSysOpen, F_TWODISK, 0, 0, 2, 2
    .asciiz "hello"
    .asciiz "world"
    CHKNAME "hello.txt"
    CHKBYTE EDITFILE::device, 8
    CHKBYTE EDITFILE::readOnly, 1
    CHKSCREEN STATUSROW, STATUSCOL_DISK, "System"
    CHKSCREEN STATUSROW, STATUSCOL_RO, "R/O"
    ENDTEST

sysNoEdit:
    TEST "a system file is read-only", keysSysNoEdit, F_TWODISK, 0, 0, 2, 2
    .asciiz "hello"
    .asciiz "world"
    CHKBYTE EDITFILE::dirty, 0
    CHKDISK "hello.txt"
    .byte "from work", CR, 0
    ENDTEST

sysNoScratch:
    TEST "no system scratch", keysSysNoScratch, F_TWODISK, 0, 0, 2, 2
    .asciiz "hello"
    .asciiz "world"
    CHKBYTE EDITFILE::readOnly, 1
    CHKDISK "hello.txt"
    .byte "from work", CR, 0
    CHKNOTONDISK "zz"
    ENDTEST

dirBack:
    TEST "back to the work disk", keysDirBack, F_TWODISK, 0, 0, 1, 1
    .asciiz "from work"
    CHKBYTE EDITFILE::device, WORK_UNIT
    CHKBYTE EDITFILE::readOnly, 0
    ENDTEST

helpNoBuild:
    TEST "help isn't built", keysHelpNoBuild, F_TWODISK|F_SKIPLINES, 0, 0, 36, 0
    CHKNAME "Help File"
    CHKBYTE EDITFILE::readOnly, 1
    CHKLOOP EDITOR_LOOP_QUIT
    CHKSCREEN STATUSROW, STATUSCOL_DISK, "System"
    CHKNOTONDISK "Help File"
    ENDTEST

sysBuild:
    TEST "build a system file", keysSysBuild, F_TWODISK|F_NOFILE, 0, 0, 0, 0
    CHKLOOP EDITOR_LOOP_COMPILE
    CHKFN "hello.txt"
    CHKDISK "hello.txt"
    .byte "hello", CR, "world", CR, 0
    CHKNOTONDISK "tmp.txt"
    ENDTEST

sysBuildRestore:
    TEST "restore the copy", keysRestore, F_TWODISK, 0, 0, 2, 2
    .asciiz "hello"
    .asciiz "world"
    CHKNAME "hello.txt"
    CHKFILES 1
    CHKBYTE EDITFILE::device, WORK_UNIT
    CHKBYTE EDITFILE::readOnly, 0
    CHKSCREEN STATUSROW, STATUSCOL_DISK, "Work  "
    CHKNOTONDISK "zzstate"
    ENDTEST

sysSaveAs:
    TEST "save a system file as", keysSysSaveAs, F_TWODISK, 1, 0, 1, 1
    .asciiz "zabc"
    CHKNAME "copy.txt"
    CHKBYTE EDITFILE::device, WORK_UNIT
    CHKBYTE EDITFILE::readOnly, 0
    CHKBYTE EDITFILE::dirty, 1
    CHKSCREEN STATUSROW, STATUSCOL_DISK, "Work  "
    CHKDISK "copy.txt"
    .byte "abc", CR, 0
    ENDTEST

sysState:
    TEST "save the state", keysSysState, F_TWODISK|F_NOFILE, 0, 0, 0, 0
    CHKLOOP EDITOR_LOOP_THEME
    ENDTEST

sysStateRestore:
    TEST "restore a system file", keysRestore, F_TWODISK, 0, 0, 2, 2
    .asciiz "hello"
    .asciiz "world"
    CHKNAME "hello.txt"
    CHKBYTE EDITFILE::device, 8
    CHKBYTE EDITFILE::readOnly, 1
    CHKSCREEN STATUSROW, STATUSCOL_DISK, "System"
    CHKNOTONDISK "zzstate"
    ENDTEST

wdSwitch:
    TEST "change the work disk", keysWdSwitch, F_TWODISK|F_NOFILE, 0, 0, 0, 0
    CHKLOOP EDITOR_LOOP_WORKDISK
    CHKFILES 0
    CHKDISK "copy.txt"
    .byte "xabc", CR, 0
    CHKNOTONDISK "zzstate"
    ENDTEST

wdKeep:
    TEST "keep unsaved changes", keysWdKeep, F_TWODISK, 1, 0, 0, 1
    .asciiz "a"
    CHKBYTE EDITFILE::dirty, 1
    CHKFILES 1
    CHKLOOP EDITOR_LOOP_QUIT
    ENDTEST

wdDrop:
    TEST "drop unsaved changes", keysWdDrop, F_TWODISK|F_NOFILE, 0, 0, 0, 0
    CHKLOOP EDITOR_LOOP_WORKDISK
    CHKFILES 0
    ENDTEST

wdNoFile:
    TEST "no file open", keysWdNoFile, F_TWODISK|F_NOFILE, 0, 0, 0, 0
    CHKLOOP EDITOR_LOOP_WORKDISK
    ENDTEST

wdDir:
    TEST "w in the directory", keysWdDir, F_TWODISK|F_NOFILE, 0, 0, 0, 0
    CHKLOOP EDITOR_LOOP_WORKDISK
    CHKFILES 0
    CHKDISK "hello.txt"
    .byte "yhello", CR, "world", CR, 0
    ENDTEST

wdDirNoFile:
    TEST "w, no file open", keysWdDirNoFile, F_TWODISK|F_NOFILE, 0, 0, 0, 0
    CHKLOOP EDITOR_LOOP_WORKDISK
    ENDTEST
