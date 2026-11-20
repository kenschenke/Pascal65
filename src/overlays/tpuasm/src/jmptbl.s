;
; jmptbl.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Jump table for the tpu overlay (tpu.inc)

.import tpuBeginX, tpuFinishX, tpuLoadX, tpuMakeX

.segment "JMPTBL"

jmp tpuBeginX
jmp tpuFinishX
jmp tpuLoadX
jmp tpuMakeX
