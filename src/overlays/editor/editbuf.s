;
; editbuf.s
; Ken Schenke (kenschenke@gmail.com)
;
; Routines to manage the editor buffer
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;

.include "chunks.inc"
.include "editor.inc"

.export _editBuf, _editBufInsertChar, _editBufDeleteChars
.export _editBufFlush, _editBufPopulate

.import popa, _getChunk, _allocChunk, pushax, popax
.import _freeChunk, _retrieveChunk, _storeChunk
.importzp tmp1, ptr1

.bss

_editBuf: .res 80
echunk: .res CHUNK_LEN
chunkNum: .res 2
chunkNumPtr: .res 2
tmpX: .res 1
tmpL: .res 1

.code

; This routine inserts a character into the edit buffer.
; It destroys tmp1
; void editBufInsertChar(char ch, char lineLength, char pos)
.proc _editBufInsertChar
    sta tmp1            ; Store position in tmp1
    jsr popa            ; Pop line length off the stack
    pha                 ; Store the line length on CPU stack
    sec                 ; Set carry for subtraction
    sbc tmp1            ; line length - position
    beq L2              ; branch if length == position
    bmi L4              ; branch if position > length
    tax                 ; put it in X
    pla                 ; Pop line length back off CPU stack
    tay                 ; Put length in Y
    dey                 ; Decrement since Y is a zero-based index
L1:
    lda _editBuf,y      ; grab the current character
    iny                 ; increment index
    sta _editBuf,y      ; store the character in the next slot
    dey                 ; go back to current slot
    dey                 ; go back to previous slot
    dex                 ; decrement counter
    bne L1              ; branch if more chars to copy
    jmp L3
L2:
    pla                 ; pull the line length back off the CPU stack
                        ; since the char is being appended to the end
                        ; of the line and the code to copy chars was skipped
L3:
    jsr popa            ; pull new character off stack
    ldy tmp1            ; load the position into Y
    sta _editBuf,y      ; store it in the new position
    rts
L4:
    pla                 ; position was > line length
                        ; pull the line length back off the CPU stack
                        ; since the code to copy chars was skipped
    jmp popa            ; clear up the remaining item on the stack
.endproc

; This routine deletes one or more characters from the edit buffer.
; It does nothing to the characters still in the buffer past the
; end of the shortened length.
; It destroys tmp1
; void editBufDeleteChars(char pos, char numToDelete, char lineLength)
.proc _editBufDeleteChars
    pha                 ; push lineLength onto CPU stack for safekeeping
    jsr popa            ; pop numToDelete off stack
    sta tmp1            ; store in tmp1
    jsr popa            ; pop pos off stack
    tay                 ; put pos in Y (destination index for copy)
    clc                 ; clear carry for addition
    adc tmp1            ; pos + numToDelete (source index for copy)
    sta tmp1            ; store source index in tmp1
    tax                 ; put source index in X
    pla                 ; pop lineLength back off CPU stack
    sec                 ; set carry for subtraction
    sbc tmp1            ; lineLength - source index
    beq L2              ; if no bytes to copy, skip ahead
    sta tmp1            ; tmp1 becomes number of bytes to copy
L1:
    lda _editBuf,x      ; read char from source index
    sta _editBuf,y      ; store char to source index
    inx                 ; increment both indexes
    iny
    dec tmp1            ; decrement byte count
    bne L1              ; branch if more bytes still to copy
L2:
    rts
.endproc

; This routine copies characters from the caller-supplied buffer
; to the edit buffer at a position.
; void editBufCopyChars(char pos, char charsToCopy, char *buffer)
; It destroys tmp1 and ptr1
.proc _editBufCopyChars
    sta ptr1            ; source buffer pointer in ptr1
    stx ptr1 + 1
    jsr popa            ; pop charsToCopy off stack
    sta tmp1            ; number of characters to copy in tmp1
    jsr popa            ; pop position off stack
    tax                 ; position in X
    ldy #0              ; index in source buffer
L1:
    lda (ptr1),y        ; load char from source buffer
    sta _editBuf,x      ; store it edit buffer
    inx                 ; increment edit buffer index
    iny                 ; increment source buffer index
    dec tmp1            ; decrement number of chars to copy
    bne L1              ; branch if chars still left to copy
    rts
.endproc

; This routine populates the edit buffer from the row chunks
; void editBufPopulate(CHUNKNUM chunkNum)
.proc _editBufPopulate
    sta chunkNum
    stx chunkNum + 1
    lda #0
    sta tmpX            ; Number of chars copied into buffer
L1:
    lda chunkNum        ; Is the chunkNum 0?
    ora chunkNum + 1
    beq L4              ; Branch if zero
    lda chunkNum
    ldx chunkNum + 1
    jsr _getChunk       ; Get a pointer to the chunk
    sta ptr1
    stx ptr1 + 1        ; Is the pointer zero?
    ora ptr1 + 1
    beq L4              ; Branch if zero
    ldy #2              ; Offset 2 into chunk
    lda (ptr1),y        ; Number of used chars in chunk
    beq L3              ; If chars is zero, branch
    sta tmp1            ; Number of chars in tmp1
    iny                 ; Start at first char
    ldx tmpX            ; X is index into editBuf
L2:
    lda (ptr1),y        ; Load a char into A
    sta _editBuf,x      ; Store that char in the edit buffer
    iny                 ; Next index in chunk
    inx                 ; Next index in editBuf
    dec tmp1            ; Decrement char counter
    bne L2              ; Branch if more chars left to copy
    stx tmpX            ; Save edit buffer index
L3:
    ; Go to the next chunk
    ldy #0
    lda (ptr1),y        ; Load the next next chunk number
    sta chunkNum
    iny
    lda (ptr1),y
    sta chunkNum + 1
    jmp L1              ; Loop back around
