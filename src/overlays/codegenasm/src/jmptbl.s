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

; The runtime mode and stack size come from the icode file's header and
; the runtime features from its EOM (icode.inc), not from the compiler apps.

.import genObjCode, setCodeGenUnitList, setChainProg

.segment "JMPTBL"

jmp genObjCode
jmp setCodeGenUnitList
jmp setChainProg
