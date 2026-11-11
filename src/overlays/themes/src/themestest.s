;
; themestest.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Hooks for the themes tests (src/apps/themestest). They are only assembled
; in the test build of the overlay (make THEMESTEST=1), which defines
; __THEMESTEST__. The normal themes overlay has none of this.
;
; The test sets a key script with themesTestSetup, then calls themesTestRun,
; which runs the theme screen (showThemesScreen). getKey takes its keys from
; the script instead of the keyboard. The theme screen has no way out but
; F1, so a script must end with it. If the script runs out first,
; themesTestRun returns straight to its caller with the carry set, wherever
; the screen was waiting for a key. The theme list is left allocated; the
; test frees it with freeThemeList.

.ifdef __THEMESTEST__

.export themesTestSetup, themesTestRun, themesTestState, themesTestNextKey

.import showThemesScreen, themeList, numThemes, selectedThemeNum
.import currentTheme

.bss

themesTestSP: .res 1        ; Stack pointer on entry to themesTestRun

.data

; The addresses of the overlay's variables a test looks at
stateTable:
    .addr themeList         ; .dword: the first theme
    .addr numThemes         ; .byte: the number of themes
    .addr selectedThemeNum  ; .byte: the selected theme's number
    .addr currentTheme      ; .dword: the selected theme

.code

; Returns the address of stateTable in A/X
.proc themesTestState
    lda #<stateTable
    ldx #>stateTable
    rts
.endproc

; Returns the next key of the script in A. At the end of the script it
; does not return. It returns from themesTestRun with the carry set.
.proc themesTestNextKey
    lda $ffff               ; The address is set by themesTestSetup
keyAddr = * - 2
    beq DN
    inc keyAddr
    bne :+
    inc keyAddr+1
:   rts

DN: ldx themesTestSP
    txs
    sec
    rts
.endproc

; Sets the key script. A/X points to it: key codes as the keyboard sends
; them, ended by a zero.
.proc themesTestSetup
    sta themesTestNextKey::keyAddr
    stx themesTestNextKey::keyAddr+1
    rts
.endproc

; Runs the theme screen. The carry is clear if it returned (F1) and set if
; the key script ran out.
.proc themesTestRun
    tsx
    stx themesTestSP
    jsr showThemesScreen
    clc
    rts
.endproc

.endif ; __THEMESTEST__
