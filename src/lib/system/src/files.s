; File handling

.include "runtime.inc"
.include "cbm_kernal.inc"

.export fileAssign, fileClose, fileReset, fileRewrite, fileEOF, fileIOResult
.export fileErase, fileRename

.proc fileAssign
    lda #0
    jsr rtSetIOResult           ; Clear IOResult
    lda #1
    jsr getParamVal             ; Get the pointer to the filename string
    sta ptr2
    stx ptr2 + 1
    lda #0
    jsr getParamVal             ; Get the pointer to the file handle
    jmp rtFileAssign
.endproc

; This handles the Pascal Close procedure
.proc fileClose
    lda #0
    jsr rtSetIOResult           ; Clear IOResult
    lda #0
    jsr getParamVal             ; Retrieve the file handle
    jmp rtFileClose
.endproc

; This handles the Pascal EOF function
.proc fileEOF
    lda #0
    jsr getParamVal             ; Retrieve the file handle
    sta ptr1                    ; Store the pointer to it in ptr1
    stx ptr1 + 1
    ldy #2                      ; Load the file number
    lda (ptr1),y
    jsr rtEOF
    ldx #0
    stx sreg
    stx sreg + 1
    jmp rtLibReturnValue
.endproc

; This handles the Pascal Erase procedure
.proc fileErase
    lda #0
    jsr rtSetIOResult           ; Clear IOResult
    lda #0
    jsr getParamVal             ; Retrieve the file handle
    jmp rtFileErase
.endproc

; This handles the IOResult Pascal function
.proc fileIOResult
    jsr rtGetIOResult
    ldx #0
    stx sreg
    stx sreg + 1
    jmp rtLibReturnValue
.endproc

; This handles the Pascal Rename procedure
.proc fileRename
    lda #0
    jsr rtSetIOResult           ; Clear IOResult
    lda #1
    jsr getParamVal
    sta ptr2
    stx ptr2 + 1
    lda #0
    jsr getParamVal
    sta ptr1
    stx ptr1 + 1
    jmp rtFileRename
.endproc

; This handles the Pascal Reset procedure
.proc fileReset
    lda #0
    jsr rtSetIOResult           ; Clear IOResult
    lda #0
    jsr getParamVal             ; Retrieve the file handle
    ldy #1
    jmp rtFileOpen
.endproc

; This handles the Pascal Rewrite procedure
.proc fileRewrite
    lda #0
    jsr rtSetIOResult           ; Clear IOResult
    lda #0
    jsr getParamVal             ; Retrieve the file handle
    ldy #0
    jmp rtFileOpen
.endproc

; This helper routine returns the value of a parameter.
; Parameter number in A
; Value returned in A/X
.proc getParamVal
    jsr rtLibLoadParam
    ldy #1
    lda (ptr1),y
    tax
    dey
    lda (ptr1),y
    rts
.endproc
