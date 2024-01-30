; Routines to compare two floating point numbers.
;
; Based on floating point routines published in the book
; 6502 Software Gourmet Guide & Cookbook
; by Robert Findley

.include "float.inc"
.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp floatEq
jmp floatGt
jmp floatGte
jmp floatLt
jmp floatLte

; end of exports
.byte $00, $00, $00

; imports

FPSUB: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

; This routine compares the floating point number in FPACC with
; the one in FPOP and returns a non-zero in A if FPACC equals FPOP.
.proc floatEq
    lda FPBASE + FPLSW  ; Compare LS byte of FPACC
    cmp FPBASE + FOPLSW ; with LS byte of FPOP
    bne L1              ; If not equal, return
    lda FPBASE + FPNSW  ; Compare NS byte of FPACC
    cmp FPBASE + FOPNSW ; with NS byte of FPOP
    bne L1              ; If not equal, return
    lda FPBASE + FPMSW  ; Compare MS byte of FPACC
    cmp FPBASE + FOPMSW ; with MS byte of FPOP
    bne L1              ; If not equal, return
    lda FPBASE + FPACCE ; Compare exponent of FPACC
    cmp FPBASE + FOPEXP ; with exponent of FPOP
    bne L1              ; If not equal return
    lda #1              ; They're equal
    rts                 ; Return
L1:
    lda #0              ; They're not equal
    rts                 ; Return
.endproc

; This routine compares the floating point number in FPACC with
; the one in FPOP and returns a non-zero in A if FPACC > FPOP.
.proc floatGt
    jsr floatEq         ; Compare FPACC and FPOP for equality
    bne L1              ; If equal, return
    jsr FPSUB           ; Subtract FPOP from FPACC
    lda FPBASE + FPMSW  ; Look at MS byte of FPACC
    bmi L1              ; FPACC < 0, therefore FPOP > FPACC
    lda #1              ; FPACC is greather than FPOP
    rts                 ; Return
L1:
    lda #0              ; FPACC is not greater than FPOP
    rts                 ; Return
.endproc

; This routine compares the floating point number in FPACC with
; the one in FPOP and returns a non-zero in A if FPACC >= FPOP.
.proc floatGte
    jsr floatEq         ; Compare FPACC and FPOP for equality
    bne L1              ; They're equal return
    jmp floatGt         ; See if FPAPP > FPOP
L1:
    lda #1              ; Load 1 into A
    rts                 ; Return
.endproc

; This routine compares the floating point number in FPACC with
; the one in FPOP and returns a non-zero in A if FPACC < FPOP.
.proc floatLt
    jsr floatEq         ; Compare FPACC and FPOP for equality
    bne L1              ; If equal, return
    jsr FPSUB           ; Subtract FPOP from FPACC
    lda FPBASE + FPMSW  ; Look at MS byte of FPACC
    bpl L1              ; FPACC >= 0, therefore FPACC >= FPOP
    lda #1              ; FPACC is less than FPOP
    rts                 ; Return
L1:
    lda #0              ; FPACC is not less than FPOP
    rts                 ; Return
.endproc

; This routine compares the floating point number in FPACC with
; the one in FPOP and returns a non-zero if FPACC <= FPOP.
.proc floatLte
    jsr floatEq         ; Compare FPACC and FPOP for equality
    bne L1              ; They're equal, return
    jmp floatLt         ; See if FPACC < FPOP
L1:
    lda #1              ; Load 1 into A
    rts                 ; Return
.endproc

