.include "ast.inc"
.include "asmlib.inc"
.include "4510macros.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "symtab.inc"

CH_BACKARROW = 95

.export showParam

.import showAddr, printz, printStructName
.import printStructNumber, getKey, loadPtr
.import showTypeKind, showType, printStructAddr

.data

nameLabel: .asciiz "name: "
typeLabel: .asciiz "type: "
nextLabel: .asciiz "next: "
lineNumberLabel: .asciiz "lineNumber: "
prompt: .byte "T:type  N:next  ", $5f, ":back", $0d, $0d, $0

.code

.proc showParam
    stq ptr2

    ; Name
    lda #<nameLabel
    ldx #>nameLabel
    ldz #param_list::name
    jsr printStructName

    ; Type
    lda #<typeLabel
    ldx #>typeLabel
    jsr printz
    ldz #param_list::type
    neg
    neg
    nop
    lda (ptr2),z
    jsr showAddr
    ldq ptr2
    jsr pushQ
    ldz #param_list::type
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    jsr isQZero
    beq :+
    lda #' '
    jsr CHROUT
    jsr showTypeKind
:   lda #13
    jsr CHROUT
    jsr popQ
    stq ptr2

    ; Next
    lda #<nextLabel
    ldx #>nextLabel
    ldz #param_list::next
    jsr printStructAddr

    ; lineNumber
    lda #<lineNumberLabel
    ldx #>lineNumberLabel
    jsr printz
    ldz #param_list::lineNumber
    jsr printStructNumber

    lda #13
    jsr CHROUT

    lda #<prompt
    ldx #>prompt
    jsr printz

L2: jsr getKey
    cmp #'t'
    bne L3
    ldq ptr2
    jsr pushQ
    ldz #param_list::type
    jsr loadPtr
    beq :+
    jsr showType
:   jsr popQ
    jmp showParam
L3: cmp #'n'
    bne L4
    ldq ptr2
    jsr pushQ
    ldz #param_list::next
    jsr loadPtr
    beq :+
    jsr showParam
:   jsr popQ
    jmp showParam
L4: cmp #CH_BACKARROW
    bne L5
    rts
L5: bra L2
.endproc