L4:
    rts
.endproc

; This routine saves the edit buffer back to the row chunks.
; It allocates and frees row chunks as necessary.
; void editBufFlush(CHUNKNUM *firstChunkNum, char lineLength)
.proc _editBufFlush
    sta tmpL                ; Save lineLength
    lda #0
    sta tmpX                ; Clear tmpX (index into _editBuf)
    jsr popax               ; Pop *chunkNum off call stack
    sta chunkNumPtr         ; Save it in chunkNumPtr
    sta ptr1                ; and ptr1
    stx chunkNumPtr + 1
    stx ptr1 + 1
    ldy #0
    lda (ptr1),y
    sta chunkNum            ; set the first row chunk in chunkNum
    iny
    lda (ptr1),y
    sta chunkNum + 1
    lda tmpL                ; Look at lineLength
    bne L1                  ; Branch if it's non-zero
    ; lineLength is zero
    ldy #0
    lda (ptr1),y            ; Look if first chunkNum is also zero
    iny
    ora (ptr1),y
    bne L0                  ; branch if chunkNumPtr points to a zero value
    jmp L12                 ; bail out
L0:
    ; All row chunks need to be freed
    ldy #0                  ; lineLength is zero but row chunks still exist
    lda (ptr1),y
    sta chunkNum
    iny
    lda (ptr1),y
    sta chunkNum + 1
    ; Clear first chunk num pointer
    lda #0
    sta (ptr1),y
    dey
    sta (ptr1),y
    jmp L10                 ; Free all row chunks
L1:
    ; Does chunkNumPtr point to a zero value?
    lda chunkNumPtr
    sta ptr1
    lda chunkNumPtr + 1
    sta ptr1 + 1
    ldy #0
    lda (ptr1),y
    iny
    ora (ptr1),y
    bne L3                  ; Branch if it's non-zero
    lda chunkNumPtr
    ldx chunkNumPtr + 1
    jsr _allocChunk         ; Allocate a chunk
    cmp #0
    bne L2                  ; _allocChunk failed
    jmp L12
L2:
    lda chunkNumPtr         ; Store the chunkNumPtr in ptr1
    sta ptr1
    lda chunkNumPtr + 1
    sta ptr1 + 1
    ldy #0
    lda (ptr1),y
    sta chunkNum            ; Store the chunkNum
    iny
    lda (ptr1),y
    sta chunkNum + 1
L3:
    lda chunkNum
    ldx chunkNum + 1
    jsr pushax
    lda #<echunk
    ldx #>echunk
    jsr _retrieveChunk
    cmp #0
    bne L4
    jmp L12
L4:
    lda #<echunk
    sta ptr1
    lda #>echunk
    sta ptr1 + 1
    ; toCopy = tmpL < ECHUNK_LEN ? tmpL : ECHUNK_LEN
    lda tmpL                ; number of chars left in line
    cmp #ECHUNK_LEN         ; is it >= ECHUNK_LEN?
    bcc L5                  ; branch if no (copy just tmpL)
    lda #ECHUNK_LEN         ; no - copy ECHUNK_LEN
L5:
    sta tmp1                ; number of chars to copy in tmp1
    ldy #2                  ; offset 2 into echunk
    sta (ptr1),y            ; store number of chars in chunk
    iny                     ; offset to first char in chunk
    ldx tmpX                ; offset into _editBuf
L6:
    ; X - index into _editBuf
    ; Y - index into echunk
    ; tmp1 - # of chars to copy in this loop
    lda _editBuf,x
    sta (ptr1),y
    inx
    iny
    dec tmpL
    dec tmp1
    bne L6
    stx tmpX
    ; If the echunk's nextChunk is zero and there are still chars
    ; to copy, allocate another chunk.
    lda tmpL
    beq L7
    ldy #0
    lda (ptr1),y
    iny
    ora (ptr1),y
    bne L7
    lda ptr1
    ldx ptr1 + 1
    jsr _allocChunk
    cmp #0
    bne L7
    jmp L12
L7:
    ; Store the current chunk
    ; If no more chars left to copy, zero out next chunk
    lda tmpL
    bne L8
    ldy #1
    lda #<echunk
    sta ptr1
    lda #>echunk
    sta ptr1 + 1
    lda (ptr1),y
    pha
    dey
    lda (ptr1),y
    pha
    lda #0
    sta (ptr1),y
    iny
    sta (ptr1),y
L8:
    lda chunkNum
    ldx chunkNum + 1
    jsr pushax
    lda #<echunk
    ldx #>echunk
    jsr _storeChunk
    cmp #0
    beq L12
    lda #<echunk
    sta ptr1
    lda #>echunk
    sta ptr1 + 1
    ldy #0
    lda (ptr1),y
    sta chunkNum
    iny
    lda (ptr1),y
    sta chunkNum + 1
    lda tmpL
    beq L9
    jmp L3
L9:
    pla
    sta chunkNum + 1
    pla
    sta chunkNum
L10:
    ; Free all remaining row chunks
    lda chunkNum
    ora chunkNum + 1
    beq L12
    lda chunkNum
    ldx chunkNum
    jsr pushax
    lda #<echunk
    ldx #>echunk
    jsr _retrieveChunk
    cmp #0
    beq L12
    lda chunkNum
    ldx chunkNum + 1
    jsr _freeChunk
    lda #<echunk
    sta ptr1
    lda #>echunk
    sta ptr1 + 1
    ldy #0
    lda (ptr1),y
    sta chunkNum
    iny
    lda (ptr1),y
    sta chunkNum + 1
    jmp L10
L12:
    rts
.endproc
