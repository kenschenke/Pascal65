;
; editorloop.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Editor loop

.include "editor.inc"
.include "editoroverlay.inc"

.export editorLoop

.import initEditor, runCompiler

.proc editorLoop
L1: jsr initEditor      ; load the editor overlay from disk
    jsr editorRun
    cmp #EDITOR_LOOP_QUIT
    beq QT
    cmp #EDITOR_LOOP_COMPILE
    beq CP
    cmp #EDITOR_LOOP_RUN
    bne L1

    ; Run
    jsr runCompiler
    sec
    rts

    ; Compile
CP: jsr runCompiler
    bra L1

QT: clc
    rts
.endproc
