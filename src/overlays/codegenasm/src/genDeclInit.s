;
; genDeclInit.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; genDeclInit routine

.include "asm.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "linker.inc"
.include "codegen.inc"
.include "zeropage.inc"

.export genDeclInit

.import strbuf, genTwoInstruction, genThreeAddr

; ARRAYDECL_ARRAY or ARRAYDECL_RECORD passed in A
.proc genDeclInit
    pha             ; save declaration type

    lda #<strbuf
    ldx #>strbuf
    ldy #LINKADDR_LOW
    ldz #1
    jsr linkAddressLookup
    genTwoImmediate OC_LDA_IMMEDIATE, 0

    lda #<strbuf
    ldx #>strbuf
    ldy #LINKADDR_HIGH
    ldz #1
    jsr linkAddressLookup
    genTwoImmediate OC_LDX_IMMEDIATE, 0

    pla             ; declaration type
    sta tmp1
    genTwoAbsolute OC_LDY_IMMEDIATE, tmp1

    genThree OC_JSR, RT_INITDECL

    rts
.endproc
