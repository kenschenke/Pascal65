;
; jmptbl.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; intermediate code generation entry points

; .import icodeWriteX, icodeFileEraseX, setIcodeUnitsList

; Everything else code generation needs comes from the icode file (icode.inc):
; the runtime mode and stack size and the libraries from its header and
; imports table, and the runtime features from its EOM.

.import genObjCode, setChainProg

.segment "JMPTBL"

jmp genObjCode
jmp setChainProg
