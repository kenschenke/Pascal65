;
; setIcodeUnitList.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "4510macros.inc"

.export setIcodeUnitsList, units

.bss

units: .res 4

.code

.proc setIcodeUnitsList
    stq units
    rts
.endproc
