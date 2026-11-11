;
; tests5.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Editor tests: selecting, cutting, copying and pasting, the longest line
; and keys with no file open (see tests.inc)

.include "editor.inc"
.include "tests.inc"

.export tests

.data

tests:
    .addr cutLast, cutFirst, cutAll, pasteTop, pasteMiddle, pasteEnd
    .addr selectUp, selectBs, selectCancel, pastePascal, typeLong
    .addr tabLong, insLong, joinLong, atCaret, escKeys, noFileQuit
    .addr noFileHelp, helpWithFile, ignoredKeys, ignoredClean, escOther
    .addr titleScreen, noFileTheme
    .addr 0

; The key scripts

KEYS

; Ctrl+Y starts a selection at the cursor's line and the cursor keys move
; its other end. X cuts the selected lines.
keysCutLast:
    NEWFILE
    .byte "a", CR, "b", CR, "c", UP, SELECT, DOWN, "x", 0

keysCutFirst:
    NEWFILE
    .byte "a", CR, "b", UP, SELECT, "x", 0

keysCutAll:
    NEWFILE
    .byte "a", CR, "b", SELECT, UP, "x", 0

; Ctrl+U pastes the lines above the cursor's line
keysPasteTop:
    NEWFILE
    .byte "a", CR, "b", SELECT, "c", CTRL_B, PASTE, 0

keysPasteMiddle:
    NEWFILE
    .byte "a", CR, "b", UP, SELECT, DOWN, "c", PASTE, 0

; Pasting on the line after a file's last line (see tests2.s)
keysPasteEnd:
    OPENFILE 2
    .byte SELECT, "c", CTRL_E, PASTE, 0

; The cursor above the selection's start
keysSelectUp:
    NEWFILE
    .byte "a", CR, "b", CR, "c", SELECT, UP, UP, "c", CTRL_E, PASTE, 0

; Backspace deletes the selected lines
keysSelectBs:
    NEWFILE
    .byte "a", CR, "b", SELECT, BS, 0

; Back cancels a selection. Other keys do nothing while there is one.
keysSelectCancel:
    NEWFILE
    .byte "a", SELECT, "z", BACK, "b", 0

; Pasting into a Pascal file highlights the pasted lines. They are inside
; the comment the line after them is in.
keysPastePascal:
    NEWFILE
    .byte "(* a", CR, "b *) c", UP, SELECT, DOWN, "c", CTRL_E, PASTE, 0

; A line holds at most 80 characters
keysTypeLong:
    NEWFILE
    .repeat 85
        .byte "a"
    .endrep
    .byte 0

keysTabLong:
    NEWFILE
    .repeat 80
        .byte "a"
    .endrep
    .byte TABKEY, "b", 0

keysInsLong:
    NEWFILE
    .repeat 80
        .byte "a"
    .endrep
    .byte HOME, INS, 0

; Backspace doesn't join lines that would be too long together
keysJoinLong:
    NEWFILE
    .repeat 50
        .byte "a"
    .endrep
    .byte CR
    .repeat 50
        .byte "b"
    .endrep
    .byte HOME, BS, 0

; @ and the up arrow ($af) aren't changed like letters
keysAtCaret:
    NEWFILE
    .byte "@", $af, 0

; Esc B, Esc E and Esc V are Ctrl+B, Ctrl+E and Ctrl+V
keysEscKeys:
    NEWFILE
    .byte "a", CR, "b", ESC, "b", "x", ESC, "e", "y", ESC, "v", 0

; With every file closed, Ctrl+X quits. The keys after it aren't read.
keysNoFileQuit:
    NEWFILE
    .byte BACK, "c", CTRL_X, BACK, "n", 0

; Help with a file open
keysHelpWithFile:
    NEWFILE
    .byte "a", HELP, 0

; Keys the editor doesn't use aren't typed: F2, Ctrl+A, F3 with Shift
; ($86) and F14 ($fe)
keysIgnoredKeys:
    NEWFILE
    .byte "a", CH_F2, $01, $86, $fe, "b", 0

; and don't make the file modified
keysIgnoredClean:
    OPENFILE 2
    .byte CH_F2, $01, 0

; Esc and a key that isn't an Esc command types the key
keysEscOther:
    NEWFILE
    .byte ESC, "x", ESC, "X", 0

; The title screen shows while no file is open. Typing does nothing.
keysTitleScreen:
    .byte "x", BACK, "n", 0

; F4 with no file open. It saves the state, so it comes last.
keysNoFileTheme:
    NEWFILE
    .byte BACK, "c", F4, 0

keysNoFileHelp:
    NEWFILE
    .byte BACK, "c", HELP, 0

; The tests

TEXT

