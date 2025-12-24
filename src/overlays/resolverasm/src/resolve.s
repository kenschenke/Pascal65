;
; resolve.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; resolver overlay miscellaneous routines

.include "asmlib.inc"
.include "4510macros.inc"

.export currentLineNumber, resolverError, setUnitsList, getUnitsList, units

.bss

currentLineNumber: .res 2
units: .res 4

.code

.proc resolverError
    ldx currentLineNumber
    ldy currentLineNumber+1
    jmp compilerError
.endproc

.proc setUnitsList
    stq units
    rts
.endproc

.proc getUnitsList
    ldq units
    rts
.endproc
