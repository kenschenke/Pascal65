;
; tests.inc
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; The layout of a themes test, and macros for writing them (see main.s).
;
; A test record is:
;    .addr  name
;    .addr  the fixture to copy to themes.dat, or NOFILE
;    .addr  the fixture to copy to themes.def, or NOFILE
;    steps (OP_* and CHK_*), then OP_END (ENDTEST)
;
; The fixtures are files on the disk, made by mkthemes.py (see the
; Makefile). Before a test, themes.dat and themes.def are scratched, the
; fixtures are copied to them and the palette is reset to the MEGA65's
; defaults. After the last step the theme list is freed and the heap is
; checked for leaks.
;
; A key script holds the keys as the keyboard sends them (ASCII letters)
; and ends with a zero. The theme screen only returns on F1, so a script
; must end with it. A script that runs out fails the test.
;
; Theme names are written as the overlay holds them: PETSCII, as ca65's
; c64 target makes them, space-filled to 16 characters.

REC_NAME = 0
REC_DAT = 2
REC_DEF = 4
REC_STEPS = 6

NOFILE = 0

; Steps that do something
OP_END = 0
OP_INIT = 1                 ; initThemeList
OP_READ = 2                 ; readThemeFile
OP_WRITE = 3                ; writeThemeFile
OP_RESET = 4                ; resetToDefaults
OP_FREE = 5                 ; freeThemeList
OP_LOAD = 6                 ; loadDefaultTheme into the test's buffer
OP_SCREEN = 7               ; .addr key script: the theme screen
OP_RESETPAL = 8             ; resetSystemPalette
OP_SETPAL = 9               ; .byte slot, r, g, b: set a palette slot
OP_ISUSED = 10              ; .byte color, 1 if used: isColorUsedInTheme
                            ; on the test's own theme (fakeTheme)
; Checks
CHK_COUNT = 11              ; .byte numThemes and the list's length
CHK_SEL = 12                ; .byte selectedThemeNum; currentTheme is it
CHK_NAME = 13               ; .byte theme, 16 bytes of name
CHK_COLOR = 14              ; .byte theme, SYNTAXHL_*, index, r, g, b
CHK_PAL = 15                ; .byte slot, r, g, b: the VIC palette
CHK_BG = 16                 ; .byte the border and background colors
CHK_BUF = 17                ; THEME_COLORS bytes: loadDefaultTheme's
                            ; buffer, from SYNTAXHL_NUMBER on
CHK_FILE = 18               ; .asciiz fixture: themes.dat has its bytes
CHK_EMPTY = 19              ; The list is empty and currentTheme null
CHK_CELL = 20               ; .byte row, column, screen code, color RAM:
                            ; the screen the theme screen left
OP_SCREENOUT = 21           ; .addr key script: the theme screen, which
                            ; must run out of keys (to check its screen
                            ; while it waits, as in the palette)
OP_LAST = 21

; Keys
CR = $0d
UP = $91
DOWN = $11
LEFT = $9d
RIGHT = $1d
F1 = 241
F5 = 245
F8 = 248
K_B = $62                   ; Letters as the keyboard sends them
K_E = $65
K_G = $67
K_N = $6e
K_R = $72
K_W = $77

.macro TEST name, dat, def
    .local nm
    .addr nm, dat, def
    .pushseg
    .rodata
nm: .asciiz name
    .popseg
.endmacro

.macro ENDTEST
    .byte OP_END
.endmacro

.macro DO_INIT
    .byte OP_INIT
.endmacro

.macro DO_READ
    .byte OP_READ
.endmacro

.macro DO_WRITE
    .byte OP_WRITE
.endmacro

.macro DO_RESET
    .byte OP_RESET
.endmacro

.macro DO_FREE
    .byte OP_FREE
.endmacro

.macro DO_LOAD
    .byte OP_LOAD
.endmacro

.macro DO_SCREEN keys
    .byte OP_SCREEN
    .addr keys
.endmacro

.macro DO_RESETPAL
    .byte OP_RESETPAL
.endmacro

.macro DO_SETPAL slot, r, g, b
    .byte OP_SETPAL, slot, r, g, b
.endmacro

.macro DO_ISUSED color, used
    .byte OP_ISUSED, color, used
.endmacro

.macro CHKCOUNT n
    .byte CHK_COUNT, n
.endmacro

.macro CHKSEL n
    .byte CHK_SEL, n
.endmacro

.macro CHKNAME n, name
    .byte CHK_NAME, n
    .byte name
    .res 16 - .strlen(name), ' '
.endmacro

.macro CHKCOLOR n, color, index, r, g, b
    .byte CHK_COLOR, n, color, index, r, g, b
.endmacro

.macro CHKPAL slot, r, g, b
    .byte CHK_PAL, slot, r, g, b
.endmacro

.macro CHKBG color
    .byte CHK_BG, color
.endmacro

.macro CHKBUF c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11
    .byte CHK_BUF, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11
.endmacro

.macro CHKFILE fixture
    .byte CHK_FILE
    .asciiz fixture
.endmacro

.macro CHKEMPTY
    .byte CHK_EMPTY
.endmacro

.macro DO_SCREENOUT keys
    .byte OP_SCREENOUT
    .addr keys
.endmacro

.macro CHKCELL row, col, char, color
    .byte CHK_CELL, row, col, char, color
.endmacro
