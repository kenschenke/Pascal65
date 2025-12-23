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
.include "zeropage.inc"
.include "4510macros.inc"

.export dumpType

.import dumpChar, printz, printNumber

.data

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

.proc dumpType
    stq ptr1

    ; Kind
    ldz #type::kind
    nop
    lda (ptr1),z
    asl a
    tay
    lda kinds+1,y
    tax
    lda kinds,y
    jsr printz

    lda #' '
    jsr dumpChar

    ldz #type::size
    lda #'S'
    jsr printNumber
    
    rts
.endproc
