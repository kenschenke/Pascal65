;
; typeCheckUnits.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export typeCheckUnits

.import declTypeCheck
.import loadQPtr1

.bss

thisUnit: .res 4

.code

; Unit list passed in Q
.proc typeCheckUnits
    stq thisUnit

    ; Loop through the units
L1: ldq thisUnit
    jsr isQZero
    bne :+
    rts
    ; Errors and warnings are in the unit's source file
:   jsr setCompilerUnitFilename
    ldq thisUnit
    stq ptr1
    ldz #unit::astRoot
    jsr loadQPtr1
    jsr declTypeCheck

    ldq thisUnit
    stq ptr1
    ldz #unit::next
    jsr loadQPtr1
    stq thisUnit
    bra L1
.endproc
