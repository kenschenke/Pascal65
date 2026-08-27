;
; showType.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; showType routine

.include "ast.inc"
.include "asmlib.inc"
.include "4510macros.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "symtab.inc"

CH_BACKARROW = 95

.export showType, showTypeKind

.import showAddr, printz, printzLong, printStructAddr, printNamePtr
.import printStructBool, printStructNumber, getKey, loadPtr, showSubExpr
.import showParam, showDecl, showSymtab

.data

kindLabel: .asciiz "kind: "
subtypeLabel: .asciiz "subtype: "
indextypeLabel: .asciiz "indextype: "
flagsLabel: .asciiz "flags: "
routineCodeLabel: .asciiz "routineCode: "
paramFieldsLabel: .asciiz "paramFields: "
symtabLabel: .asciiz "symtab: "
nameLabel: .asciiz "name: "
minLabel: .asciiz "min: "
maxLabel: .asciiz "max: "
sizeLabel: .asciiz "size: "
lineNumberLabel: .asciiz "lineNumber: "
prompt: .byte "S:subtype  I:indextype  P:params  Y:symtab  ", $5f, ":back", $0d, $0d, $0

strTYPE_VOID: .asciiz "TYPE_VOID"
strTYPE_BYTE: .asciiz "TYPE_BYTE"
strTYPE_SHORTINT: .asciiz "TYPE_SHORTINT"
strTYPE_WORD: .asciiz "TYPE_WORD"
strTYPE_INTEGER: .asciiz "TYPE_INTEGER"
strTYPE_CARDINAL: .asciiz "TYPE_CARDINAL"
strTYPE_LONGINT: .asciiz "TYPE_LONGINT"
strTYPE_REAL: .asciiz "TYPE_REAL"
strTYPE_BOOLEAN: .asciiz "TYPE_BOOLEAN"
strTYPE_CHARACTER: .asciiz "TYPE_CHARACTER"
strTYPE_STRING_LITERAL: .asciiz "TYPE_STRING_LITERAL"
strTYPE_ARRAY: .asciiz "TYPE_ARRAY"
strTYPE_FUNCTION: .asciiz "TYPE_FUNCTION"
strTYPE_PROCEDURE: .asciiz "TYPE_PROCEDURE"
strTYPE_PROGRAM: .asciiz "TYPE_PROGRAM"
strTYPE_UNIT: .asciiz "TYPE_UNIT"
strTYPE_DECLARED: .asciiz "TYPE_DECLARED"
strTYPE_SUBRANGE: .asciiz "TYPE_SUBRANGE"
strTYPE_ENUMERATION: .asciiz "TYPE_ENUMERATION"
strTYPE_ENUMERATION_VALUE: .asciiz "TYPE_ENUMERATION_VALUE"
strTYPE_RECORD: .asciiz "TYPE_RECORD"
strTYPE_STRING_VAR: .asciiz "TYPE_STRING_VAR"
strTYPE_STRING_OBJ: .asciiz "TYPE_STRING_OBJ"
strTYPE_FILE: .asciiz "TYPE_FILE"
strTYPE_TEXT: .asciiz "TYPE_TEXT"
strTYPE_SCALAR_BYTES: .asciiz "TYPE_SCALAR_BYTES"
strTYPE_HEAP_BYTES: .asciiz "TYPE_HEAP_BYTES"
strTYPE_POINTER: .asciiz "TYPE_POINTER"
strTYPE_ADDRESS: .asciiz "TYPE_ADDRESS"
strTYPE_ROUTINE_ADDRESS: .asciiz "TYPE_ROUTINE_ADDRESS"
strTYPE_ROUTINE_POINTER: .asciiz "TYPE_ROUTINE_POINTER"

