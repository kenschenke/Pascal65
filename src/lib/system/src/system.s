;
; system.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; Jump table for system library

.include "runtime.inc"

.import chr, odd, peek, poke, length, trim, stringOfChar, getkey, getkeynowait
.import upCase, lowerCase, compareStr, contains, beginswith, endswith, strPos
.import sin, cos, tan, fileAssign, fileClose, fileReset, fileRewrite, fileEOF
.import fileIOResult, fileErase, fileRename, setRasterCb, cleanup, init

.segment "JMPTBL"

jmp init
jmp cleanup
jmp fileAssign
jmp beginswith
jmp chr
jmp fileClose
jmp compareStr
jmp contains
jmp cos
jmp endswith
jmp fileEOF
jmp fileErase
jmp getkey
jmp getkeynowait
jmp fileIOResult
jmp length
jmp lowerCase
jmp odd
jmp peek
jmp poke
jmp fileRename
jmp fileReset
jmp fileRewrite
jmp setRasterCb
jmp sin
jmp strPos
jmp stringOfChar
jmp tan
jmp trim
jmp upCase
