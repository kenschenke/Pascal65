;
; icodeVariableDeclarations.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export icodeVariableDeclarations

.import icodeShortValue, icodeWordValue, icodeCharValue, icodeLongValue
.import icodeBoolValue, icodeRealValue, heapOffset, icodeWriteInstruction
.import icodeOper1Int, icodeOper1Long, icodeOper1String
.import icodeOper1Label, icodeArrayInit, icodeLabel, icodeRecordInit

.bss

declPtr: .res 4
localVars: .res 4
varIndex: .res 1
symDecl: .res 4
declInitLabel: .res 15

.data

diStr: .asciiz "di"

.code

; This routine expects two inputs:
;    ptr1 - pointer to storage for local variable info
;    Q - first declaration in chain
;    Number of variables returned in A
.proc icodeVariableDeclarations
    stq declPtr

    ldq ptr1
    stq localVars

    lda #0
    sta varIndex

    ; Loop through the declarations
L1: ldq declPtr
    jsr isQZero
    bne :+
    jmp DN

:   stq ptr1
    ldq localVars
    stq ptr2
    ldz varIndex
    lda #0
    nop
    sta (ptr2),z

    ldz #decl::kind
    nop
    lda (ptr1),z
    cmp #DECL_CONST
    beq L2
    cmp #DECL_VARIABLE
    beq L2
    jmp NX

L2: ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr getBaseType
    stq ptr2

    ; If this is the return value for a function, skip it.
    ldz #type::flags
    nop
    lda (ptr2),z
    and #TYPE_FLAG_ISRETVAL
    beq :+
    jmp NX

:   ldz #decl::node
    neg
    neg
    nop
    lda (ptr1),z
    stq symDecl

    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_BYTE
    bne :+
    jsr shortValue
    jmp L3
:   cmp #TYPE_SHORTINT
    bne :+
    jsr shortValue
    jmp L3
:   cmp #TYPE_INTEGER
    bne :+
    jsr wordValue
    jmp L3
:   cmp #TYPE_WORD
    bne :+
    jsr wordValue
    jmp L3
:   cmp #TYPE_ENUMERATION
    bne :+
    jsr wordValue
    jmp L3
:   cmp #TYPE_CHARACTER
    bne :+
    jsr charValue
    jmp L3
:   cmp #TYPE_LONGINT
    bne :+
    jsr longValue
    jmp L3
:   cmp #TYPE_CARDINAL
    bne :+
    jsr longValue
    jmp L3
:   cmp #TYPE_FILE
    bne :+
    jsr fileValue
    jmp L3
:   cmp #TYPE_TEXT
    bne :+
    jsr fileValue
    jmp L3
:   cmp #TYPE_BOOLEAN
    bne :+
    jsr boolValue
    jmp L3
:   cmp #TYPE_POINTER
    bne :+
    lda #0
    tax
    tay
    taz
    jsr icodeWordValue
    jmp L3
:   cmp #TYPE_ROUTINE_POINTER
    bne :+
    lda #0
    tax
    tay
    taz
    jsr icodeLongValue
    jmp L3
:   cmp #TYPE_REAL
    bne :+
    jsr realValue
    jmp L3
:   cmp #TYPE_ARRAY
    bne :+
    jsr arrayValue
    jmp L3
:   cmp #TYPE_RECORD
    bne :+
    jsr recordValue
    jmp L3
:   cmp #TYPE_STRING_VAR
    bne L3
    jsr stringValue

    ; Is this a library declaration?
L3: ldq declPtr
    stq ptr1
    ldz #decl::isLibrary
    nop
    lda (ptr1),z
    beq L4
    ; Write the address of this library declaration
    ; to the library's jump table.
    jsr libraryDecl

L4: inc varIndex

NX: ldq declPtr
    stq ptr1
    ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    stq declPtr
    jmp L1

DN: lda varIndex
    rts
.endproc