typeKinds: .byte .LOBYTE(strTYPE_VOID), .HIBYTE(strTYPE_VOID)
           .byte .LOBYTE(strTYPE_BYTE), .HIBYTE(strTYPE_BYTE)
           .byte .LOBYTE(strTYPE_SHORTINT), .HIBYTE(strTYPE_SHORTINT)
           .byte .LOBYTE(strTYPE_WORD), .HIBYTE(strTYPE_WORD)
           .byte .LOBYTE(strTYPE_INTEGER), .HIBYTE(strTYPE_INTEGER)
           .byte .LOBYTE(strTYPE_CARDINAL), .HIBYTE(strTYPE_CARDINAL)
           .byte .LOBYTE(strTYPE_LONGINT), .HIBYTE(strTYPE_LONGINT)
           .byte .LOBYTE(strTYPE_REAL), .HIBYTE(strTYPE_REAL)
           .byte .LOBYTE(strTYPE_BOOLEAN), .HIBYTE(strTYPE_BOOLEAN)
           .byte .LOBYTE(strTYPE_CHARACTER), .HIBYTE(strTYPE_CHARACTER)
           .byte .LOBYTE(strTYPE_STRING_LITERAL), .HIBYTE(strTYPE_STRING_LITERAL)
           .byte .LOBYTE(strTYPE_ARRAY), .HIBYTE(strTYPE_ARRAY)
           .byte .LOBYTE(strTYPE_FUNCTION), .HIBYTE(strTYPE_FUNCTION)
           .byte .LOBYTE(strTYPE_PROCEDURE), .HIBYTE(strTYPE_PROCEDURE)
           .byte .LOBYTE(strTYPE_PROGRAM), .HIBYTE(strTYPE_PROGRAM)
           .byte .LOBYTE(strTYPE_UNIT), .HIBYTE(strTYPE_UNIT)
           .byte .LOBYTE(strTYPE_DECLARED), .HIBYTE(strTYPE_DECLARED)
           .byte .LOBYTE(strTYPE_SUBRANGE), .HIBYTE(strTYPE_SUBRANGE)
           .byte .LOBYTE(strTYPE_ENUMERATION), .HIBYTE(strTYPE_ENUMERATION)
           .byte .LOBYTE(strTYPE_ENUMERATION_VALUE), .HIBYTE(strTYPE_ENUMERATION_VALUE)
           .byte .LOBYTE(strTYPE_RECORD), .HIBYTE(strTYPE_RECORD)
           .byte .LOBYTE(strTYPE_STRING_VAR), .HIBYTE(strTYPE_STRING_VAR)
           .byte .LOBYTE(strTYPE_STRING_OBJ), .HIBYTE(strTYPE_STRING_OBJ)
           .byte .LOBYTE(strTYPE_FILE), .HIBYTE(strTYPE_FILE)
           .byte .LOBYTE(strTYPE_TEXT), .HIBYTE(strTYPE_TEXT)
           .byte .LOBYTE(strTYPE_SCALAR_BYTES), .HIBYTE(strTYPE_SCALAR_BYTES)
           .byte .LOBYTE(strTYPE_HEAP_BYTES), .HIBYTE(strTYPE_HEAP_BYTES)
           .byte .LOBYTE(strTYPE_POINTER), .HIBYTE(strTYPE_POINTER)
           .byte .LOBYTE(strTYPE_ADDRESS), .HIBYTE(strTYPE_ADDRESS)
           .byte .LOBYTE(strTYPE_ROUTINE_ADDRESS), .HIBYTE(strTYPE_ROUTINE_ADDRESS)
           .byte .LOBYTE(strTYPE_ROUTINE_POINTER), .HIBYTE(strTYPE_ROUTINE_POINTER)

strTYPE_FLAG_ISCONST: .asciiz "ISCONST"
strTYPE_FLAG_ISFORWARD: .asciiz "ISFORWARD"
strTYPE_FLAG_ISBYREF: .asciiz "ISBYREF"
strTYPE_FLAG_ISSTD: .asciiz "ISSTD"
strTYPE_FLAG_ISRETVAL: .asciiz "ISRETVAL"

