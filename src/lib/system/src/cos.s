;
; cos.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; Contains runtime function

.include "runtime.inc"

.export cos

.proc cos
    lda #0
    jsr rtLibLoadParam
    jsr rtCosine
    jmp rtLibReturnValue
.endproc