.proc arrayValue
    lda #0
    sta heapOffset
    sta heapOffset+1

    ldz #type::size+1
    nop
    lda (ptr2),z
    tax
    dez
    nop
    lda (ptr2),z
    jsr icodeOper1Int
    lda #IC_NEW
    jsr icodeWriteInstruction

    jsr formatDeclLabel
    lda #<declInitLabel
    ldx #>declInitLabel
    ldy #0
    ldz #0
    jsr pushQ               ; label
    ldq declPtr
    stq ptr1
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ               ; type
    ldz #decl::value
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ               ; value
    ldq declPtr
    jsr pushQ               ; declaration
    jsr icodeArrayInit

    ; Copy declInitLabel to icodeLabel
    ldx #0
:   lda declInitLabel,x
    sta icodeLabel,x
    beq :+
    inx
    bne :-

:   jsr icodeOper1Label
    lda #IC_DIA
    jsr icodeWriteInstruction
    rts
.endproc

.proc boolValue
    ldq declPtr
    stq ptr1
    ldz #decl::value
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeBoolValue
    rts
.endproc

.proc charValue
    ldq declPtr
    stq ptr1
    ldz #decl::value
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeCharValue
    rts
.endproc

.proc fileValue
    lda #0
    tax
    tay
    taz
    jsr icodeLongValue
    ldq localVars
    stq ptr3
    ldz varIndex
    lda #LOCALVARS_FILE
    nop
    sta (ptr3),z
    rts
.endproc

.proc libraryDecl
    rts
.endproc

.proc longValue
    ldq declPtr
    stq ptr1
    ldz #decl::value
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeLongValue
    rts
.endproc

.proc realValue
    ldq declPtr
    stq ptr1
    ldz #decl::value
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeRealValue
    rts
.endproc

.proc recordValue
    ldq localVars
    stq ptr3
    ldz varIndex
    lda #LOCALVARS_RECORD
    nop
    sta (ptr3),z

    ldz #type::size+1
    nop
    lda (ptr2),z
    tax
    dez
    nop
    lda (ptr2),z
    jsr icodeOper1Int
    lda #IC_NEW
    jsr icodeWriteInstruction

    lda #0
    sta heapOffset
    sta heapOffset+1

    jsr formatDeclLabel
    lda #<declInitLabel
    ldx #>declInitLabel
    ldy #0
    ldz #0
    jsr pushQ               ; label
    ldq declPtr
    stq ptr1
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ               ; type
    ldq declPtr
    jsr pushQ               ; declaration
    jsr icodeRecordInit

    ; Copy declInitLabel to icodeLabel
    ldx #0
:   lda declInitLabel,x
    sta icodeLabel,x
    beq :+
    inx
    bne :-

:   jsr icodeOper1Label
    lda #IC_DIR
    jsr icodeWriteInstruction
    rts
.endproc

.proc shortValue
    ldq declPtr
    stq ptr1
    ldz #decl::value
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeShortValue
    rts
.endproc

.proc stringValue
    ldq localVars
    stq ptr3
    ldz varIndex
    lda #LOCALVARS_DEL
    nop
    sta (ptr3),z
    inc varIndex

    ldq declPtr
    stq ptr1
    ldz #decl::kind
    nop
    lda (ptr1),z
    cmp #DECL_CONST
    beq L1
    ldz #decl::value
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    bne L1

    ; Allocate an empty string
    lda #0
    tax
    tay
    taz
    jsr icodeOper1Long
    lda #IC_SST
    jsr icodeWriteInstruction
    rts

L1: ldz #decl::value
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldz #expr::kind
    nop
    lda (ptr2),z
    cmp #EXPR_NAME
    bne L2
    ldz #expr::node
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ldz #symbol::decl
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2
    ldz #decl::value
    neg
    neg
    nop
    lda (ptr2),z
    stq ptr2

L2: ldz #expr::value
    neg
    neg
    nop
    lda (ptr2),z
    jsr icodeOper1String
    lda #IC_SST
    jsr icodeWriteInstruction
    rts
.endproc

.proc wordValue
    ldq declPtr
    stq ptr1
    ldz #decl::value
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeWordValue
    rts
.endproc

.proc formatDeclLabel
    ldx #0
:   lda diStr,x
    beq :+
    sta declInitLabel,x
    inx
    bne :-

:   stx tmp1
    ldq declPtr
    stq intOp32
    lda #<declInitLabel
    clc
    adc tmp1
    pha
    lda #>declInitLabel
    adc #0
    tax
    pla
    jsr hexstr
    rts
.endproc
