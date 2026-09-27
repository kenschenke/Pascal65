;
; jmptbl.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; themes entry points

.segment "JMPTBL"

.import showThemesScreen, loadDefaultTheme

jmp showThemesScreen
jmp loadDefaultTheme
