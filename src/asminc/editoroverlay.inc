
EDITOR_BASE = $4000

editorRun = EDITOR_BASE

; Only in the test build of the overlay (make EDITORTEST=1). See
; editortest.s in the overlay.
editorTestSetup = EDITOR_BASE + 3
editorTestCleanup = EDITOR_BASE + 6
editorTestState = EDITOR_BASE + 9
