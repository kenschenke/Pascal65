;
; tests.inc
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; The layout of an editor test, and macros for writing them (see main.s).
;
; Each testsN.s file is the tests of one test program. They don't all fit
; in one. It exports "tests", a list of test records ended by a zero.
;
; A key script holds the keys as the keyboard sends them, which is ASCII,
; and ends with a zero. The editor turns letters into PETSCII as it reads
; them (fixAlphaCase), so the expected text is PETSCII. The KEYS and TEXT
; macros switch ca65's character map between the two.
;
; A test record is (TEST makes the first part):
;    .addr  name
;    .addr  key script
;    .byte  flags (F_*)
;    .byte  cursor X
;    .word  cursor Y
;    .word  numLines
;    .byte  number of lines
;    .addr  build result (BUILD), or 0 for none
;    the text of each line, zero-terminated
;    the other checks (CHK_*), then CHK_END (ENDTEST)
;
; With F_NOFILE no file may be open, and the cursor, numLines and lines
; aren't checked (the number of lines is zero). With F_SKIPLINES the lines
; aren't checked (the number is zero), but CHK_LINE can check some.
;
; editorRun gets the test's build result (EDITORCTX::buildResult). A test
; with none gets an empty one: BUILD_NONE, no entries and the summary.
; BUILD starts one and ENDBUILD ends it. Between them, BFILE adds a file
; and BENTRY an entry, in the order they are kept (fileIdx counts BFILEs
; from 0). numFiles and numEntries are the counts of each. The message is
; a pointer to text in the test program.
;
; Include editor.inc and buildresult.inc first.

REC_NAME = 0
REC_KEYS = 2
REC_FLAGS = 4
REC_CX = 5
REC_CY = 6
REC_NUMLINES = 8
REC_COUNT = 10
REC_BUILD = 11
REC_LINES = 13

F_PASCAL = 1                ; New files are Pascal files
F_NOFILE = 2                ; No file is open at the end
F_SKIPLINES = 4             ; Only the lines CHK_LINE names are checked

; The checks after the lines
CHK_END = 0
CHK_BYTE = 1                ; .byte offset in EDITFILE, value
CHK_WORD = 2                ; .byte offset in EDITFILE, .word value
CHK_HL = 3                  ; .byte line, .asciiz highlighting as digits
CHK_NAME = 4                ; .asciiz filename
CHK_FILES = 5               ; .byte number of open files
CHK_SCREEN = 6              ; .byte row, column, .asciiz text
CHK_DISK = 7                ; .asciiz filename, contents ended by a zero
CHK_NOTONDISK = 8           ; .asciiz filename
CHK_LOOP = 9                ; .byte the code editorRun returned
CHK_COMPILEFN = 10          ; .asciiz the filename editorRun returned
CHK_LINE = 11               ; .byte line, .asciiz text
CHK_BUILD = 12              ; .word offset in BUILDRESULT, .byte value
CHK_LAST = 12

; The items of a build result after its header (see BUILD)
BLD_END = 0
BLD_FILE = 1                ; .asciiz name
BLD_ENTRY = 2               ; .byte kind, fileIdx, .word line, .addr msg

; Keys
CR = CH_ENTER
LEFT = CH_CURS_LEFT
RIGHT = CH_CURS_RIGHT
UP = CH_CURS_UP
DOWN = CH_CURS_DOWN
BS = CH_BACKSPACE
HOME = CH_HOME
INS = CH_INS
TABKEY = CH_TAB
ESC = CH_ESC
BACK = CH_BACKARROW         ; The file screen, or back out of a screen
SELECT = CTRL_Y
PASTE = CTRL_U
F1 = CH_F1
F3 = CH_F3
F4 = CH_F4
F5 = CH_F5
F7 = CH_F7
HELP = CH_HELP

; Letters as the keyboard sends them (ASCII)
.macro KEYS
    .repeat 26, i
        .charmap $61+i, $61+i
        .charmap $41+i, $41+i
    .endrep
.endmacro

; Letters as the editor stores them (PETSCII, as ca65's c64 target has them)
.macro TEXT
    .repeat 26, i
        .charmap $61+i, $41+i
        .charmap $41+i, $c1+i
    .endrep
.endmacro

; Opens a new file: the file screen, then N
.macro NEWFILE
    .byte BACK, $6e
.endmacro

; Starts a test record. The name goes in RODATA.
.macro TEST name, keys, flags, cx, cy, numLines, count, build
    .local nm
    .addr nm, keys
    .byte flags, cx
    .word cy, numLines
    .byte count
    .ifblank build
        .addr 0
    .else
        .addr build
    .endif
    .pushseg
    .rodata
nm: .asciiz name
    .popseg
.endmacro

.macro ENDTEST
    .byte CHK_END
.endmacro

.macro CHKBYTE offset, value
    .byte CHK_BYTE, offset, value
.endmacro

.macro CHKWORD offset, value
    .byte CHK_WORD, offset
    .word value
.endmacro

.macro CHKHL line, digits
    .byte CHK_HL, line
    .asciiz digits
.endmacro

.macro CHKNAME name
    .byte CHK_NAME
    .asciiz name
.endmacro

.macro CHKFILES count
    .byte CHK_FILES, count
.endmacro

.macro CHKSCREEN row, col, text
    .byte CHK_SCREEN, row, col
    .asciiz text
.endmacro

; The contents follow, ended by a zero
.macro CHKDISK name
    .byte CHK_DISK
    .asciiz name
.endmacro

.macro CHKNOTONDISK name
    .byte CHK_NOTONDISK
    .asciiz name
.endmacro

.macro CHKLOOP code
    .byte CHK_LOOP, code
.endmacro

.macro CHKLINE line, text
    .byte CHK_LINE, line
    .asciiz text
.endmacro

; Opens the file in row n of the directory screen (F1), counting from 0.
; The disk's SEQ files are title.txt, help.txt, then the files the Makefile
; writes, in its order (FIXNAMES, then m01.txt to m40.txt).
.macro OPENFILE n
    .byte F1
    .repeat n
        .byte DOWN
    .endrep
    .byte CR
.endmacro

.macro CHKFN name
    .byte CHK_COMPILEFN
    .asciiz name
.endmacro

; A byte of the build result the overlay was given
.macro CHKBUILD offset, value
    .byte CHK_BUILD
    .word offset
    .byte value
.endmacro

; Starts a build result: the header, then BFILE and BENTRY items
.macro BUILD state, numErrors, numWarns, current
    .byte state
    .word numErrors, numWarns
    .byte current
.endmacro

.macro BFILE name
    .byte BLD_FILE
    .asciiz name
.endmacro

.macro BENTRY kind, fileIdx, line, msg
    .byte BLD_ENTRY, kind, fileIdx
    .word line
    .addr msg
.endmacro

.macro ENDBUILD
    .byte BLD_END
.endmacro
