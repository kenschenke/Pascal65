;;;
 ; poisonbss.inc
 ; Ken Schenke (kenschenke@gmail.com)
 ;
 ; Fills a program's BSS segment with a poison byte at startup
 ;
 ; Copyright (c) 2026
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

; The emulator starts with RAM zeroed. Real hardware does not, so BSS holds
; whatever was there before: an earlier program, or the last run before a
; reset. Code that reads a BSS variable before writing it works in the
; emulator and fails on hardware. Filling BSS with a non-zero byte makes that
; code fail the same way in both.
;
; poisonBss must be the first thing a program runs, before anything writes to
; BSS. It uses a DMA fill and changes A.
;
; Only a debug build (__DEBUG__, make DEBUG=1) fills BSS. In other builds the
; macro is empty, so shipping code has no fill.

POISON_BYTE = $a5

.macro poisonBss
.ifdef __DEBUG__
    .local skip, joblist
    .import __BSS_RUN__, __BSS_SIZE__

    ; A count of zero would fill 64k
    lda #<__BSS_SIZE__
    ora #>__BSS_SIZE__
    beq skip

    lda #0
    sta $d702                   ; Job list bank
    sta $d704                   ; Job list megabyte
    lda #>joblist
    sta $d701
    lda #<joblist
    sta $d705                   ; Start the enhanced-mode DMA job
    bra skip

joblist:
    .byte $0b                   ; Option: F018B job format
    .byte $00                   ; End of options
    .byte $03                   ; Command: fill
    .word __BSS_SIZE__          ; Count
    .word POISON_BYTE           ; Source: the low byte is the fill value
    .byte $00                   ; Source bank
    .word __BSS_RUN__           ; Destination
    .byte $00                   ; Destination bank
    .byte $00                   ; Sub-command
    .word $0000                 ; Modulo
skip:
.endif
.endmacro
