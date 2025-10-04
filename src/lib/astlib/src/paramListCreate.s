.include "zeropage.inc"
.include "ast.inc"
.include "asmlib.inc"
.include "4510macros.inc"

.export paramListCreate

.import nameCreate

; This routine creates a param_list structure
;
; Inputs - pointer to name in A/X (bank 0)
.proc paramListCreate
    pha
    phx

    ; Allocate the structure
    lda #.sizeof(param_list)
    ldx #0
    jsr heapAlloc
    stq ptr1

    ; Zero out the param_list structure
    lda #0
    ldz #.sizeof(param_list)-1
:   nop
    sta (ptr1),z
    dez
    bpl :-

    ; Set up the name
    ldq ptr1
    jsr pushQ
    plx
    pla
    jsr nameCreate
    stq ptr2
    jsr popQ
    stq ptr1
    ldz #param_list::name+3
    ldx #3
:   lda ptr2,x
    nop
    sta (ptr1),z
    dez
    dex
    bpl :-

    ldq ptr1
    rts
.endproc
