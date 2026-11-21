;
; jmptbl.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; workdisk entry points (workdisk.inc)

.segment "JMPTBL"

.import wdCheck, wdCreate, wdRefresh, wdDialog, wdStartup, wdUse

jmp wdCheck
jmp wdCreate
jmp wdRefresh
jmp wdDialog
jmp wdStartup
jmp wdUse

.ifdef __WORKDISKTEST__
.import wdTestSetup, wdTestRun, wdTestState
jmp wdTestSetup
jmp wdTestRun
jmp wdTestState
.endif
