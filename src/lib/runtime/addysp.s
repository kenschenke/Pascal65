.export addysp
.importzp sp

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
