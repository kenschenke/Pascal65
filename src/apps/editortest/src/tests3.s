;
; tests3.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Editor tests: saving and closing files and the file screen (see
; tests.inc)
;
; The tests change the disk, so their order matters. Saving a file that is
; already on the disk writes tmp.txt, scratches the file and renames
; tmp.txt, so the file moves to the end of the directory and a new file can
; take its place. Only the first tests open files by their row in the
; directory screen (see OPENFILE). The theme test saves the editor state,
; which the next test would restore, so it comes last.

.include "editor.inc"
.include "tests.inc"

.export tests

.data

tests:
    .addr saveExisting, saveAsNew, saveAsPascal, saveAsBlank, saveAsEsc
    .addr overwriteNo, overwriteYes, switchFile1, switchFile2, activeBack
    .addr activeBadKey, activePages, activeScreen, fsSave, fsSaveAs
    .addr closeNoSave, closeSave, closeCancel, runUnsaved, fsBackKeys
    .addr fsDirKeys, fsNoFiles, saveAsComment, saveAsShort, theme
    .addr 0

; The key scripts

KEYS


; save.txt has the lines "one" and "two". F3 saves it.
keysSaveExisting:
    OPENFILE 6
    .byte CTRL_K, "!", F3, 0

; F3 asks for a name for a new file
keysSaveAsNew:
    NEWFILE
    .byte "abc", F3, "new1.txt", CR, 0

; Saving as a .pas file makes it a Pascal file and highlights it. The empty
; line has no buffers.
keysSaveAsPascal:
    NEWFILE
    .byte "begin", CR, CR, "end", F3, "p1.pas", CR, 0

; A blank name, or Esc, doesn't save
keysSaveAsBlank:
    NEWFILE
    .byte "a", F3, CR, 0

keysSaveAsEsc:
    NEWFILE
    .byte "a", F3, "zz", BS, ESC, 0

; Saving over a file asks first
keysOverwriteNo:
    NEWFILE
    .byte "a", F3, "hello.txt", CR, "n", 0

keysOverwriteYes:
    NEWFILE
    .byte "q", F3, "noeol.txt", CR, "y", 0

; The file screen's N opens a new file and M lists the open files. A
; number switches to a file.
keysSwitchFile1:
    NEWFILE
    .byte "a"
    NEWFILE
    .byte "b", BACK, "m", "1", 0

keysSwitchFile2:
    NEWFILE
    .byte "a"
    NEWFILE
    .byte "b", BACK, "m", "2", 0

keysActiveBack:
    NEWFILE
    .byte "a", BACK, "m", BACK, "b", 0

; A number with no file is ignored
keysActiveBadKey:
    NEWFILE
    .byte "a", BACK, "m", "5", BACK, "b", 0

; Ten files take two pages. The arrows change the page, but not past the
; first or the last.
keysActivePages:
    .repeat 9
        NEWFILE
    .endrep
    NEWFILE
    .byte "j", BACK, "m", LEFT, RIGHT, RIGHT, LEFT, RIGHT, "1", 0

; The list of open files. The script ends on that screen, so the test
; sees it.
keysActiveScreen:
    OPENFILE 2
    NEWFILE
    .byte "a", BACK, "m", 0

; The file screen's S and A save
keysFsSave:
    NEWFILE
    .byte "z", F3, "fs.txt", CR, "?", BACK, "s", 0

keysFsSaveAs:
    NEWFILE
    .byte "z", BACK, "a", "new2.txt", CR, 0

; The file screen's C closes the file. With no file open, the keys that
; move around do nothing.
keysCloseNoSave:
    NEWFILE
    .byte "a", BACK, "c", "n"
    .byte CTRL_B, CTRL_E, CTRL_N, CTRL_P, CTRL_V, CTRL_W, CTRL_J, CTRL_K
    .byte HOME, UP, DOWN, LEFT, RIGHT, SELECT, PASTE, F3, F5, "x", 0

keysCloseSave:
    OPENFILE 2
    .byte "x", BACK, "c", "y", 0

; Saving a new file before closing it, but with no name, doesn't close it
keysCloseCancel:
    NEWFILE
    .byte "a", BACK, "c", "y", CR, 0

; A file with no name can't be saved, so F5 does nothing
keysRunUnsaved:
    NEWFILE
    .byte "a", F5, "b", 0

; Back leaves the file screen, which ignores other keys
keysFsBackKeys:
    NEWFILE
    .byte "a", BACK, "z", BACK, "b", 0

; The file screen's $ and O show the directory. Back leaves it.
keysFsDirKeys:
    NEWFILE
    .byte "a", BACK, "$", BACK, BACK, "o", BACK, "b", 0

; The list of open files with none open
keysFsNoFiles:
    NEWFILE
    .byte BACK, "c", BACK, "m", "1", BACK, 0

; Highlighting a file saved as Pascal carries comments over lines
keysSaveAsComment:
    NEWFILE
    .byte "(* a", CR, "b *)", F3, "p2.pas", CR, 0

; A name too short to end in .pas
keysSaveAsShort:
    NEWFILE
    .byte "a", F3, "ab", CR, 0

; F4 saves the state, closes every file and returns, to change the theme.
; Closing a changed file asks to save it.
keysTheme:
    NEWFILE
    .byte "a", F4, "n", 0

; The tests

TEXT


saveExisting:
    TEST "save a file", keysSaveExisting, 0, 4, 0, 2, 2
    .asciiz "one!"
    .asciiz "two"
    CHKBYTE EDITFILE::dirty, 0
    CHKDISK "save.txt"
    .byte "one!", CR, "two", CR, 0
    CHKNOTONDISK "tmp.txt"
    ENDTEST

