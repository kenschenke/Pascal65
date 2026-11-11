;
; tests.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Themes overlay tests (see tests.inc). The fixtures are described in
; the Makefile and files/*.txt. three has Alpha, Beta and Gamma with Beta
; selected; defs has Def One and Def Two with Def Two selected.

.include "editor.inc"
.include "tests.inc"

.export tests

.data

tests:
    .addr readThree, readPalette, freeEmpties, readTwice
    .addr loadBuffer, loadAlpha
    .addr noDat, noFiles, onlySelected, badDef, partial
    .addr selPastEnd
    .addr writeSame, writeFallback, writeBuiltin
    .addr resetDefs, resetBuiltin, resetPalette, colorUsed
    .addr saveSame, pickDown, pickUp, pickPastEnd, saveReload
    .addr changeNumber, editRgb, changeBg, bgOnUi
    .addr screenReset, screenResetBuiltin
    .addr 0

; The fixtures
three: .asciiz "three"
three0: .asciiz "three0"
three2: .asciiz "three2"
sel9: .asciiz "sel9"
partialFx: .asciiz "partial"
onlysel: .asciiz "onlysel"
defs: .asciiz "defs"

; The key scripts. The theme screen starts in the theme list, which takes
; arrows and Return; F5 goes back to it.
keysSave:
    .byte CR, F1, 0
; Down, from the list again
keysDown:
    .byte CR, F5, DOWN, CR, F1, 0
keysUp:
    .byte UP, CR, F1, 0
keysPastEnd:
    .byte DOWN, DOWN, DOWN, CR, F1, 0
; Numbers, down to the next index, Return
keysNumber:
    .byte CR, K_N, DOWN, CR, F1, 0
; Numbers, edit: red down one, green down two, blue up one
keysRgb:
    .byte CR, K_N, K_E, K_R, LEFT, K_G, LEFT, LEFT, K_B, RIGHT, CR, CR, F1, 0
keysBg:
    .byte CR, K_B, DOWN, CR, F1, 0
keysBgUi:
    .byte CR, K_B, UP, UP, UP, UP, UP, CR, F1, 0
keysReset:
    .byte CR, F8, F1, 0

; Reading

readThree:
    TEST "read", three, defs
    DO_INIT
    CHKCOUNT 3
    CHKSEL 1
    CHKNAME 0, "Alpha"
    CHKNAME 1, "Beta"
    CHKNAME 2, "Gamma"
    CHKCOLOR 0, SYNTAXHL_NUMBER, 5, 0, 15, 0
    CHKCOLOR 0, SYNTAXHL_BACKGROUND, 21, 2, 3, 5
    CHKCOLOR 1, SYNTAXHL_STRING, 18, 15, 11, 0
    CHKCOLOR 2, SYNTAXHL_KEYWORD, 25, 1, 2, 3
    CHKCOLOR 2, SYNTAXHL_BACKGROUND, 1, 15, 15, 15
    CHKBG 6
    ENDTEST

; initThemeList writes the selected theme's colors into the palette
readPalette:
    TEST "read palette", three0, defs
    DO_SETPAL 21, 9, 9, 9
    DO_SETPAL 3, 1, 1, 1
    DO_INIT
    CHKPAL 21, 2, 3, 5
    CHKPAL 3, 0, 15, 15
    CHKPAL 4, 15, 9, 12
    CHKBG 21
    ENDTEST

freeEmpties:
    TEST "free", three, defs
    DO_INIT
    DO_FREE
    CHKEMPTY
    ENDTEST

readTwice:
    TEST "read twice", three, defs
    DO_INIT
    DO_FREE
    DO_INIT
    CHKCOUNT 3
    CHKSEL 1
    ENDTEST

; loadDefaultTheme

; Beta's index 18 goes in the buffer as $42 (toVIC)
loadBuffer:
    TEST "load buffer", three, defs
    DO_LOAD
    CHKBUF 7, 2, $42, 11, 14, 13, 8, 1, 6
    CHKPAL 18, 15, 11, 0
    CHKBG 6
    CHKEMPTY
    ENDTEST

loadAlpha:
    TEST "load alpha", three0, defs
    DO_LOAD
    CHKBUF 5, 4, 3, 12, 1, 10, $43, 1, $45
    CHKPAL 21, 2, 3, 5
    CHKBG 21
    CHKEMPTY
    ENDTEST

; Unreadable files

noDat:
    TEST "no themes.dat", NOFILE, defs
    DO_INIT
    CHKCOUNT 2
    CHKSEL 1
    CHKNAME 0, "Def One"
    CHKNAME 1, "Def Two"
    CHKCOLOR 1, SYNTAXHL_BACKGROUND, 30, 3, 4, 5
    CHKPAL 30, 3, 4, 5
    CHKBG 30
    ENDTEST

noFiles:
    TEST "no files", NOFILE, NOFILE
    DO_INIT
    CHKCOUNT 1
    CHKSEL 0
    CHKNAME 0, "Default"
    CHKCOLOR 0, SYNTAXHL_NUMBER, 5, 0, 15, 0
    CHKCOLOR 0, SYNTAXHL_BACKGROUND, 21, 2, 3, 5
    CHKPAL 21, 2, 3, 5
    CHKPAL 19, 14, 14, 0
    CHKBG 21
    ENDTEST

onlySelected:
    TEST "no complete theme", onlysel, defs
    DO_INIT
    CHKCOUNT 2
    CHKSEL 1
    CHKNAME 0, "Def One"
    CHKNAME 1, "Def Two"
    ENDTEST

badDef:
    TEST "bad themes.def", onlysel, onlysel
    DO_INIT
    CHKCOUNT 1
    CHKNAME 0, "Default"
    ENDTEST

; The partial third theme is dropped
partial:
    TEST "partial theme", partialFx, defs
    DO_INIT
    CHKCOUNT 2
    CHKSEL 1
    CHKNAME 1, "Beta"
    CHKCOLOR 1, SYNTAXHL_BACKGROUND, 6, 0, 0, 15
    ENDTEST

selPastEnd:
    TEST "selected past end", sel9, defs
    DO_INIT
    CHKCOUNT 3
    CHKSEL 0
    CHKBG 21
    ENDTEST

; Writing

writeSame:
    TEST "write", three, defs
    DO_INIT
    DO_WRITE
    CHKFILE "three"
    ENDTEST

writeFallback:
    TEST "write defaults", NOFILE, defs
    DO_READ
    DO_WRITE
    CHKFILE "defs"
    ENDTEST

writeBuiltin:
    TEST "write built-in", NOFILE, NOFILE
    DO_READ
    DO_WRITE
    CHKFILE "builtin"
    ENDTEST

; resetToDefaults, and the palette

resetDefs:
    TEST "reset", three, defs
    DO_INIT
    DO_SETPAL 31, 1, 1, 1
    DO_RESET
    CHKCOUNT 2
    CHKSEL 1
    CHKNAME 0, "Def One"
    CHKPAL 31, 15, 3, 6
    CHKPAL 2, 1, 2, 3
    CHKBG 30
    ENDTEST

resetBuiltin:
    TEST "reset built-in", three, NOFILE
    DO_INIT
    DO_RESET
    CHKCOUNT 1
    CHKSEL 0
    CHKNAME 0, "Default"
    CHKBG 21
    ENDTEST

; Every slot, 0 to 31, goes back to the MEGA65's default
resetPalette:
    TEST "reset palette", NOFILE, NOFILE
    DO_SETPAL 0, 9, 9, 9
    DO_SETPAL 16, 1, 1, 1
    DO_SETPAL 31, 1, 2, 3
    DO_RESETPAL
    CHKPAL 0, 0, 0, 0
    CHKPAL 16, 14, 0, 0
    CHKPAL 31, 15, 3, 6
    ENDTEST

; fakeTheme (main.s) uses 2 to 10. Its next pointer's low byte is 30.
colorUsed:
    TEST "color used", NOFILE, NOFILE
    DO_ISUSED 2, 1
    DO_ISUSED 10, 1
    DO_ISUSED 0, 0
    DO_ISUSED 11, 0
    DO_ISUSED 30, 0
    ENDTEST

; The theme screen

saveSame:
    TEST "screen save", three, defs
    DO_SCREEN keysSave
    CHKEMPTY
    CHKFILE "three"
    ENDTEST

pickDown:
    TEST "pick down", three, defs
    DO_SCREEN keysDown
    CHKFILE "three2"
    ENDTEST

pickUp:
    TEST "pick up", three, defs
    DO_SCREEN keysUp
    CHKFILE "three0"
    ENDTEST

pickPastEnd:
    TEST "pick past end", three, defs
    DO_SCREEN keysPastEnd
    CHKFILE "three2"
    ENDTEST

saveReload:
    TEST "save and reload", three, defs
    DO_SCREEN keysDown
    DO_INIT
    CHKSEL 2
    CHKBG 1
    CHKPAL 25, 1, 2, 3
    ENDTEST

changeNumber:
    TEST "change number", three, defs
    DO_SCREEN keysNumber
    CHKFILE "numchg"
    ENDTEST

editRgb:
    TEST "edit rgb", three, defs
    DO_SCREEN keysRgb
    CHKFILE "rgbchg"
    CHKPAL 7, 14, 13, 1
    ENDTEST

changeBg:
    TEST "change background", three, defs
    DO_SCREEN keysBg
    CHKFILE "bgchg"
    CHKPAL 1, 0, 0, 0
    CHKBG 7
    ENDTEST

bgOnUi:
    TEST "background on ui", three, defs
    DO_SCREEN keysBgUi
    CHKFILE "bgui"
    CHKBG 1
    ENDTEST

screenReset:
    TEST "screen reset", three, defs
    DO_SCREEN keysReset
    CHKFILE "defs"
    ENDTEST

screenResetBuiltin:
    TEST "screen reset built-in", three, NOFILE
    DO_SCREEN keysReset
    CHKFILE "builtin"
    ENDTEST
