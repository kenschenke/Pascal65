;
; writeRuntimeBss.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; writeRuntimeBss routine

.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"

ZPBACKUP_LEN = 97
ZPINTBUF_LEN = 15
TENSTABLE_LEN = 40
INPUTBUF_LEN = 80

.export writeRuntimeBss

.import tagBSS_ZPBACKUP, tagBSS_TENSTABLE, tagBSS_INPUTBUF, tagBSS_INTBUF
.import tagBSS_HEAPBOTTOM
.import incCodeOffset

; Write pieces of the BSS segment needed by the runtime.
.proc writeRuntimeBss
    ldx #1
    jsr CHKOUT

    ; Set aside some memory for the integer buffer
    lda #<tagBSS_INTBUF
    ldx #>tagBSS_INTBUF
    jsr linkAddressSet
    ldx #ZPINTBUF_LEN
    lda #0
:   jsr CHROUT
    dex
    bne :-
    lda #ZPINTBUF_LEN
    jsr incCodeOffset
    
    ; Set aside some memory to undo the changes to page zero
    lda #<tagBSS_ZPBACKUP
    ldx #>tagBSS_ZPBACKUP
    jsr linkAddressSet

    ldx #ZPBACKUP_LEN
    lda #0
:   jsr CHROUT
    dex
    bne :-
    lda #ZPBACKUP_LEN
    jsr incCodeOffset

    ; Set aside memory for the integer/ascii table
    lda #<tagBSS_TENSTABLE
    ldx #>tagBSS_TENSTABLE
    jsr linkAddressSet
    ldx #TENSTABLE_LEN
    lda #0
:   jsr CHROUT
    dex
    bne :-
    lda #TENSTABLE_LEN
    jsr incCodeOffset

    ; Set aside memory for the input buffer
    lda #<tagBSS_INPUTBUF
    ldx #>tagBSS_INPUTBUF
    jsr linkAddressSet
    ldx #INPUTBUF_LEN
    lda #0
:   jsr CHROUT
    dex
    bne :-
    lda #INPUTBUF_LEN
    jsr incCodeOffset

    ; This MUST be the last thing written to the code buffer
    lda #<tagBSS_HEAPBOTTOM
    ldx #>tagBSS_HEAPBOTTOM
    jsr linkAddressSet
    lda #0
    jsr CHROUT
    jsr CHROUT
    lda #2
    jsr incCodeOffset

    rts
.endproc
