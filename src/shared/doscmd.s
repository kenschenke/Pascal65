;;;
 ; blocks.s
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; Sending DOS commands.
 ; 
 ; Copyright (c) 2022
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "cbm_kernal.inc"

; Send a DOS command

.export _sendDosCmd
.import popax, _strlen
.importzp ptr1, tmp1

; void sendDosCmd(char *cmd, char device);
;    cmd would be something like "s0:filename" or "r0:oldname=0:newname"

.proc _sendDosCmd
    sta tmp1        ; device number
    jsr popax       ; get cmd
    sta ptr1        ; low byte of cmd
    stx ptr1+1      ; high byte of cmd
    lda #1          ; logical file number
    ldx tmp1        ; device number for disk drive
    ldy #15         ; command channel 15
    jsr SETLFS      ; prepare to open it
    lda ptr1        ; low byte of cmd
    ldx ptr1+1      ; high byte of cmd
    jsr _strlen     ; length of cmd returned in .A
    ldx ptr1        ; .X and .Y hold
    ldy ptr1+1      ; address of the cmd
    jsr SETNAM      ; set name
    jsr OPEN        ; open it
    lda #1          ; and immediately
    jsr CLOSE       ; close the command channel
    jsr CLRCHN      ; clear the channels
    rts             ; all done
.endproc
