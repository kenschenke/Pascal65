;;;
 ; mega65.inc
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; MEGA65 DMA definitions and constants
 ; 
 ; Copyright (c) 2024
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

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
