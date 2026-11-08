;
; rthdr.s
; Ken Schenke (kenschenke@gmail.com)
;
; Header of the dynamic runtime
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

; The dynamic runtime, runtimeN, starts with this header (RTH_* in asm.inc).
; A program's loader checks it before it loads the runtime. It's linked only
; into runtimeN (see mkruntime.py).

.include "asm.inc"

.import __RTHDR_RUN__, __BSS_RUN__, __BSS_SIZE__, __PKGBSS_SIZE__

.segment "RTHDR"

    .byte RTH_MAGIC0, RTH_MAGIC1, RTH_MAGIC2, RTH_MAGIC3
    .byte RT_ABI_VERSION
    .word __RTHDR_RUN__                 ; rtLow
    .word __BSS_RUN__
    .word __BSS_SIZE__ + __PKGBSS_SIZE__