cutLast:
    TEST "cut the last lines", keysCutLast, 0, 1, 0, 0, 1
    .asciiz "a"
    CHKBYTE EDITFILE::inSelection, 0
    ENDTEST

cutFirst:
    TEST "cut the first line", keysCutFirst, 0, 1, 0, 0, 1
    .asciiz "b"
    ENDTEST

cutAll:
    TEST "cut every line", keysCutAll, 0, 0, 0, 0, 0
    ENDTEST

pasteTop:
    TEST "paste on the first line", keysPasteTop, 0, 0, 1, 2, 3
    .asciiz "b"
    .asciiz "a"
    .asciiz "b"
    ENDTEST

pasteMiddle:
    TEST "paste two lines", keysPasteMiddle, 0, 1, 3, 3, 4
    .asciiz "a"
    .asciiz "a"
    .asciiz "b"
    .asciiz "b"
    ENDTEST

pasteEnd:
    TEST "paste after the last line", keysPasteEnd, 0, 0, 3, 3, 3
    .asciiz "hello"
    .asciiz "world"
    .asciiz "hello"
    ENDTEST

selectUp:
    TEST "select upwards", keysSelectUp, 0, 0, 5, 5, 6
    .asciiz "a"
    .asciiz "b"
    .asciiz "a"
    .asciiz "b"
    .asciiz "c"
    .asciiz "c"
    ENDTEST

selectBs:
    TEST "backspace a selection", keysSelectBs, 0, 1, 0, 0, 1
    .asciiz "a"
    ENDTEST

selectCancel:
    TEST "cancel a selection", keysSelectCancel, 0, 2, 0, 0, 1
    .asciiz "ab"
    CHKBYTE EDITFILE::inSelection, 0
    ENDTEST

pastePascal:
    TEST "paste into pascal", keysPastePascal, F_PASCAL, 0, 3, 3, 4
    .asciiz "(* a"
    .asciiz "(* a"
    .asciiz "b *) c"
    .asciiz "b *) c"
    CHKHL 0, "4444"
    CHKHL 1, "4444"
    CHKHL 2, "444486"
    CHKHL 3, "444486"
    ENDTEST

typeLong:
    TEST "type a long line", keysTypeLong, 0, 80, 0, 0, 1
    .repeat 80
        .byte "a"
    .endrep
    .byte 0
    ENDTEST

tabLong:
    TEST "tab on a full line", keysTabLong, 0, 80, 0, 0, 1
    .repeat 80
        .byte "a"
    .endrep
    .byte 0
    ENDTEST

insLong:
    TEST "insert on a full line", keysInsLong, 0, 0, 0, 0, 1
    .repeat 80
        .byte "a"
    .endrep
    .byte 0
    ENDTEST

joinLong:
    TEST "join long lines", keysJoinLong, 0, 0, 1, 1, 2
    .repeat 50
        .byte "a"
    .endrep
    .byte 0
    .repeat 50
        .byte "b"
    .endrep
    .byte 0
    ENDTEST

atCaret:
    TEST "at sign and up arrow", keysAtCaret, 0, 2, 0, 0, 1
    .asciiz "@^"
    ENDTEST

escKeys:
    TEST "esc b, e and v", keysEscKeys, 0, 1, 1, 1, 2
    .asciiz "xa"
    .asciiz "yb"
    ENDTEST

noFileQuit:
    TEST "quit with no file open", keysNoFileQuit, F_NOFILE, 0, 0, 0, 0
    CHKFILES 0
    ENDTEST

noFileHelp:
    TEST "help with no file open", keysNoFileHelp, F_SKIPLINES, 0, 0, 33, 0
    CHKNAME "Help File"
    CHKFILES 1
    ENDTEST

helpWithFile:
    TEST "help with a file open", keysHelpWithFile, F_SKIPLINES, 0, 0, 33, 0
    CHKNAME "Help File"
    CHKFILES 2
    ENDTEST

ignoredKeys:
    TEST "ignored keys", keysIgnoredKeys, 0, 2, 0, 0, 1
    .asciiz "ab"
    ENDTEST

ignoredClean:
    TEST "ignored keys, not modified", keysIgnoredClean, 0, 0, 0, 2, 2
    .asciiz "hello"
    .asciiz "world"
    CHKBYTE EDITFILE::dirty, 0
    ENDTEST

escOther:
    TEST "esc and another key", keysEscOther, 0, 2, 0, 0, 1
    .asciiz "xX"
    ENDTEST

titleScreen:
    TEST "typing on the title screen", keysTitleScreen, 0, 0, 0, 0, 0
    CHKFILES 1
    ENDTEST

noFileTheme:
    TEST "theme with no file open", keysNoFileTheme, F_NOFILE, 0, 0, 0, 0
    CHKLOOP EDITOR_LOOP_THEME
    ENDTEST
