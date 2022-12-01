.include "cbm_kernal.inc"
.include "c64.inc"

.importzp ptr1, tmp1
.export getline, _getlineUsed, _getlineBuf

CH_STOP = 3
CH_DEL = 20
CH_ENTER = 13

MAX_CHARS = 80

.bss

_getlineBuf: .res MAX_CHARS
_getlineUsed: .res 1

.code

; tmp1 - number of characters typed
.proc getline
    ; set up the buffer pointer
    lda #<_getlineBuf
    sta ptr1
    lda #>_getlineBuf
    sta ptr1 + 1
    ; turn the cursor on
    lda #0
    sta CURS_FLAG
    ; clear tmp1
    sta tmp1
Loop:
    jsr STOP
    beq StopKey
    jsr GETIN
    cmp #CH_ENTER
    beq EnterKey
    cmp #CH_DEL
    beq DeleteKey
    ; Is the character less than 32?
    cmp #32
    bcc Loop        ; Yes - ignore it
    ; Is the character > 160?
    cmp #160
    bcs Keep        ; Yes - keep it
    ; Is the character > 127?
    cmp #127
    bcs Loop        ; Yes - ignore it
Keep:
    ; Has the user already typed the maximum allowed characters?
    ldx tmp1
    cpx #MAX_CHARS
    beq Loop        ; Yes - ignore the key
    jsr CHROUT
    ldy tmp1
    sta (ptr1),y
    inc tmp1
    jmp Loop
DeleteKey:
    ; Delete
    ldx tmp1
    beq Loop        ; Already at start of buffer
    jsr CHROUT
    dec tmp1
    jmp Loop

StopKey:
    ; User hit STOP key
    lda #1
    sta CURS_FLAG
    rts

EnterKey:
    ; User pressed Enter
    lda #1
    sta CURS_FLAG
    lda #' '
    jsr CHROUT
    lda #CH_ENTER
    jsr CHROUT
    lda #0
    ldx tmp1
    stx _getlineUsed
    rts
.endproc
