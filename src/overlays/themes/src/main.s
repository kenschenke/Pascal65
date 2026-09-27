;
; main.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Main themes entry point

.export showThemesScreen

.import initScreen, mainloop, initPalette, initThemeList, freeThemeList

.proc showThemesScreen
    ; Initialize the screen
    jsr initPalette
    jsr initThemeList
    jsr initScreen
    
    ; Main loop
    jsr mainloop

    ; Free the themes list
    jsr freeThemeList

    rts
.endproc
