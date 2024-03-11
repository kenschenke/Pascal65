; Jump table for screen library

.import clearScreen, drawChar, drawCharRaw, drawText, drawTextRaw
.import getScreenSize, setScreenSize
.import setBackgroundColor, setBorderColor, setReverse, setTextColor
.import setLowerCase, setUpperCase

.segment "JMPTBL"

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
