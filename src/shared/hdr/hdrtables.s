;
; hdrtables.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Pointer-field tables shared by mkhdr (which writes pre-compiled headers)
; and the compiler (which loads them). See hdr.inc for the file format.

.include "ast.inc"
.include "hdr.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export hdrRecSize, hdrFieldFirst, hdrFieldNext, hdrTbl, hdrEntryPtr

; Conditional target codes. The target depends on the record's contents.
TK_COND_PARAMFIELDS = $81       ; type.paramFields
TK_COND_EXPRVALUE   = $82       ; expr.value

.bss

hdrTbl: .res 4                  ; index table (HDR_ENTRY_SIZE bytes per record)
fieldIdx: .res 1
v: .res 2
w: .res 2

.rodata

; Size of each record kind's structure, indexed by HDR_REC_*.
; HDR_REC_NAME is variable length.
hdrRecSize:
    .byte 0
    .byte .sizeof(decl)
    .byte .sizeof(type)
    .byte .sizeof(expr)
    .byte .sizeof(param_list)
    .byte 0
    .byte .sizeof(stmt)

descTable:
    .word 0
    .word descDecl
    .word descType
    .word descExpr
    .word descParam
    .word 0
    .word descStmt

; Each descriptor is a list of (field offset, target code), ending with $ff.
; A field that is not listed is copied as-is.

descDecl:
    .byte decl::type, HDR_REC_TYPE
    .byte decl::value, HDR_REC_EXPR
    .byte decl::node, HDR_TK_ZERO
    .byte decl::symtab, HDR_TK_ZERO
    .byte decl::code, HDR_REC_STMT
    .byte decl::next, HDR_REC_DECL
    .byte decl::unitSymtab, HDR_TK_ZERO
    .byte $ff

descType:
    .byte type::subtype, HDR_REC_TYPE
    .byte type::indextype, HDR_REC_TYPE
    .byte type::paramFields, TK_COND_PARAMFIELDS
    .byte type::symtab, HDR_TK_ZERO
    .byte type::name, HDR_REC_NAME
    .byte type::min, HDR_REC_EXPR
    .byte type::max, HDR_REC_EXPR
    .byte $ff

descExpr:
    .byte expr::left, HDR_REC_EXPR
    .byte expr::right, HDR_REC_EXPR
    .byte expr::name, HDR_REC_NAME
    .byte expr::node, HDR_TK_ZERO
    .byte expr::width, HDR_TK_ZERO
    .byte expr::precision, HDR_TK_ZERO
    .byte expr::evalType, HDR_TK_ZERO
    .byte expr::value, TK_COND_EXPRVALUE
    .byte $ff

descParam:
    .byte param_list::type, HDR_REC_TYPE
    .byte param_list::next, HDR_REC_PARAM
    .byte $ff

; Only the unit's module block exists in a library. The statement and
; loop fields are always null there.
descStmt:
    .byte stmt::decl, HDR_REC_DECL
    .byte stmt::interfaceDecl, HDR_REC_DECL
    .byte stmt::init_expr, HDR_TK_ZERO
    .byte stmt::expr, HDR_TK_ZERO
    .byte stmt::to_expr, HDR_TK_ZERO
    .byte stmt::body, HDR_TK_ZERO
    .byte stmt::else_body, HDR_TK_ZERO
    .byte stmt::next, HDR_TK_ZERO
    .byte $ff

.code

; Start iterating the pointer fields of a record kind.
; A contains the HDR_REC_* kind (never HDR_REC_NAME).
; Uses ptr4 as the descriptor pointer. Keep it intact until iteration ends.
.proc hdrFieldFirst
    asl
    tax
    lda descTable,x
    sta ptr4
    lda descTable+1,x
    sta ptr4+1
    lda #0
    sta fieldIdx
    rts
.endproc

; Get the next pointer field. ptr1 must point to the record.
; Returns carry set when there are no more fields.
; Otherwise carry is clear, X contains the field's offset, and A contains the
; target: 1..HDR_REC_COUNT is the HDR_REC_* kind the field points to,
; HDR_TK_ZERO means the field is not stored, HDR_TK_RAW means it is a value.
.proc hdrFieldNext
    ldy fieldIdx
    lda (ptr4),y
    cmp #$ff
    bne :+
    sec
    rts
:   tax
    iny
    lda (ptr4),y
    iny
    sty fieldIdx

    cmp #TK_COND_PARAMFIELDS
    beq ParamFields
    cmp #TK_COND_EXPRVALUE
    beq ExprValue
    clc
    rts

    ; type.paramFields is a parameter list for routines and programs/units
    ; and a declaration list for records and enumerations.
ParamFields:
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_FUNCTION
    beq IsParam
    cmp #TYPE_PROCEDURE
    beq IsParam
    cmp #TYPE_PROGRAM
    beq IsParam
    cmp #TYPE_UNIT
    beq IsParam
    cmp #TYPE_ROUTINE_POINTER
    beq IsParam
    cmp #TYPE_RECORD
    beq IsDecl
    cmp #TYPE_ENUMERATION
    beq IsDecl
    bra IsRaw

    ; expr.value is a name for string and real literals. Otherwise it's a value.
ExprValue:
    ldz #expr::kind
    nop
    lda (ptr1),z
    cmp #EXPR_STRING_LITERAL
    beq IsName
    cmp #EXPR_REAL_LITERAL
    beq IsName

IsRaw:
    lda #HDR_TK_RAW
    clc
    rts
IsParam:
    lda #HDR_REC_PARAM
    clc
    rts
IsDecl:
    lda #HDR_REC_DECL
    clc
    rts
IsName:
    lda #HDR_REC_NAME
    clc
    rts
.endproc

; Compute the address of an entry in the index table.
; A/X contains the 1-based record index.
; Returns ptr3 = hdrTbl + (index-1) * HDR_ENTRY_SIZE
.proc hdrEntryPtr
    sec
    sbc #1
    sta v
    txa
    sbc #0
    sta v+1

    ; w = v * 4
    lda v
    asl
    sta w
    lda v+1
    rol
    sta w+1
    asl w
    rol w+1

    ; w = w + v (v * 5)
    clc
    lda w
    adc v
    sta w
    lda w+1
    adc v+1
    sta w+1

    ; ptr3 = hdrTbl + w
    clc
    lda hdrTbl
    adc w
    sta ptr3
    lda hdrTbl+1
    adc w+1
    sta ptr3+1
    lda hdrTbl+2
    adc #0
    sta ptr3+2
    lda hdrTbl+3
    adc #0
    sta ptr3+3
    rts
.endproc
