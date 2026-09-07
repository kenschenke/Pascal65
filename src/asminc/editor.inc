;
; editor.inc
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Editor Definitions

MAX_LINE_LENGTH = 80
EDITOR_LOOP_CONTINUE = 0
EDITOR_LOOP_QUIT = 1
EDITOR_LOOP_COMPILE = 2
EDITOR_LOOP_RUN = 3
EDITOR_LOOP_DEBUG = 4

DEFAULT_COLS = 80
DEFAULT_ROWS = 25
STATUSCOL_X = 71
STATUSCOL_X_LABEL = 69
STATUSCOL_Y = 77
STATUSCOL_Y_LABEL = 75
STATUSCOL_RO = 57
STATUSCOL_MEM = 62

CTRL_B = 2
CH_WHITE = 5
CTRL_E = 5
CH_TAB = 9
CTRL_J = 10
CTRL_K = 11
CH_ENTER = 13
CH_LOWERCASE = 14
CTRL_N = 14
CTRL_P = 16
CH_CURS_DOWN = 17
CH_REVERSE_ON = 18
CH_HOME = 19
CH_BACKSPACE = 20
CTRL_U = 21
CTRL_V = 22
CTRL_W = 23
CTRL_X = 24
CTRL_Y = 25
CH_ESC = 27
CH_CURS_RIGHT = 29
CH_HELP = 31
CH_DOUBLE_QUOTE = 34
CH_CLEAR = 93
CH_BACKARROW = 95
CH_ORANGE = 129
CH_CURS_UP = 145
CH_REVERSE_OFF = 146
CH_CLRSCR = 147
CH_INS = 148
CH_CURS_LEFT = 157
CH_F1 = 241
CH_F2 = 242
CH_F3 = 243
CH_F5 = 245
CH_F7 = 247
CH_F8 = 248
CH_DELETE_SOL = 250
CH_DELETE_EOL = 251
CH_25_ROWS = 252
CH_50_ROWS = 253

; These are screen codes, not PETSCII
CH_UL_CORNER = 112
CH_HORIZ_LINE = 64
CH_UPPER_TEE = 114
CH_UR_CORNER = 110
CH_VERT_LINE = 93
CH_LEFT_TEE = 107
CH_BOTTOM_TEE = 113
CH_RIGHT_TEE = 115
CH_LL_CORNER = 109
CH_LR_CORNER = 125

COLOR_WHITE = 1

COLOR_CURSOR = 67 ; lemon tart

SYNTAXHL_NONE = 0
SYNTAXHL_NUMBER = 1
SYNTAXHL_KEYWORD = 2
SYNTAXHL_STRING = 3
SYNTAXHL_COMMENT = 4

SYNTAXCOLOR_NONE = COLOR_WHITE ; white
SYNTAXCOLOR_NUMBER = 5 ; green
SYNTAXCOLOR_KEYWORD = 65 ; rambutan (orange)
SYNTAXCOLOR_STRING = 10 ; light red
SYNTAXCOLOR_COMMENT = 12 ; light grey

; Syntax highlighting character codes
.enum
    shLetter
    shDigit
    shSpecial
    shQuote
    shWhiteSpace
    shDollar
    shHash
    shPercent
    shError
.endenum

.struct EDITFILE
    nextFile .dword         ; Pointer to the next EDITFILE record
    cx .byte                ; cursor X
    cy .word                ; cursor Y
    rowOff .word            ; top row on screen
    colOff .byte            ; left-most column on screen
    firstLine .dword        ; pointer to first line in file
    numLines .word          ; # of lines in file
    readOnly .byte          ; non-zero if file is read-only
    dirty .byte             ; non-zero if file is modified
    isPascal .byte          ; non-zero if the file is a Pascal source file
    filename .res 17        ; null-terminated filename
    inSelection .byte       ; non-zero if text is selected
    selectionY .word        ; anchor point Y for selection
    startHY .word           ; start of selection for highlighting
    endHY .word             ; end of selection for highlighting
.endstruct

.struct EDITLINE
    buffer .dword           ; Pointer to buffer containing line text
    syntaxHL .dword         ; Pointer to buffer containing syntax highlighting
    length .byte            ; Number of characters used in buffer
    capacity .byte          ; Size of buffer
    dirty .byte             ; Non-zero if line needs to be re-rendered
    continuedComment .byte  ; Non-zero if the line starts with a continued multi-line comment
    next .dword             ; Pointer to next line or null
.endstruct

.struct DIRENT
    filename .res 16        ; space-filled, not null-terminated
    blocks .res 3           ; number of blocks on disk in PETSCII, space-filled
    type .res 3             ; space-filled file type - SEQ, PRG, etc
    next .res 4             ; pointer to next file in directory or NULL
.endstruct
