;
; system.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; Jump table for system library

.import chr, odd, peek, poke, length, trim, stringOfChar, getkey, getkeynowait
.import upCase, lowerCase, compareStr

.segment "JMPTBL"

jmp chr
jmp compareStr
jmp getkey
jmp getkeynowait
jmp odd
jmp length
jmp lowerCase
jmp peek
jmp poke
jmp stringOfChar
jmp trim
jmp upCase
