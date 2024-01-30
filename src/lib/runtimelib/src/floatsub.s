; Routine to subtract one floating point number from another.
;
; Based on floating point routines published in the book
; 6502 Software Gourmet Guide & Cookbook
; by Robert Findley

.include "float.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp FPSUB

; end of exports
.byte $00, $00, $00

; imports

COMPLM: jmp $0000
FPADD: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

; This routine subtracts FPOP from FPACC and leaves the result in FPACC.
; FPOP is also modified.

.proc FPSUB
    ldx #FOPLSW         ; Set pointer to FPOP least-significant byte
    ldy #3              ; Set precision counter
    jsr COMPLM          ; Complement FPACC
    jmp FPADD           ; Subtract by adding negative
.endproc
