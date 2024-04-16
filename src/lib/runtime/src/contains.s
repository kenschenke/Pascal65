;
; contains.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Contains runtime function
;
; Inputs:
;   ptr1: pointer to source string
;   ptr2: pointer to substring
;   tmp1: length of source string
;   tmp2: length of substring
; Outputs:
;   A: 1 if source string contains substring

.include "runtime.inc"

.export contains

.import strFind

.proc contains
    jmp strFind
.endproc
