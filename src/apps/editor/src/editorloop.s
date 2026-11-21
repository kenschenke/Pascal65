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
.include "workdisk.inc"

.export editorLoop

.import initEditor, initThemes, runCompiler, buildResult
.import initWorkdisk, initBuildResult

.ifdef __DEBUG__
.import editorDebug
.endif

.bss

; The theme colors and the build result, for editorRun
ctx: .tag EDITORCTX

.code

.proc editorLoop
    lda #<buildResult
    sta ctx+EDITORCTX::buildResult
    lda #>buildResult
    sta ctx+EDITORCTX::buildResult+1

    ; Load the default theme's colors into the buffer
    jsr initThemes
    lda #<(ctx+EDITORCTX::themeColors)
    ldx #>(ctx+EDITORCTX::themeColors)
    jsr loadDefaultTheme

L1: jsr initEditor      ; load the editor overlay from disk
    lda #<ctx
    ldx #>ctx
    jsr editorRun
    cmp #EDITOR_LOOP_QUIT
    beq QT
    cmp #EDITOR_LOOP_COMPILE
    beq CP
    cmp #EDITOR_LOOP_REBUILD
    beq CP
.ifdef __DEBUG__
    cmp #EDITOR_LOOP_DEBUG
    beq DB
.endif
    cmp #EDITOR_LOOP_THEME
    beq TH
    cmp #EDITOR_LOOP_WORKDISK
    beq WD
    cmp #EDITOR_LOOP_RUN
    bne L1

    ; Run, unless the compile failed or compiled a unit, which has no
    ; program to run. Then go back to the editor like Compile does.
    jsr runCompiler
    bcc CP2
    rts

.ifdef __DEBUG__
    ; Debug
DB: jsr editorDebug
    bra L1
.endif

    ; Compile
CP: jsr runCompiler
CP2:
    jsr clearMemHeap
    bra L1

    ; Themes
TH: jsr initThemes
    jsr showThemesScreen
    lda #<(ctx+EDITORCTX::themeColors)
    ldx #>(ctx+EDITORCTX::themeColors)
    jsr loadDefaultTheme
    bra L1

    ; The work disk dialog. The last build was on the old disk.
WD: jsr initWorkdisk
    jsr wdDialog
    jsr initBuildResult
    bra L1

QT: clc
    rts
.endproc
