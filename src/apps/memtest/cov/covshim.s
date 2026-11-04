;
; covshim.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Resolves the imports of the instrumented copy of memheap.s (see mkcov.pl)
; to asmlib's jump table. ltUint32 is not in the jump table, so it is made
; from geUint32.

.include "asmlib.inc"
.include "zeropage.inc"

.export geUint32, isQZero, runtimeError, ltUint32
.export rtPushQ, rtPopQ

rtPushQ = pushQ
rtPopQ = popQ

.code

; A is 1 if intOp1/intOp2 < intOp32, 0 otherwise. Z is set from A.
.proc ltUint32
    jsr geUint32
    eor #1
    rts
.endproc
