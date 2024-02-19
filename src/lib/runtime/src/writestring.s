.include "cbm_kernal.inc"
.include "runtime.inc"

.export writeString, writeStringLiteral

.import leftpad, writeByte, printz, popeax

; Pointer to string heap in A/X
; Field width in Y
.proc writeString
    sta ptr1
    stx ptr1 + 1
    cpy #0
    beq SK
    tya
    pha
    ldy #0
    lda (ptr1),y
    tax
    pla
    jsr leftpad
SK: ldy #0
    lda (ptr1),y
    tax
    beq DN
LP: iny
    lda (ptr1),y
    sta tmp1
    lda ptr1
    pha
    lda ptr1 + 1
    pha
    txa
    pha
    tya
    pha
    ; jsr $ffd2
    lda tmp1
    jsr writeByte
    pla
    tay
    pla
    tax
    pla
    sta ptr1 + 1
    pla
    sta ptr1
    dex
    bne LP
DN: rts
.endproc

; This routine writes a NULL-terminated string literal.
; Pointer pushed to stack
; Field width in A.
.proc writeStringLiteral
    cmp #0              ; Is field width zero?
    bne :+              ; Branch if not
    jsr popeax
    jmp printz          ; No field width - just print the string
:   sta tmp1            ; Store field
    jsr popeax
    sta ptr1            ; Put the string pointer in ptr1
    stx ptr1 + 1
    pha                 ; Preserve A and X
    txa
    pha
    ldy #0
:   lda (ptr1),y        ; Count the length of the string
    beq :+
    iny
    bne :-
:   tya                 ; Copy the string length
    tax                 ; to X
    lda tmp1            ; Load the field width
    jsr leftpad         ; Pad to the field width
    pla                 ; Pop the string pointer off the stack
    tax
    pla
    jmp printz          ; Print the string
.endproc
