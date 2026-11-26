;;;
 ; rtt.inc
 ; Ken Schenke (kenschenke@gmail.com)
 ;
 ; Definitions shared by the runtime test suites
 ;
 ; Copyright (c) 2026
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

; Each suite is its own PRG. The PRGs chain: a suite that passes loads the
; next one (start.s), so the suites never have to fit in one program. The
; chain loader and the state the suites share live below $1EFA
; (RTERR_RECORD in asm.inc), which a LOAD at $2001 leaves alone.

CHAIN_LOADER = $1600        ; The loader and the next suite's name
RTT_STATE = $1d00           ; The state the suites share

; The state block
rttChainFlag = RTT_STATE    ; CHAIN_MAGIC1, 2 when the loader started this PRG
rttSuites = RTT_STATE + 2   ; Number of suites that have passed
rttZpSave = RTT_STATE + 3   ; BASIC's zero page, RTT_ZP_FIRST to RTT_ZP_LAST
RTT_ZP_FIRST = $04          ; The runtime's zero page (runtime.inc)
RTT_ZP_LAST = $65
RTT_ZP_SIZE = RTT_ZP_LAST - RTT_ZP_FIRST + 1
.assert rttZpSave + RTT_ZP_SIZE <= $1efa, error, "state overlaps RTERR_RECORD"

CHAIN_MAGIC1 = $c7
CHAIN_MAGIC2 = $3a

; Memory a suite can use as it likes, such as for a heap. The program
; ends below it (runtimetest.cfg).
TESTMEM = $7000
TESTMEM_END = $9000


; Loads A/X with a 16-bit value
.macro LDAX val
    lda #<(val)
    ldx #>(val)
.endmacro
