;
; reset.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Calls reset vector.
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.export _reset

.proc _reset
    jmp ($fffc)
.endproc
