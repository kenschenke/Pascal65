;
; screen.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Output a runtime error
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; Jump table for screen library

.import clearScreen, drawChar, drawCharRaw, drawText, drawTextRaw
.import getScreenSize, setScreenSize
.import setBackgroundColor, setBorderColor, setReverse, setTextColor
.import setLowerCase, setUpperCase

.segment "JMPTBL"

rts                 ; initialization
nop                 ; pad to three bytes
nop
rts                 ; cleanup
nop                 ; pad to three bytes
nop
jmp clearScreen
jmp drawChar
jmp drawCharRaw
jmp drawText
jmp drawTextRaw
jmp getScreenSize
jmp setBackgroundColor
jmp setBorderColor
jmp setLowerCase
jmp setReverse
jmp setScreenSize
jmp setTextColor
jmp setUpperCase
