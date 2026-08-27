;
; dumpSymtabForDecl.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; dumpSymtabForDecl routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export dumpSymtabForDecl

.import dumpDecl, memBuf, level, dumpMemBuf

; This routine dumps the symbol table for the decl in Q.
; It also recurses down the tree, dumping any symbol tables
; it finds in child nodes.
.proc dumpSymtabForDecl
    jsr pushQ
    lda #0
    sta level

    jsr allocMemBuf
    stq memBuf

    jsr popQ
    jsr dumpDecl

    ; jsr dumpMemBuf
    ldq memBuf
    rts
.endproc
