;
; jmptbl.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; parser entry points

; .import handleParse, setUnitsList, getUnitsList, getRuntimeStackSize

.segment "JMPTBL"

.import editorRun

jmp editorRun

; The editor tests' hooks (editortest.s), in the test build only
.ifdef __EDITORTEST__
.import editorTestSetup, editorTestCleanup, editorTestState
jmp editorTestSetup
jmp editorTestCleanup
jmp editorTestState
.endif
