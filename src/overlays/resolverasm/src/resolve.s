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
.include "zeropage.inc"
.include "4510macros.inc"

.export currentLineNumber, resolverError, setUnitsList, getUnitsList, units
.export calcNamePtr

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

; Structure pointer in A/X/Y and structure offset in Z.
; Address returned in Q.
.proc calcNamePtr
    stz intOp32
    ldz #0
    stz intOp32+1
    stz intOp32+2
    stz intOp32+3
    clc
    adcq intOp32
    rts
.endproc
