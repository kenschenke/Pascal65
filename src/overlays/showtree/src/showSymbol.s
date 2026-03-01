;
; showSymbol.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; showSymbol routine

.include "ast.inc"
.include "4510macros.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "symtab.inc"
.include "asmlib.inc"

CH_BACKARROW = 95

.export showSymbol

.import showAddr, printz, printStructAddr, printStructName
.import getKey, loadPtr, showTypeKind, showType, printStructNumber

.data

kindLabel: .asciiz "kind: "
nodeLabel: .asciiz "node: "
typeLabel: .asciiz "type: "
nameLabel: .asciiz "name: "
declLabel: .asciiz "decl: "
offsetLabel: .asciiz "offset: "
levelLabel: .asciiz "level: "
prompt: .byte "T:type  ", $5f, ":back", $0d, $0d, $0

strSYMBOL_LOCAL: .asciiz "SYMBOL_LOCAL"
strSYMBOL_PARAM: .asciiz "SYMBOL_PARAM"
strSYMBOL_GLOBAL: .asciiz "SYMBOL_GLOBAL"

symbolKinds: .byte .LOBYTE(strSYMBOL_LOCAL), .HIBYTE(strSYMBOL_LOCAL)
             .byte .LOBYTE(strSYMBOL_PARAM), .HIBYTE(strSYMBOL_PARAM)
             .byte .LOBYTE(strSYMBOL_GLOBAL), .HIBYTE(strSYMBOL_GLOBAL)

.code

.proc showSymbol
    stq ptr2

    ; Kind
    lda #<kindLabel
    ldx #>kindLabel
    jsr printz
    jsr showKind
    lda #13
    jsr CHROUT

    ; Node
    lda #<nodeLabel
    ldx #>nodeLabel
    ldz #symbol::node
    jsr printStructAddr

    ; Type
    lda #<typeLabel
    ldx #>typeLabel
    jsr printz
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr2),z
    jsr showAddr
    ldq ptr2
    jsr pushQ
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    lda #' '
    jsr CHROUT
    jsr showTypeKind
    jsr popQ
    stq ptr2
    lda #13
    jsr CHROUT

    ; Name
    lda #<nameLabel
    ldx #>nameLabel
    ldz #symbol::name
    jsr printStructName

    ; Decl
    lda #<declLabel
    ldx #>declLabel
    ldz #symbol::decl
    jsr printStructAddr

    ; Offset
    lda #<offsetLabel
    ldx #>offsetLabel
    jsr printz
    ldz #symbol::offset
    jsr printStructNumber

    ; Level
    lda #<levelLabel
    ldx #>levelLabel
    jsr printz
    ldz #symbol::level
    jsr printStructNumber

    lda #13
    jsr CHROUT

    lda #<prompt
    ldx #>prompt
    jsr printz

L1: jsr getKey
    cmp #'t'
    bne L2
    ldq ptr2
    jsr pushQ
    ldz #symbol::type
    jsr loadPtr
    beq :+
    jsr showType
:   jsr popQ
    jmp showSymbol
L2: cmp #CH_BACKARROW
    bne L3
    rts
L3: bra L1
.endproc

.proc showKind
    ldz #symbol::kind
    nop
    lda (ptr2),z
    asl a
    tay
    lda symbolKinds,y
    ldx symbolKinds+1,y
    jsr printz
    rts
.endproc
