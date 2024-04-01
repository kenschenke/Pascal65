;
; clearinputbuf.s
; Ken Schenke (kenschenke@gmail.com)
;
; Clears the input buffer
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "runtime.inc"

.export clearInputBuf

.proc clearInputBuf
    lda #0
    sta inputBufUsed
    sta inputPos
    rts
.endproc

