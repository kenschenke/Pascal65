;
; initdumpast.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Routine to load dumpast from disk

.include "cbm_kernal.inc"
.include "c64.inc"

.data

fnDumpAst: .byte "dumpast,p,r"
fnDumpAst2:

.code

.export initDumpAst

.import loadfile

.proc initDumpAst
    ; Call SETNAM
    ldx #<fnDumpAst
    ldy #>fnDumpAst
    lda #fnDumpAst2-fnDumpAst
    jsr loadfile

    rts
.endproc