str_rcNA: .asciiz "n/a"
str_rcDeclared: .asciiz "rcDeclared"
str_rcForward: .asciiz "rcForward"
str_rcRead: .asciiz "rcRead"
str_rcReadln: .asciiz "rcReadln"
str_rcReadStr: .asciiz "rcReadStr"
str_rcWrite: .asciiz "rcWrite"
str_rcWriteln: .asciiz "rcWriteln"
str_rcWriteStr: .asciiz "rcWriteStr"
str_rcAbs: .asciiz "rcAbs"
str_rcEoln: .asciiz "rcEoln"
str_rcOrd: .asciiz "rcOrd"
str_rcPred: .asciiz "rcPred"
str_rcRound: .asciiz "rcRound"
str_rcSqr: .asciiz "rcSqr"
str_rcSucc: .asciiz "rcSucc"
str_rcTrunc: .asciiz "rcTrunc"
str_rcDec: .asciiz "rcDec"
str_rcInc: .asciiz "rcInc"

routineCodes: .byte .LOBYTE(str_rcDeclared), .HIBYTE(str_rcDeclared)
              .byte .LOBYTE(str_rcForward), .HIBYTE(str_rcForward)
              .byte .LOBYTE(str_rcRead), .HIBYTE(str_rcRead)
              .byte .LOBYTE(str_rcReadln), .HIBYTE(str_rcReadln)
              .byte .LOBYTE(str_rcReadStr), .HIBYTE(str_rcReadStr)
              .byte .LOBYTE(str_rcWrite), .HIBYTE(str_rcWrite)
              .byte .LOBYTE(str_rcWriteln), .HIBYTE(str_rcWriteln)
              .byte .LOBYTE(str_rcWriteStr), .HIBYTE(str_rcWriteStr)
              .byte .LOBYTE(str_rcAbs), .HIBYTE(str_rcAbs)
              .byte .LOBYTE(str_rcEoln), .HIBYTE(str_rcEoln)
              .byte .LOBYTE(str_rcOrd), .HIBYTE(str_rcOrd)
              .byte .LOBYTE(str_rcPred), .HIBYTE(str_rcPred)
              .byte .LOBYTE(str_rcRound), .HIBYTE(str_rcRound)
              .byte .LOBYTE(str_rcSqr), .HIBYTE(str_rcSqr)
              .byte .LOBYTE(str_rcSucc), .HIBYTE(str_rcSucc)
              .byte .LOBYTE(str_rcTrunc), .HIBYTE(str_rcTrunc)
              .byte .LOBYTE(str_rcDec), .HIBYTE(str_rcDec)
              .byte .LOBYTE(str_rcInc), .HIBYTE(str_rcInc)

.code

.proc showType
    stq ptr2

    ; Kind
    lda #<kindLabel
    ldx #>kindLabel
    jsr printz
    jsr showTypeKind
    lda #13
    jsr CHROUT

    ; Subtype
    lda #<subtypeLabel
    ldx #>subtypeLabel
    jsr printz
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr2),z
    jsr showAddr
    ldq ptr2
    jsr pushQ
    ldz #type::subtype
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

    ; Indextype
    lda #<indextypeLabel
    ldx #>indextypeLabel
    ldz #type::indextype
    jsr printStructAddr

    ; Flags
    lda #<flagsLabel
    ldx #>flagsLabel
    jsr printz
    lda #0
    sta tmp3
    ldz #type::flags
    nop
    lda (ptr2),z
    sta tmp1

    lda #TYPE_FLAG_ISBYREF
    sta tmp2
    ldx #<strTYPE_FLAG_ISBYREF
    ldy #>strTYPE_FLAG_ISBYREF
    jsr printFlag

    lda #TYPE_FLAG_ISCONST
    sta tmp2
    ldx #<strTYPE_FLAG_ISCONST
    ldy #>strTYPE_FLAG_ISCONST
    jsr printFlag

    lda #TYPE_FLAG_ISFORWARD
    sta tmp2
    ldx #<strTYPE_FLAG_ISFORWARD
    ldy #>strTYPE_FLAG_ISFORWARD
    jsr printFlag

    lda #TYPE_FLAG_ISSTD
    sta tmp2
    ldx #<strTYPE_FLAG_ISSTD
    ldy #>strTYPE_FLAG_ISSTD
    jsr printFlag

    lda #TYPE_FLAG_ISRETVAL
    sta tmp2
    ldx #<strTYPE_FLAG_ISRETVAL
    ldy #>strTYPE_FLAG_ISRETVAL
    jsr printFlag

    lda #13
    jsr CHROUT

    ; routineCode
    lda #<routineCodeLabel
    ldx #>routineCodeLabel
    jsr printz
    ldz #type::flags
    nop
    lda (ptr2),z
    bit #TYPE_FLAG_ISSTD
    bne :+
    lda #<str_rcNA
    ldx #>str_rcNA
    jsr printz
    bra L1