saveAsNew:
    TEST "save as", keysSaveAsNew, 0, 3, 0, 0, 1
    .asciiz "abc"
    CHKNAME "new1.txt"
    CHKBYTE EDITFILE::dirty, 0
    CHKBYTE EDITFILE::isPascal, 0
    CHKDISK "new1.txt"
    .byte "abc", CR, 0
    ENDTEST

saveAsPascal:
    TEST "save as pascal", keysSaveAsPascal, 0, 3, 2, 2, 3
    .asciiz "begin"
    .asciiz ""
    .asciiz "end"
    CHKBYTE EDITFILE::isPascal, 1
    CHKHL 0, "22222"
    CHKHL 2, "222"
    CHKDISK "p1.pas"
    .byte "begin", CR, CR, "end", CR, 0
    ENDTEST

saveAsBlank:
    TEST "save as a blank name", keysSaveAsBlank, 0, 1, 0, 0, 1
    .asciiz "a"
    CHKNAME ""
    CHKBYTE EDITFILE::dirty, 1
    ENDTEST

saveAsEsc:
    TEST "save as, then esc", keysSaveAsEsc, 0, 1, 0, 0, 1
    .asciiz "a"
    CHKNAME ""
    CHKBYTE EDITFILE::dirty, 1
    ENDTEST

overwriteNo:
    TEST "save over a file, no", keysOverwriteNo, 0, 1, 0, 0, 1
    .asciiz "a"
    CHKNAME ""
    CHKBYTE EDITFILE::dirty, 1
    CHKDISK "hello.txt"
    .byte "hello", CR, "world", CR, 0
    ENDTEST

overwriteYes:
    TEST "save over a file, yes", keysOverwriteYes, 0, 1, 0, 0, 1
    .asciiz "q"
    CHKNAME "noeol.txt"
    CHKBYTE EDITFILE::dirty, 0
    CHKDISK "noeol.txt"
    .byte "q", CR, 0
    ENDTEST

switchFile1:
    TEST "switch to file 1", keysSwitchFile1, 0, 1, 0, 0, 1
    .asciiz "a"
    CHKFILES 2
    ENDTEST

switchFile2:
    TEST "switch to file 2", keysSwitchFile2, 0, 1, 0, 0, 1
    .asciiz "b"
    CHKFILES 2
    ENDTEST

activeBack:
    TEST "open files, then back", keysActiveBack, 0, 2, 0, 0, 1
    .asciiz "ab"
    ENDTEST

activeBadKey:
    TEST "open files, no such file", keysActiveBadKey, 0, 2, 0, 0, 1
    .asciiz "ab"
    CHKFILES 1
    ENDTEST

activePages:
    TEST "open files, two pages", keysActivePages, 0, 1, 0, 0, 1
    .asciiz "j"
    CHKFILES 10
    ENDTEST

activeScreen:
    TEST "open files screen", keysActiveScreen, 0, 1, 0, 0, 1
    .asciiz "a"
    CHKSCREEN 4, 7, "  1: hello.txt"
    CHKSCREEN 5, 7, "* 2: No filename (modified)"
    ENDTEST

fsSave:
    TEST "file screen save", keysFsSave, 0, 2, 0, 0, 1
    .asciiz "z?"
    CHKNAME "fs.txt"
    CHKBYTE EDITFILE::dirty, 0
    CHKDISK "fs.txt"
    .byte "z?", CR, 0
    ENDTEST

fsSaveAs:
    TEST "file screen save as", keysFsSaveAs, 0, 1, 0, 0, 1
    .asciiz "z"
    CHKNAME "new2.txt"
    CHKDISK "new2.txt"
    .byte "z", CR, 0
    ENDTEST

closeNoSave:
    TEST "close without saving", keysCloseNoSave, F_NOFILE, 0, 0, 0, 0
    CHKFILES 0
    ENDTEST

closeSave:
    TEST "save and close", keysCloseSave, F_NOFILE, 0, 0, 0, 0
    CHKFILES 0
    CHKDISK "hello.txt"
    .byte "xhello", CR, "world", CR, 0
    ENDTEST

closeCancel:
    TEST "close, but no name", keysCloseCancel, 0, 1, 0, 0, 1
    .asciiz "a"
    CHKFILES 1
    CHKBYTE EDITFILE::dirty, 1
    ENDTEST

runUnsaved:
    TEST "run an unsaved file", keysRunUnsaved, 0, 2, 0, 0, 1
    .asciiz "ab"
    ENDTEST

fsBackKeys:
    TEST "file screen back", keysFsBackKeys, 0, 2, 0, 0, 1
    .asciiz "ab"
    ENDTEST

fsDirKeys:
    TEST "file screen directory", keysFsDirKeys, 0, 2, 0, 0, 1
    .asciiz "ab"
    ENDTEST

fsNoFiles:
    TEST "open files, none open", keysFsNoFiles, F_NOFILE, 0, 0, 0, 0
    CHKFILES 0
    ENDTEST

saveAsComment:
    TEST "save as pascal, comment", keysSaveAsComment, 0, 4, 1, 1, 2
    .asciiz "(* a"
    .asciiz "b *)"
    CHKHL 0, "4444"
    CHKHL 1, "4444"
    ENDTEST

saveAsShort:
    TEST "save as a short name", keysSaveAsShort, 0, 1, 0, 0, 1
    .asciiz "a"
    CHKNAME "ab"
    CHKBYTE EDITFILE::isPascal, 0
    CHKDISK "ab"
    .byte "a", CR, 0
    ENDTEST

theme:
    TEST "theme", keysTheme, F_NOFILE, 0, 0, 0, 0
    CHKLOOP EDITOR_LOOP_THEME
    ENDTEST
