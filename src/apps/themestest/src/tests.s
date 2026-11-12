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
    .addr changeNumber, editRgb, changeBg, changeBgReload, bgOnUi
    .addr screenReset, screenResetBuiltin
    .addr readOld, oldPartial, oldLoad, oldWrite, oldScreen, oldReload
    .addr version2, markerOnly, markerVersion, headerOnly, newColors
    .addr newColorsLoad
    .addr changeError, changeWarning, editErrorRgb, bgOnError, sampleScreen
    .addr paletteHelp
    .addr 0

; The fixtures
three: .asciiz "three"
three0: .asciiz "three0"
three2: .asciiz "three2"
sel9: .asciiz "sel9"
partialFx: .asciiz "partial"
onlysel: .asciiz "onlysel"
defs: .asciiz "defs"
old: .asciiz "old"
oldpart: .asciiz "oldpart"
version2Fx: .asciiz "version2"
marker: .asciiz "marker"
markerver: .asciiz "markerver"
hdronly: .asciiz "hdronly"
newcolors: .asciiz "newcolors"

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
; Error, down to the next index; warning, up to the one before
keysErr:
    .byte CR, K_E, DOWN, CR, F1, 0
keysWarn:
    .byte CR, K_W, UP, CR, F1, 0
; Error, edit: red down one
keysErrRgb:
    .byte CR, K_E, K_E, K_R, LEFT, CR, CR, F1, 0
keysBgErr:
    .byte CR, K_B, DOWN, DOWN, DOWN, DOWN, DOWN, CR, F1, 0
; Into the palette, where the script runs out
keysPalette:
    .byte CR, K_E, 0

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
    CHKBUF 7, 2, $42, 11, 14, 13, 8, 1, 6, 1, 1
    CHKPAL 18, 15, 11, 0
    CHKBG 6
    CHKEMPTY
    ENDTEST

loadAlpha:
    TEST "load alpha", three0, defs
    DO_LOAD
    CHKBUF 5, 4, 3, 12, 1, 10, $43, 1, $45, 1, 1
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

; fakeTheme (main.s) uses 2 to 12; 11 and 12 are the error and warning
; colors. Its next pointer's low byte is 30.
colorUsed:
    TEST "color used", NOFILE, NOFILE
    DO_ISUSED 2, 1
    DO_ISUSED 10, 1
    DO_ISUSED 11, 1
    DO_ISUSED 12, 1
    DO_ISUSED 0, 0
    DO_ISUSED 13, 0
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

; The error and warning colors share the UI color's slot. They take its new
; RGB, so loading the theme again (they are written to the palette after
; it) leaves the UI color black.
changeBgReload:
    TEST "change background reload", three, defs
    DO_SCREEN keysBg
    DO_INIT
    CHKCOLOR 1, SYNTAXHL_ERROR, 1, 0, 0, 0
    CHKCOLOR 1, SYNTAXHL_WARNING, 1, 0, 0, 0
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

; Version 0 files. Each theme gets copies of its UI color as its error and
; warning colors: Alpha's is 1 13 13 13, Beta's 1 (white) and Gamma's 0.

readOld:
    TEST "read version 0", old, defs
    DO_INIT
    CHKCOUNT 3
    CHKSEL 1
    CHKNAME 2, "Gamma"
    CHKCOLOR 0, SYNTAXHL_BACKGROUND, 21, 2, 3, 5
    CHKCOLOR 0, SYNTAXHL_ERROR, 1, 13, 13, 13
    CHKCOLOR 0, SYNTAXHL_WARNING, 1, 13, 13, 13
    CHKCOLOR 1, SYNTAXHL_ERROR, 1, 15, 15, 15
    CHKCOLOR 1, SYNTAXHL_WARNING, 1, 15, 15, 15
    CHKCOLOR 2, SYNTAXHL_BACKGROUND, 1, 15, 15, 15
    CHKCOLOR 2, SYNTAXHL_ERROR, 0, 0, 0, 0
    CHKCOLOR 2, SYNTAXHL_WARNING, 0, 0, 0, 0
    CHKBG 6
    ENDTEST

; The partial third theme is dropped
oldPartial:
    TEST "version 0 partial", oldpart, defs
    DO_INIT
    CHKCOUNT 2
    CHKSEL 1
    CHKNAME 1, "Beta"
    CHKCOLOR 1, SYNTAXHL_WARNING, 1, 15, 15, 15
    ENDTEST

oldLoad:
    TEST "version 0 load", old, defs
    DO_LOAD
    CHKBUF 7, 2, $42, 11, 14, 13, 8, 1, 6, 1, 1
    CHKEMPTY
    ENDTEST

; Writing a version 0 list writes version 1
oldWrite:
    TEST "version 0 write", old, defs
    DO_INIT
    DO_WRITE
    CHKFILE "three"
    ENDTEST

oldScreen:
    TEST "version 0 screen save", old, defs
    DO_SCREEN keysSave
    CHKFILE "three"
    ENDTEST

oldReload:
    TEST "version 0 save and reload", old, defs
    DO_SCREEN keysSave
    DO_INIT
    CHKCOUNT 3
    CHKSEL 1
    CHKCOLOR 2, SYNTAXHL_ERROR, 0, 0, 0, 0
    CHKCOLOR 0, SYNTAXHL_WARNING, 1, 13, 13, 13
    CHKBG 6
    ENDTEST

