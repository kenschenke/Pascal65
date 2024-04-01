;
; int16c.s
; Ken Schenke (kenschenke@gmail.com)
; 
; 16-bit integer C/asm glue code
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; C / ASM glue code for int16

.export _formatInt16, _formatUint16, _leftPad, _printInt16, _setIntBuf

.importzp intPtr
.import intOp1, writeInt16, writeUint16, _printz, popa, leftpad

; const char *formatInt16(int num)
.proc _formatInt16
    sta intOp1
    stx intOp1 + 1
    lda #0
    jsr writeInt16
    lda intPtr
    ldx intPtr + 1
    rts
.endproc

; const char *formatUint16(unsigned int num)
.proc _formatUint16
    sta intOp1
    stx intOp1 + 1
    lda #0
    jsr writeUint16
    lda intPtr
    ldx intPtr + 1
    rts
.endproc

; void leftPad(char fieldWidth, char valueWidth)
.proc _leftPad
    tax
    jsr popa
    jmp leftpad
.endproc

; void printInt16(int num)
.proc _printInt16
    sta intOp1
    stx intOp1 + 1
    jsr writeInt16
    lda intPtr
    ldx intPtr + 1
    jmp _printz
.endproc

; void setIntBuf(char *buffer);
.proc _setIntBuf
    sta intPtr
    stx intPtr + 1
    rts
.endproc
