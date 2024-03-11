; Mega65 DMA routines

.include "mega65.inc"
.include "runtime.inc"

.export lfill, lpoke, dma_addr, dma_value, dma_count

; .segment "DMALIST"
; dmalist: .res DMAGIC_DMALIST_SIZE

; .code

; dmalist = $a000

dma_addr: .res 4
dma_value: .res 1
dma_count: .res 2

.proc do_dma
    jsr mega65_io_enable

    lda #0
    sta $d702
    sta $d704
    lda #>dmalist
    sta $d701
    lda #<dmalist
    sta $d705
    rts
.endproc

.proc ror20
    ldx #19
:   lsr tmp4
    ror tmp3
    ror tmp2
    ror tmp1
    dex
    bpl :-
    rts
.endproc

.proc lfill
    ; Copy dma_addr to tmp1-tmp4
    ldx #3
:   lda dma_addr,x
    sta tmp1,x
    dex
    bpl :-
    jsr ror20

    lda #$0b
    sta dmalist + DMAGIC_DMALIST::option_0b
    lda #$80
    sta dmalist + DMAGIC_DMALIST::option_80
    lda #0
    sta dmalist + DMAGIC_DMALIST::source_mb
    sta dmalist + DMAGIC_DMALIST::sub_cmd
    sta dmalist + DMAGIC_DMALIST::end_of_options
    sta dmalist + DMAGIC_DMALIST::source_addr + 1
    lda #$81
    sta dmalist + DMAGIC_DMALIST::option_81
    lda #3      ; fill
    sta dmalist + DMAGIC_DMALIST::command
    lda #1
    sta dmalist + DMAGIC_DMALIST::dest_skip
    lda #$85
    sta dmalist + DMAGIC_DMALIST::option_85
    lda dma_count
    sta dmalist + DMAGIC_DMALIST::count
    lda dma_count + 1
    sta dmalist + DMAGIC_DMALIST::count + 1
    lda dma_value
    sta dmalist + DMAGIC_DMALIST::source_addr
    lda tmp1
    sta dmalist + DMAGIC_DMALIST::dest_mb
    lda dma_addr
    sta dmalist + DMAGIC_DMALIST::dest_addr
    lda dma_addr + 1
    sta dmalist + DMAGIC_DMALIST::dest_addr + 1
    lda dma_addr + 2
    and #$0f
    sta dmalist + DMAGIC_DMALIST::dest_bank

    jmp do_dma
.endproc

; Address in dma_addr
; Value in dma_value
.proc lpoke
    ; Copy dma_addr to tmp1-tmp4
    ldx #3
:   lda dma_addr,x
    sta tmp1,x
    dex
    bpl :-
    jsr ror20

    lda #$0b
    sta dmalist + DMAGIC_DMALIST::option_0b
    lda #$80
    sta dmalist + DMAGIC_DMALIST::option_80
    lda #0
    sta dmalist + DMAGIC_DMALIST::source_mb
    sta dmalist + DMAGIC_DMALIST::end_of_options
    sta dmalist + DMAGIC_DMALIST::sub_cmd
    sta dmalist + DMAGIC_DMALIST::command
    sta dmalist + DMAGIC_DMALIST::source_bank
    sta dmalist + DMAGIC_DMALIST::count + 1
    lda #$81
    sta dmalist + DMAGIC_DMALIST::option_81
    lda tmp1
    sta dmalist + DMAGIC_DMALIST::dest_mb
    lda #$85
    sta dmalist + DMAGIC_DMALIST::option_85
    lda #1
    sta dmalist + DMAGIC_DMALIST::dest_skip
    sta dmalist + DMAGIC_DMALIST::count
    lda dma_value
    sta tmp1
    lda #<tmp1
    sta dmalist + DMAGIC_DMALIST::source_addr
    lda #0
    sta dmalist + DMAGIC_DMALIST::source_addr + 1
    lda dma_addr
    sta dmalist + DMAGIC_DMALIST::dest_addr
    lda dma_addr + 1
    sta dmalist + DMAGIC_DMALIST::dest_addr + 1
    lda dma_addr + 2
    and #$0f
    sta dmalist + DMAGIC_DMALIST::dest_bank

    jmp do_dma
.endproc

.proc mega65_io_enable
    lda $d05d
    ora #$80
    sta $d05d

    ; Gate C65 IO enable
    lda #$47
    sta $d02f
    lda #$53
    sta $d02f
    ; Force to full speed
    lda #65
    sta $0
    rts
.endproc