:   ldz #type::routineCode
    nop
    lda (ptr2),z
    asl a
    tay
    lda routineCodes,y
    ldx routineCodes+1,y
    jsr printz
L1: lda #13
    jsr CHROUT

    ; paramFields
    lda #<paramFieldsLabel
    ldx #>paramFieldsLabel
    ldz #type::paramFields
    jsr printStructAddr

    ; Subtype
    lda #<symtabLabel
    ldx #>symtabLabel
    ldz #type::symtab
    jsr printStructAddr

    ; Name
    lda #<nameLabel
    ldx #>nameLabel
    ldz #type::name
    jsr printNamePtr

    ; Min
    lda #<minLabel
    ldx #>minLabel
    jsr printz
    ldz #type::min
    neg
    neg
    nop
    lda (ptr2),z
    jsr showAddr
    ldz #type::min
    jsr showSubExpr

    ; Max
    lda #<maxLabel
    ldx #>maxLabel
    jsr printz
    ldz #type::max
    neg
    neg
    nop
    lda (ptr2),z
    jsr showAddr
    ldz #type::max
    jsr showSubExpr

    ; size
    lda #<sizeLabel
    ldx #>sizeLabel
    jsr printz
    ldz #type::size
    jsr printStructNumber

    ; lineNumber
    lda #<lineNumberLabel
    ldx #>lineNumberLabel
    jsr printz
    ldz #type::lineNumber
    jsr printStructNumber

    lda #13
    jsr CHROUT

    lda #<prompt
    ldx #>prompt
    jsr printz

L2: jsr getKey
    cmp #'s'
    bne L3
    ldq ptr2
    jsr pushQ
    ldz #type::subtype
    jsr loadPtr
    beq :+
    jsr showType
:   jsr popQ
    jmp showType
L3: cmp #'i'
    bne L4
    ldq ptr2
    jsr pushQ
    ldz #type::indextype
    jsr loadPtr
    beq :+
    jsr showType
:   jsr popQ
    jmp showType
L4: cmp #'p'
    bne L5
    ldq ptr2
    jsr pushQ
    ldz #type::paramFields
    jsr loadPtr
    beq :+
    jsr showParam
:   jsr popQ
    jmp showType
L5: cmp #'y'
    bne L6
    ldq ptr2
    jsr pushQ
    ldz #type::symtab
    jsr loadPtr
    beq :+
    jsr showSymtab
:   jsr popQ
    jmp showType
L6: cmp #CH_BACKARROW
    bne L7
    rts
L7: bra L2
.endproc

; This routine prints a flag's label
; X - low byte of flag label
; Y - high byte of flag label
;
; flag value in tmp1
; flag bit in tmp2
; tmp3 is used for storage
.proc printFlag
    lda tmp1
    bit tmp2
    bne :+
    rts
:   phx
    phy
    lda tmp3
    beq :+
    lda #','
    jsr CHROUT
    lda #' '
    jsr CHROUT
:   plx
    pla
    jsr printz
    lda #1
    sta tmp3
    rts
.endproc

.proc showTypeKind
    ldq ptr2
    jsr isQZero
    bne :+
    rts
:   ldz #type::kind
    nop
    lda (ptr2),z
    asl a
    tay
    lda typeKinds,y
    ldx typeKinds+1,y
    jsr printz
    rts
.endproc
