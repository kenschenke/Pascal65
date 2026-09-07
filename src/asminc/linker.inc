LINKER_BASE = $4000

genPrgFile = LINKER_BASE

; These constants define how a linker tag reference is to be resolved.
; At the offset, the code needs to know the low byte, the high byte,
; or both.
LINKADDR_LOW = 1
LINKADDR_HIGH = 2
LINKADDR_BOTH = 3

; This structure defines a location that needs to be resolved by the linker.
; The label is the location being referenced. The offset is the location
; of the reference in the object code.
.struct TAGTOFIND
    label .res 24           ; Null-terminated label
    type .byte             ; One of LINKADDR_*
    offset .word            ; offset of reference in generated code
.endstruct

; This structure defines a location that needs to be updated by the linker.
; The type is on of LINKADDR_*, the offset is the offset in the object file.
; The address is a the 16-bit address to update.
.struct TAGTOFIX
    type .byte
    offset .word
    address .word
.endstruct
