;
; findUnit.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; findUnit routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export findUnit

.import units

.proc findUnit
    stq ptr4
    ldq units
    stq ptr1

L1: ldq ptr1
    jsr isQZero
    beq L2

    jsr isUnitNameEqual
    beq L2

    ldz #unit::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    bra L1

L2: ldq ptr1
    rts
.endproc

; This routine compares two null-terminated strings in ptr1 and ptr4.
; The Z flag is set if the string are equal.
.proc isUnitNameEqual
    ldz #0
L1: nop
    lda (ptr1),z
    beq L2              ; Branch if null-terminator reached in first string
    nop
    cmp (ptr4),z
    bne L3              ; Branch if the characters are not equal.
    inz
    bne L1

    ; A null-terminator was found in the first string.
    ; The strings are equal if a null-terminator is also the next
    ; character in the second string.
L2: nop
    lda (ptr4),z        ; Load the next character from the second string
L3: rts
.endproc
