;
; typecheck.s
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

.export currentLineNumber, typeCheckError, loadStackValue

.bss

currentLineNumber: .res 2

.code

.proc typeCheckError
    ldx currentLineNumber
    ldy currentLineNumber+1
    jmp compilerError
.endproc

; This routine loads a pointer from the stack and leaves it in Q.
; Stack offset passed in Z.
.proc loadStackValue
    neg
    neg
    nop
    lda (stackPointer),z
    rts
.endproc
