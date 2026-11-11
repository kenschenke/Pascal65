
THEMES_BASE = $4000

showThemesScreen = THEMES_BASE + 0
loadDefaultTheme = THEMES_BASE + 3

; Only in the test build of the overlay (make THEMESTEST=1). See
; themestest.s in the overlay.
themesTestSetup = THEMES_BASE + 6           ; A/X: the key script
themesTestRun = THEMES_BASE + 9             ; C set if the keys ran out
themesTestState = THEMES_BASE + 12          ; A/X: the state table
themesInitThemeList = THEMES_BASE + 15
themesReadThemeFile = THEMES_BASE + 18
themesWriteThemeFile = THEMES_BASE + 21
themesResetToDefaults = THEMES_BASE + 24
themesFreeThemeList = THEMES_BASE + 27
themesIsColorUsed = THEMES_BASE + 30        ; ptr1: theme, A: color
themesResetPalette = THEMES_BASE + 33
