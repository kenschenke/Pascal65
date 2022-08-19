;;;
 ; doscmd.s
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
    ; Store parameters

    sta tmp1        ; device number
    jsr popax       ; get cmd
    sta ptr1        ; low byte of cmd
    stx ptr1+1      ; high byte of cmd

    ; Call SETLFS

    lda #1          ; logical file number
    ldx tmp1        ; device number for disk drive
    ldy #15         ; command channel 15
    jsr SETLFS      ; prepare to open it

    ; Calculate length of command string

    ldy #0
@Loop:
    lda (ptr1),y
    beq @DoneLoop
    iny
    jmp @Loop
@DoneLoop:
    tya             ; length of command in .A

    ; Call SETNAM

    ldx ptr1        ; low byte of command in .X
    ldy ptr1+1      ; high byte in .Y
    jsr SETNAM      ; set name

    ; Call OPEN

    jsr OPEN        ; open it

    ; and immediately call CLOSE

    lda #1          ; and immediately
    jsr CLOSE       ; close the command channel
    jsr CLRCHN      ; clear the channels
    rts             ; all done
.endproc
