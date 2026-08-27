;
; dumpType.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; dumpType routine

.include "ast.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export dumpType, dumpTypeMember, dumpTypeKind

.import level, printz, dumpString, dumpPtrString, dumpExprValue, newLine, showPrefix, dumpChar, dumpDecl
.import indent

.bss

anyFlag: .res 1

.data

strOF: .asciiz " OF "
strDotDot: .asciiz ".."
strParam: .asciiz "param:"
strFlags: .asciiz "flags: "
strReturn: .asciiz "return: "
strMin: .asciiz "min:"
strMax: .asciiz "max:"
strTYPE_VOID: .asciiz "TYPE-VOID"
strTYPE_BYTE: .asciiz "TYPE-BYTE"
strTYPE_SHORTINT: .asciiz "TYPE-SHORTINT"
strTYPE_WORD: .asciiz "TYPE-WORD"
strTYPE_INTEGER: .asciiz "TYPE-INTEGER"
strTYPE_CARDINAL: .asciiz "TYPE-CARDINAL"
strTYPE_LONGINT: .asciiz "TYPE-LONGINT"
strTYPE_REAL: .asciiz "TYPE-REAL"
strTYPE_BOOLEAN: .asciiz "TYPE-BOOLEAN"
strTYPE_CHARACTER: .asciiz "TYPE-CHARACTER"
strTYPE_STRING_LITERAL: .asciiz "TYPE-STRING-LITERAL"
strTYPE_ARRAY: .asciiz "TYPE-ARRAY"
strTYPE_FUNCTION: .asciiz "TYPE-FUNCTION"
strTYPE_PROCEDURE: .asciiz "TYPE-PROCEDURE"
strTYPE_PROGRAM: .asciiz "TYPE-PROGRAM"
strTYPE_UNIT: .asciiz "TYPE-UNIT"
strTYPE_DECLARED: .asciiz "TYPE-DECLARED"
strTYPE_SUBRANGE: .asciiz "TYPE-SUBRANGE"
strTYPE_ENUMERATION: .asciiz "TYPE-ENUMERATION"
strTYPE_ENUMERATION_VALUE: .asciiz "TYPE-ENUMERATION-VALUE"
strTYPE_RECORD: .asciiz "TYPE-RECORD"
strTYPE_STRING_VAR: .asciiz "TYPE-STRING-VAR"
strTYPE_STRING_OBJ: .asciiz "TYPE-STRING-OBJ"
strTYPE_FILE: .asciiz "TYPE-FILE"
strTYPE_TEXT: .asciiz "TYPE-TEXT"
strTYPE_SCALAR_BYTES: .asciiz "TYPE-SCALAR-BYTES"
strTYPE_HEAP_BYTES: .asciiz "TYPE-HEAP-BYTES"
strTYPE_POINTER: .asciiz "TYPE-POINTER"
strTYPE_ADDRESS: .asciiz "TYPE-ADDRESS"
strTYPE_ROUTINE_ADDRESS: .asciiz "TYPE-ROUTINE-ADDRESS"
strTYPE_ROUTINE_POINTER: .asciiz "TYPE-ROUTINE-POINTER"

strTYPE_FLAG_ISCONST: .asciiz "TYPE-FLAG-ISCONST"
strTYPE_FLAG_ISFORWARD: .asciiz "TYPE-FLAG-ISFORWARD"
strTYPE_FLAG_ISBYREF: .asciiz "TYPE-FLAG-ISBYREF"
strTYPE_FLAG_ISSTD: .asciiz "TYPE-FLAG-ISSTD"
strTYPE_FLAG_ISRETVAL: .asciiz "TYPE-FLAG-ISRETVAL"

kinds: .byte .LOBYTE(strTYPE_VOID), .HIBYTE(strTYPE_VOID)
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

.code

.proc dumpTypeMember
    phz
    ldq ptr1
    jsr pushQ
    plz
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq :+

    jsr dumpType

:   jsr popQ
    stq ptr1
    rts
.endproc

.proc dumpType
    stq ptr1

    inc level
    lda #'T'
    jsr showPrefix

    ldz #type::kind
    nop
    lda (ptr1),z
    jsr dumpTypeKind
    
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    bne L1
    jsr dumpArrayType
    jsr newLine
    bra L7

L1: cmp #TYPE_RECORD
    bne L2
    jsr dumpRecordType
    bra L7

L2: cmp #TYPE_ENUMERATION
    bne L3
    jsr dumpRecordType
    bra L7

L3: cmp #TYPE_PROCEDURE
    bne L4
    jsr dumpProcedureType
    bra L7

L4: cmp #TYPE_FUNCTION
    bne L5
    jsr dumpFunctionType
    bra L7

