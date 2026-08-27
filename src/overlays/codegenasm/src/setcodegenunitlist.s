;
; setCodeGenUnitList.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; setCodeGenUnitList routine

.include "4510macros.inc"

.export setCodeGenUnitList, units

.bss

units: .res 4

.code

; Unit list passed in Q
.proc setCodeGenUnitList
    stq units
    rts
.endproc
