; This bit of code is used by the IDE and compiler for loading
; and transferring control to another program.  The IDE uses it
; to launch the compiler and the compiler uses it to launch
; the IDE.
;
; The code expects A/X to contain a pointer to the PRG filename.

.include "cbm_kernal.inc"
.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "LOADADDR"

.addr *+2

.code

    sta ptr1        ; store the filename in ptr1
    stx ptr1 + 1
    lda #0
    ldx $ba         ; current device number
    ldy #$ff
    jsr SETLFS
    ldy #0          ; Copy the filename to our own memory
    ldx #0          ; since the caller's filename will probably
:   lda (ptr1),y    ; get overwritten when the new PRG is loaded.
    sta filename,x
    beq :+
    inx
    iny
    bne :-
:   tya             ; filename length
    ldx #<filename
    ldy #>filename
    jsr SETNAM
    lda #0
    tax
    tay
    jsr LOAD
.ifdef __MEGA65__
    jmp $2011
.else
    jmp $80d
.endif

filename: .res 16