L5: cmp #TYPE_SUBRANGE
    bne L6
    jsr dumpSubrangeType
    bra L7

L6: ldz #type::name
    jsr dumpPtrString

    jsr newLine

    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    beq L7
    ldz #type::subtype
    jsr dumpTypeMember

L7: dec level
    rts
.endproc

.proc dumpTypeKind
    asl a
    tay
    lda kinds,y
    ldx kinds+1,y
    jsr printz
    rts
.endproc

.proc dumpArrayType
    lda #' '
    jsr dumpChar

    ldq ptr1
    jsr pushQ
    ldz #type::indextype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    neg
    neg
    nop
    ldz #type::min
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jsr dumpExprValue
    jsr popQ
    stq ptr1

    lda #<strDotDot
    ldx #>strDotDot
    jsr printz

    ldq ptr1
    jsr pushQ
    ldz #type::indextype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    neg
    neg
    nop
    ldz #type::max
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jsr dumpExprValue
    jsr popQ
    stq ptr1

    lda #<strOF
    ldx #>strOF
    jsr printz

    ldq ptr1
    jsr pushQ
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ; If the subtype is an array, dump the full type specification
    ; instead of just the type kind.
    ldz #type::kind
    nop
    lda (ptr1),z
    cmp #TYPE_ARRAY
    bne L1
    lda #<strTYPE_ARRAY
    ldx #>strTYPE_ARRAY
    jsr printz
    jsr dumpArrayType
    bra L2
L1: ldz #type::kind
    nop
    lda (ptr1),z
    jsr dumpTypeKind
L2: jsr popQ
    stq ptr1

    rts
.endproc

.proc dumpRecordType
    ldq ptr1
    jsr pushQ

    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1

    jsr newLine
    inc level

L1: ldq ptr1
    jsr isQZero
    beq L3

    ldq ptr1
    jsr pushQ
    ldq ptr1
    jsr dumpDecl
    jsr popQ
    stq ptr1

    ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    bra L1

L3: jsr popQ
    stq ptr1
    dec level
    rts
.endproc

.proc dumpProcedureType
    ldq ptr1
    jsr pushQ

    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jsr dumpRoutineParams

    jsr popQ
    stq ptr1
    rts
.endproc

.proc dumpFunctionType
    ldq ptr1
    jsr pushQ

    jsr newLine
    inc level
    jsr indent
    lda #<strReturn
    ldx #>strReturn
    jsr printz
    ldz #type::subtype
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    jsr dumpTypeKind
    jsr popQ
    stq ptr1
    jsr pushQ
    dec level

    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jsr dumpRoutineParams

    jsr popQ
    stq ptr1
    rts
.endproc

.proc dumpRoutineParams
    jsr newLine
    inc level

L1: ldq ptr1
    jsr isQZero
    beq L3

    jsr indent
    lda #<strParam
    ldx #>strParam
    jsr printz
    ldz #param_list::name
    jsr dumpString

    jsr newLine
    inc indent
    ldq ptr1
    jsr pushQ
    ldz #param_list::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr dumpType
    jsr popQ
    stq ptr1
    jsr pushQ
    ldz #param_list::type
    neg
    neg
    nop
    lda (ptr1),z
    jsr dumpTypeFlags
    jsr popQ
    stq ptr1
    dec indent

    ldz #param_list::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    bra L1

L3: dec level
    rts
.endproc

.proc dumpSubrangeType
    ldq ptr1
    jsr pushQ
    inc level

    jsr newLine
    jsr indent
    lda #<strMin
    ldx #>strMin
    jsr printz
    ldz #type::min
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jsr dumpExprValue
    jsr popQ
    stq ptr1
    jsr pushQ

    jsr newLine
    jsr indent
    lda #<strMax
    ldx #>strMax
    jsr printz
    ldz #type::max
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    jsr dumpExprValue
    jsr popQ
    stq ptr1

    jsr newLine

    dec level
    rts
.endproc

.proc dumpTypeFlags
    stq ptr1
    inc level
    lda #0
    sta anyFlag
    ldz #type::flags
    nop
    lda (ptr1),z
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

    lda anyFlag
    beq :+
    jsr newLine

:   dec level
    rts
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

    lda tmp1
    jsr pushA
    lda anyFlag
    jsr pushA

    lda anyFlag
    bne :+
    jsr indent
    lda #<strFlags
    ldx #>strFlags
    jsr printz
    lda #1
    sta anyFlag

:   jsr popA
    beq :+
    lda #','
    jsr dumpChar
    lda #' '
    jsr dumpChar
:   plx
    pla
    jsr printz
    jsr popA
    sta tmp1
    rts
.endproc
