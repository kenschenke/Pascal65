;
; jmptbl.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; intermediate code entry points

.import icodeWriteX, icodeFileEraseX, setIcodeUnitsList, getRuntimeFeatures
.import setRuntimeMode, setStackSize, setGlobalSlots

.segment "JMPTBL"

jmp icodeWriteX
jmp icodeFileEraseX
jmp setIcodeUnitsList
jmp getRuntimeFeatures
jmp setRuntimeMode
jmp setStackSize
jmp setGlobalSlots