; Unreadable version 1 files fall back to themes.def

version2:
    TEST "version 2", version2Fx, defs
    DO_INIT
    CHKCOUNT 2
    CHKSEL 1
    CHKNAME 0, "Def One"
    CHKBG 30
    ENDTEST

markerOnly:
    TEST "marker only", marker, defs
    DO_INIT
    CHKCOUNT 2
    CHKSEL 1
    CHKNAME 0, "Def One"
    ENDTEST

markerVersion:
    TEST "marker and version", markerver, defs
    DO_INIT
    CHKCOUNT 2
    CHKSEL 1
    CHKNAME 0, "Def One"
    ENDTEST

headerOnly:
    TEST "header only", hdronly, defs
    DO_INIT
    CHKCOUNT 2
    CHKSEL 1
    CHKNAME 0, "Def One"
    ENDTEST

; The error and warning colors in their own palette slots

newColors:
    TEST "new colors", newcolors, NOFILE
    DO_INIT
    CHKCOUNT 1
    CHKSEL 0
    CHKCOLOR 0, SYNTAXHL_ERROR, 26, 1, 2, 3
    CHKCOLOR 0, SYNTAXHL_WARNING, 27, 4, 5, 6
    CHKPAL 26, 1, 2, 3
    CHKPAL 27, 4, 5, 6
    DO_WRITE
    CHKFILE "newcolors"
    ENDTEST

newColorsLoad:
    TEST "new colors load", newcolors, NOFILE
    DO_LOAD
    CHKBUF 5, 4, 3, 12, 1, 10, $43, 1, $45, $4a, $4b
    CHKPAL 27, 4, 5, 6
    CHKEMPTY
    ENDTEST

; Editing the error and warning colors on the theme screen. The sample's
; error line is screen row 8 and its warning line row 13 (codesample.s);
; column 10 is the reversed n or i.

changeError:
    TEST "change error", three, defs
    DO_SCREEN keysErr
    CHKFILE "errchg"
    CHKPAL 2, 15, 0, 0
    CHKCELL 8, 10, $8e, 2
    CHKCELL 13, 10, $89, 1
    DO_LOAD
    CHKBUF 7, 2, $42, 11, 14, 13, 8, 1, 6, 2, 1
    ENDTEST

changeWarning:
    TEST "change warning", three, defs
    DO_SCREEN keysWarn
    CHKFILE "warnchg"
    CHKPAL 0, 0, 0, 0
    CHKCELL 13, 10, $89, 0
    CHKCELL 8, 10, $8e, 1
    DO_LOAD
    CHKBUF 7, 2, $42, 11, 14, 13, 8, 1, 6, 1, 0
    ENDTEST

; The UI and warning colors share the error color's slot
editErrorRgb:
    TEST "edit error rgb", three, defs
    DO_SCREEN keysErrRgb
    CHKFILE "errrgb"
    CHKPAL 1, 14, 15, 15
    ENDTEST

; The background lands on the error color's slot, so the error color
; moves to the UI color's
bgOnError:
    TEST "background on error", newcolors, NOFILE
    DO_SCREEN keysBgErr
    CHKFILE "bgerr"
    CHKBG 26
    CHKPAL 1, 15, 15, 15
    CHKPAL 26, 1, 2, 3
    CHKPAL 27, 4, 5, 6
    CHKCELL 8, 10, $8e, 1
    CHKCELL 13, 10, $89, $4b
    ENDTEST

; The code sample's error and warning lines, reversed in their colors from
; border to border, and the help text's E and W row
sampleScreen:
    TEST "sample screen", newcolors, NOFILE
    DO_SCREEN keysSave
    CHKCELL 8, 4, $5d, 1        ; The left border, in the UI color
    CHKCELL 8, 5, $a0, $4a      ; Index 26
    CHKCELL 8, 10, $8e, $4a
    CHKCELL 8, 38, $a0, $4a
    CHKCELL 8, 39, $5d, 1
    CHKCELL 13, 5, $a0, $4b     ; Index 27
    CHKCELL 13, 10, $89, $4b
    CHKCELL 13, 38, $a0, $4b
    CHKCELL 7, 10, $09, 10      ; i, an identifier, not reversed
    CHKCELL 7, 14, $42, 4       ; Byte, a keyword
    CHKCELL 17, 4, $43, 1       ; C:Comments
    CHKCELL 20, 4, $45, 1       ; E:Error
    CHKCELL 20, 19, $57, 1      ; W:Warning
    CHKCELL 22, 3, $46, 1       ; F1:Save+Exit
    CHKCELL 23, 3, $4f, 1       ; On exit
    ENDTEST

; The palette's help text replaces the main help (rows 17 to 23)
paletteHelp:
    TEST "palette help", three, defs
    DO_SCREENOUT keysPalette
    CHKCELL 17, 9, $2a, 1       ; * = Currently selected color
    CHKCELL 17, 13, $43, 1
    CHKCELL 18, 9, $55, 1       ; Use arrows
    CHKCELL 20, 9, $52, 1       ; Return to use
    CHKCELL 21, 9, $50, 1       ; Press E
    CHKCELL 17, 4, $20, 1       ; The main help is gone
    CHKCELL 20, 4, $20, 1
    CHKCELL 22, 3, $20, 1
    CHKCELL 23, 3, $20, 1
    ENDTEST
