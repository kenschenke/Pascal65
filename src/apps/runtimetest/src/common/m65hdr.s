;
; m65hdr.s
; Ken Schenke (kenschenke@gmail.com)
;
; BASIC header for MEGA65 PRGs
;
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; The following symbol is used by linker config to force the module
; to get included into the output file
        .export         __M65HDR__: absolute = 1

.segment        "M65HDR"

        .addr   Next
        .word   .version        ; Line number
        .byte   $fe,$02         ; BANK token
        .byte   "0:"            ; BANK argument
        .byte   $9E             ; SYS token
        .byte   <(((Start /  1000) .mod 10) + '0')
        .byte   <(((Start /   100) .mod 10) + '0')
        .byte   <(((Start /    10) .mod 10) + '0')
        .byte   <(((Start /     1) .mod 10) + '0')
        .byte   $00             ; End of BASIC line
Next:   .word   0               ; BASIC end marker
Start:

; The chain loader (start.s) jumps here after it loads a suite
.assert (Start = $2011), error, "The chain loader expects the entry at $2011"
