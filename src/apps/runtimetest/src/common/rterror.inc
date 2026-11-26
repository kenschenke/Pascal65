;;;
 ; rterror.inc
 ; Ken Schenke (kenschenke@gmail.com)
 ;
 ; Catching runtime errors in the runtime test suites (rterror.s)
 ;
 ; Copyright (c) 2026
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.import rteCatch, rteCatchSP, rteCode

; Arms a catch: a runtime error jumps to handler with the stack pointer as
; it is here and the error's code in rteCode. Changes A and X.
.macro CATCH_RTE handler
    tsx
    stx rteCatchSP
    lda #<(handler)
    sta rteCatch
    lda #>(handler)
    sta rteCatch+1
.endmacro

; Disarms the catch. Keeps the flags and A, X and Y.
.macro UNCATCH_RTE
    php
    pha
    lda #0
    sta rteCatch+1
    pla
    plp
.endmacro
