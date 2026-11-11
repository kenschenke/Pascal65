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

; Only in the test build (make THEMESTEST=1). See themestest.s and
; themes.inc.
.ifdef __THEMESTEST__
.import themesTestSetup, themesTestRun, themesTestState, initThemeList
.import readThemeFile, writeThemeFile, resetToDefaults, freeThemeList
.import isColorUsedInTheme, resetSystemPalette
jmp themesTestSetup
jmp themesTestRun
jmp themesTestState
jmp initThemeList
jmp readThemeFile
jmp writeThemeFile
jmp resetToDefaults
jmp freeThemeList
jmp isColorUsedInTheme
jmp resetSystemPalette
.endif
