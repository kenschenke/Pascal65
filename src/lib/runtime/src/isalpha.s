;
; isalpha.s
; Ken Schenke (kenschenke@gmail.com)
;
; Tests PETSCII for alphabetic character
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

.export isAlpha

; This routine returns a 0 or 1 in X if the
; PETSCII character in A is a letter
.proc isAlpha
    cmp #'a'
    bcc NO          ; branch if < 'a'
    cmp #'z'+1
    bcc YS          ; branch if <= 'z'
    cmp #'A'
    bcc NO          ; branch if < 'A'
    cmp #'Z'+1
    bcc YS          ; branch if <= 'Z'
NO: ldx #0
    rts
YS: ldx #1
    rts
.endproc
