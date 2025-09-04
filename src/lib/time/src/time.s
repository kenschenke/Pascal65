;
; time.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; Jump table for Time Unit

.import getDateTime, getTicks, resetTicks

.segment "JMPTBL"

rts
nop
nop
rts
nop
nop
jmp getDateTime
jmp getTicks
jmp resetTicks
