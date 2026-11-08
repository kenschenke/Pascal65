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

.import genObjCode, setRuntimeStackSize, setCodeGenUnitList, setChainProg
.import setRuntimeFeatures, setRuntimeMode

.segment "JMPTBL"

jmp genObjCode
jmp setRuntimeStackSize
jmp setCodeGenUnitList
jmp setChainProg
jmp setRuntimeFeatures
jmp setRuntimeMode
