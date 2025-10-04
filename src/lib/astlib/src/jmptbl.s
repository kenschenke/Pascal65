;
; jmptbl.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; AST LIB jump table

.import declCreate, nameCreate, paramListCreate, typeCreate, stmtCreate
.import exprCreate, unitCreate, nameClone

.segment "JMPTBL"

jmp declCreate
jmp nameCreate
jmp paramListCreate
jmp typeCreate
jmp stmtCreate
jmp exprCreate
jmp unitCreate
jmp nameClone
