;
; astlib.inc
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; AST LIB entry points

ASTBASE = $5800

declCreate = ASTBASE
nameCreate = ASTBASE + 3
paramListCreate = ASTBASE + 6
typeCreate = ASTBASE + 9
stmtCreate = ASTBASE + 12
exprCreate = ASTBASE + 15
unitCreate = ASTBASE + 18
nameClone = ASTBASE + 21
