;
; jmptbl.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; parser entry points

.import declResolve, setUnitsList, getUnitsList, injectSystemUnit
.import resolveUnits, setDeclOffsets, setUnitOffsets, fixGlobalOffsets
.import verifyFwdDeclarations, initStandardRoutines

.segment "JMPTBL"

jmp declResolve
jmp setUnitsList
jmp getUnitsList
jmp injectSystemUnit
jmp resolveUnits
jmp setDeclOffsets
jmp setUnitOffsets
jmp fixGlobalOffsets
jmp verifyFwdDeclarations
jmp initStandardRoutines
