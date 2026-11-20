;
; tpu.inc
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Compiled unit (.tpu) file format and the tpuasm overlay's entries
; (plans/tpu.md). A unit compiled on its own (unit mode) is written to
; <unit>.tpu. Words are low byte first.
;
;    TPU_MAGIC0, TPU_MAGIC1, TPU_VERSION
;    ICODE_VERSION              the icode format of the icode section
;    flags                      TPU_FLAG_*
;    source CRC (2 bytes)       of <unit>.pas when it was compiled
;    interface CRC (2 bytes)    of the interface section
;    used units: a count byte, then each unit's name (its length, then
;        its characters) and the interface CRC it was compiled with
;    interface section: its length (2 bytes), then a pre-compiled header
;        (hdr.inc) of the unit's interface, as the parser made it
;    icode section: its length (2 bytes), then the unit's icode file
;
; A CRC is CRC-16/CCITT: polynomial $1021, starting at $FFFF. A used
; unit's interface CRC is that of the interface section its own TPU would
; have, so a library's is of its interface too.

TPU_BASE = $4000

tpuBegin  = TPU_BASE        ; after parsing; see tpu.s
tpuFinish = TPU_BASE + 3    ; after icode; see tpu.s
tpuLoad   = TPU_BASE + 6    ; a unit from its TPU; see tpuload.s
tpuMake   = TPU_BASE + 9    ; the next unit to compile; see tpumake.s

TPU_MAGIC0 = $54            ; "TP", as numbers so no charmap changes them
TPU_MAGIC1 = $50
TPU_VERSION = 1

TPU_FLAG_OVERLAY = 1        ; not used yet (plans/overlays.md)
