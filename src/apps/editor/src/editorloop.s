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

.include "asmlib.inc"
.include "editor.inc"
.include "themes.inc"
.include "editoroverlay.inc"

.export editorLoop

.import initEditor, initThemes, runCompiler

.ifdef __DEBUG__
.import editorDebug
.endif

.bss

themeColors: .res 10

.code

.proc editorLoop
    ; Load the default theme's colors into the buffer
    jsr initThemes
    lda #<themeColors
    ldx #>themeColors
    jsr loadDefaultTheme

L1: jsr initEditor      ; load the editor overlay from disk
    lda #<themeColors
    ldx #>themeColors
    jsr editorRun
    cmp #EDITOR_LOOP_QUIT
    beq QT
    cmp #EDITOR_LOOP_COMPILE
    beq CP
.ifdef __DEBUG__
    cmp #EDITOR_LOOP_DEBUG
    beq DB
.endif
    cmp #EDITOR_LOOP_THEME
    beq TH
    cmp #EDITOR_LOOP_RUN
    bne L1

    ; Run
    jsr runCompiler
    sec
    rts

.ifdef __DEBUG__
    ; Debug
DB: jsr editorDebug
    bra L1
.endif

    ; Compile
CP: jsr runCompiler
    jsr clearMemHeap
    bra L1

    ; Themes
TH: jsr initThemes
    jsr showThemesScreen
    lda #<themeColors
    ldx #>themeColors
    jsr loadDefaultTheme
    bra L1

QT: clc
    rts
.endproc
