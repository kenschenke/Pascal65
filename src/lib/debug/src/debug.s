;
; debug.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Jump table for debug library
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.import getHeapUsed, dumpHeap

.segment "JMPTBL"

rts                 ; initialization
nop                 ; pad to three bytes
nop
rts                 ; cleanup
nop                 ; pad to three bytes
nop
jmp dumpHeap
jmp getHeapUsed
