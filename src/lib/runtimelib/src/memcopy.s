; Copy variable from ptr2 to ptr1
;
; memcopy and memcpyP both copy one or more bytes from
; the address in ptr2 to the address in ptr1.
;
; memcopy can copy more than 255 bytes by receiving the
; number to copy in A/X.
;
; memcpyP copies 1-255 bytes by receiving the number
; to copy in A.
;
; memcpyPStack uses the top two bytes of the stack
; as the source address.

.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp memcopy

; end of exports
.byte $00, $00, $00

; imports

popeax: jmp $0000

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

; Destination address in ptr1
; Source address in ptr2
; Size in A/X
memcopy:
    sta tmp1
    ldy #0
    cpx #0
    beq L2
L1:
    ; Copy one page
    lda (ptr2),y
    sta (ptr1),y
    iny
    bne L1
    inc ptr1 + 1
    inc ptr2 + 1
    dex
    bne L1
    beq L2
memcpyPStack:
    pha
    jsr popeax
    sta ptr2
    stx ptr2 + 1
    ; Add 4 to ptr2
    ; clc
    ; lda ptr2
    ; adc #4
    ; sta ptr2
    ; lda ptr2 + 1
    ; adc #0
    ; sta ptr2 + 1
    pla
memcpyP:
    sta tmp1
    ldy #0
L2:
    ; Copy remaining bytes
    ldx tmp1
    beq L4
L3:
    lda (ptr2),y
    sta (ptr1),y
    iny
    dex
    bne L3
L4:
    rts
