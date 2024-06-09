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
.import upCase, lowerCase, compareStr, contains, beginswith, endswith, strPos
.import sin, cos

.segment "JMPTBL"

jmp beginswith
jmp chr
jmp compareStr
jmp contains
jmp cos
jmp endswith
jmp getkey
jmp getkeynowait
jmp odd
jmp length
jmp lowerCase
jmp peek
jmp poke
jmp sin
jmp strPos
jmp stringOfChar
jmp trim
jmp upCase
