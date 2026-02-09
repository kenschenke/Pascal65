;
; logerror.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; logError routine

.include "asmlib.inc"
.include "error.inc"

.export logError, errorNum, errorCount, errorLine

.bss

errorNum: .res 1
errorLine: .res 2
errorCount: .res 1

.code

.proc logError
    ; Ignore this error. It happens because the tests are not resolving the
    ; system unit for each test.
    cpy #errMissingUnitDeclaration
    beq L1

    ldz errorCount
    bne L1              ; only save the first error

    sta errorLine
    stx errorLine+1
    sty errorNum
    inc errorCount
L1: jmp popQ
.endproc
