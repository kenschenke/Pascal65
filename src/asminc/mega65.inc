; Mega65 DMA command

DMAGIC_DMALIST_SIZE = 20
dmalist = $2014

.struct DMAGIC_DMALIST
    ; Enhanced DMA options
    option_0b       .byte
    option_80       .byte
    source_mb       .byte
    option_81       .byte
    dest_mb         .byte
    option_85       .byte
    dest_skip       .byte
    end_of_options  .byte

    ; F018B format DMA request
    command         .byte
    count           .word
    source_addr     .word
    source_bank     .byte
    dest_addr       .word
    dest_bank       .byte
    sub_cmd         .byte
    modulo          .word
.endstruct
