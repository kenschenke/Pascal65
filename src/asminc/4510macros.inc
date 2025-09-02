;
; 4510macros.inc
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; CA65 macros for CSG 4510 instructions

.macro ldq addr
    neg
    neg
    lda addr
.endmacro

.macro stq addr
    neg
    neg
    sta addr
.endmacro

.macro cpq addr
    neg
    neg
    cmp addr
.endmacro

.macro adcq addr
    neg
    neg
    adc addr
.endmacro

.macro sbcq addr
    neg
    neg
    sbc addr
.endmacro

.macro orq addr
    neg
    neg
    ora addr
.endmacro

.macro aslq
    neg
    neg
    asl
.endmacro

.macro inq
    neg
    neg
    inc
.endmacro

.macro deq
    neg
    neg
    dec
.endmacro
