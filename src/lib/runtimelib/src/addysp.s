.include "runtime.inc"

.export __LOADADDR__: absolute = 1

.segment "JMPTBL"

; exports

jmp addysp

; end of exports
.byte $00, $00, $00

; imports

; end of imports
.byte $00, $00, $00

.segment "LOADADDR"

.addr *+2

.code

.proc addysp
        pha                     ; Save A
        clc
        tya                     ; Get the value
        adc     sp              ; Add low byte
        sta     sp              ; Put it back
        bcc     @L1             ; If no carry, we're done
        inc     sp+1            ; Inc high byte
@L1:    pla                     ; Restore A
        rts
.endproc
