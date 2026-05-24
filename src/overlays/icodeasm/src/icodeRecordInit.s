;
; icodeRecordInit.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; icodeRecordInit routine

.include "ast.inc"
.include "icode.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

fieldLabelSize = 25

; Local variables
fieldOffset = 0
memberTypeOffset = fieldOffset + 2
recordOffset = memberTypeOffset + 1
declMemBufOffset = recordOffset + 2
fieldTypePtrOffset = declMemBufOffset + 4
fieldLabelOffset = fieldTypePtrOffset + 4
fieldPtrOffset = fieldLabelOffset + fieldLabelSize
; Parameters passed on stack
declPtrOffset = fieldPtrOffset + 4
typePtrOffset = declPtrOffset + 4
labelOffset = typePtrOffset + 4

.export icodeRecordInit

.import loadStackValue, heapOffset, icodeArrayInit, icodeSaveData
.import icodeOper1Label, icodeWriteInstruction, icodeLabel

.bss

intBuf: .res 10

.data

strDi: .asciiz "di"

.code

; Parameters passed on stack, bottom to top:
;    label
;    type
;    declaration
.proc icodeRecordInit
    ; Set up local variables
    jsr pushQZero   ; fieldPtr
    lda #fieldLabelSize
    jsr pushBlock
    jsr pushQZero   ; fieldTypePtr
    jsr pushQZero   ; declMemBuf
    lda heapOffset
    ldx heapOffset+1
    jsr pushAX      ; recordOffset
    lda #0
    jsr pushA       ; memberType
    lda #0
    tax
    jsr pushAX      ; fieldOffset

    ; Initialize fieldPtr
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::paramFields
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #fieldPtrOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

    ; Loop through the record fields
L1: ldz #fieldPtrOffset
    jsr loadStackValue
    jsr isQZero
    bne :+
    jmp DN

    ; Retrieve the field type
:   stq ptr1
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldz #fieldTypePtrOffset
    ldx #0
:   lda ptr2,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

    ; Initialize memberType to 0
    ldz #memberTypeOffset
    lda #0
    nop
    sta (stackPointer),z

    ; Clear the fieldLabel
    ldz #fieldLabelOffset
    lda #0
    nop
    sta (stackPointer),z

    ; If the declaration has a node, use the symbol type instead
    ldz #decl::node
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L2
    stq ptr3
    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_DECLARED
    bne L2
    ldz #symbol::type
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr2
    ldz #fieldTypePtrOffset
    ldx #0
:   lda ptr2,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

    ; If the field is an embedded record:
L2: ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_RECORD
    bne :+
    jsr embeddedRecord
    bra L3
:   cmp #TYPE_STRING_VAR
    bne :+
    jsr stringField
    bra L3
:   cmp #TYPE_FILE
    bne :+
    jsr fileField
    bra L3
:   cmp #TYPE_TEXT
    bne :+
    jsr fileField
    bra L3
:   cmp #TYPE_ARRAY
    bne L3
    jsr embeddedArray

    ; Allocate a membuf if not allocated yet
L3: ldz #declMemBufOffset
    jsr loadStackValue
    jsr isQZero
    bne :+
    jsr allocDeclMemBuf
:   ldz #memberTypeOffset
    nop
    lda (stackPointer),z
    beq :+
    jsr writeFieldInfo

    ; Increment the heapOffset
:   ldz #fieldTypePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::size
    nop
    lda (ptr1),z
    clc
    adc heapOffset
    sta heapOffset
    inz
    nop
    lda (ptr1),z
    adc heapOffset+1
    sta heapOffset+1

    ; Increment fieldOffset
    ldz #type::size
    nop
    lda (ptr1),z
    clc
    ldz #fieldOffset
    nop
    adc (stackPointer),z
    nop
    sta (stackPointer),z
    ldz #type::size+1
    nop
    lda (ptr1),z
    ldz #fieldOffset+1
    nop
    adc (stackPointer),z
    nop
    sta (stackPointer),z

    ; Go to the next field
    ldz #fieldPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #fieldPtrOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-
    jmp L1

    ; End of loop
DN: ldz #declMemBufOffset
    jsr loadStackValue
    jsr isQZero
    beq :+
    jsr closeDeclMemBuf

    ; Clean variables and parameters off the stack
:   jsr popAX       ; fieldOffset
    jsr popA        ; memberType
    jsr popAX       ; recordOffset
    jsr popQ        ; declMemBuf
    jsr popQ        ; fieldTypePtr
    lda #fieldLabelSize
    jsr popBlock    ; fieldLabel
    jsr popQ        ; fieldPtr
    jsr popQ        ; declPtr
    jsr popQ        ; typePtr
    jsr popQ        ; label

    rts
.endproc

.proc allocDeclMemBuf
    jsr allocMemBuf
    stq ptr1
    ldz #declMemBufOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

    ; Write the record offset to the membuf
    lda #recordOffset
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq stackPointer
    clc
    adcq intOp32
    stq ptr2
    lda #2
    ldx #0
    jsr writeToMemBuf

    ; Write the record size
    ldz #declMemBufOffset
    jsr loadStackValue
    stq ptr1
    lda #type::size
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldz #typePtrOffset
    jsr loadStackValue
    clc
    adcq intOp32
    stq ptr2
    lda #2
    ldx #0
    jsr writeToMemBuf

    rts
.endproc

.proc closeDeclMemBuf
    ; Write a 0 to terminate the list of fields
    ldz #declMemBufOffset
    jsr loadStackValue
    stq ptr1
    lda #0
    sta intBuf
    lda #<intBuf
    sta ptr2
    lda #>intBuf
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr writeToMemBuf

    ; Add a data segment for the record init block
    ldz #declMemBufOffset
    jsr loadStackValue
    stq ptr1
    ldz #labelOffset
    jsr loadStackValue
    stq ptr2
    lda #ARRAYDECL_RECORD
    jsr pushA               ; Data block type
    ldq ptr1
    jsr pushQ               ; Membuf
    ldq ptr2
    jsr pushQ               ; label
    jsr icodeSaveData
    rts
.endproc

.proc embeddedArray
    jsr formatFieldLabel
    ; Copy label -> fieldLabel
    ; tmp1=labelOffset
    ; tmp2=fieldLabelOffset
;     ldz #labelOffset
;     jsr loadStackValue
;     stq ptr1
;     lda #0
;     sta tmp1
;     lda #fieldLabelOffset
;     sta tmp2
; :   ldz tmp1
;     nop
;     lda (ptr1),z
;     beq :+
;     ldz tmp2
;     nop
;     sta (stackPointer),z
;     inc tmp1
;     inc tmp2
;     bne :-
; :   lda tmp2
;     pha             ; Save fieldLabelOffset
    ; Format declPtr
    ; ldz #declPtrOffset
    ; jsr loadStackValue
    ; stq intOp32
    ; lda #<intBuf
    ; ldx #>intBuf
    ; jsr hexstr
;     lda heapOffset
;     sta intOp1
;     lda heapOffset+1
;     sta intOp1+1
;     lda #<intBuf
;     ldx #>intBuf
;     jsr writeInt16
;     ; Concat intBuf onto fieldLabel
;     pla         ; Restore fieldOffset
;     sta tmp1
;     ldx #0
; :   lda intBuf,x
;     beq :+
;     ldz tmp1
;     nop
;     sta (stackPointer),z
;     inx
;     inz
;     bne :-
; :   lda #'.'
;     nop
;     sta (stackPointer),z
;     inz
;     phz         ; Save label offset
;     ; Format fieldOffset
;     ldz #fieldOffset
;     nop
;     lda (stackPointer),z
;     sta intOp1
;     inz
;     nop
;     lda (stackPointer),z
;     sta intOp1+1
;     lda #<intBuf
;     ldx #>intBuf
;     jsr writeInt16
;     ; Concat intBuf onto fieldLabel
;     plz             ; Restore label offset
;     ldx #0
; :   lda intBuf,x
;     nop
;     sta (stackPointer),z
;     beq :+
;     inz
;     inx
;     bne :-
    ; Save the heapOffset
    lda heapOffset
    pha
    lda heapOffset+1
    pha
    ; Call icodeArrayInit
    lda #fieldLabelOffset
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq stackPointer
    clc
    adcq intOp32
    stq ptr1
    jsr pushQ           ; save the label pointer
    ; Copy the field label to icodeLabel
    ldz #0
    ldx #0
:   nop
    lda (ptr1),z
    sta icodeLabel,x
    beq :+
    inz
    inx
    bne :-
:   ; Write the DIA instruction
    jsr icodeOper1Label
    lda #IC_DIA
    jsr icodeWriteInstruction
    ; Put the label back into ptr1
    jsr popQ
    stq ptr1
    ldz #fieldTypePtrOffset
    jsr loadStackValue
    stq ptr2
    ldz #fieldPtrOffset
    jsr loadStackValue
    stq ptr3
    ldz #decl::value
    neg
    neg
    nop
    lda (ptr3),z
    stq ptr3
    ldz #declPtrOffset
    jsr loadStackValue
    stq ptr4
    ldq ptr1
    jsr pushQ               ; label
    ldq ptr2
    jsr pushQ               ; type
    ldq ptr3
    jsr pushQ               ; value
    ldq ptr4
    jsr pushQ               ; declPtr
    jsr icodeArrayInit
    ; Restore heapOffset
    pla
    sta heapOffset+1
    pla
    sta heapOffset
    ; Set memberType
    ldz #memberTypeOffset
    lda #ARRAYDECL_ARRAY
    nop
    sta (stackPointer),z

    rts
.endproc

.proc embeddedRecord
    jsr formatFieldLabel

    lda #fieldLabelOffset
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq stackPointer
    clc
    adcq intOp32
    stq ptr1
    ldz #fieldTypePtrOffset
    jsr loadStackValue
    stq ptr2
    ldz #declPtrOffset
    jsr loadStackValue
    stq ptr3
    ldq ptr1
    jsr pushQ               ; label
    ldq ptr2
    jsr pushQ               ; fieldType
    ldq ptr3
    jsr pushQ               ; declPtr
    jsr icodeRecordInit
    ldz #memberTypeOffset
    lda #ARRAYDECL_RECORD
    nop
    sta (stackPointer),z
    rts
.endproc

.proc fileField
    ; Set memberType to ARRAYDECL_FILE
    ldz #memberTypeOffset
    lda #ARRAYDECL_FILE
    nop
    sta (stackPointer),z
    rts
.endproc

.proc stringField
    ; Set memberType to ARRAYDECL_STRING
    ldz #memberTypeOffset
    lda #ARRAYDECL_STRING
    nop
    sta (stackPointer),z
    rts
.endproc

.proc writeFieldInfo
    ; Write memberType
    ldz #declMemBufOffset
    jsr loadStackValue
    stq ptr1
    lda #memberTypeOffset
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq stackPointer
    clc
    adcq intOp32
    stq ptr2
    lda #1
    ldx #0
    jsr writeToMemBuf

    ; Write fieldOffset
    ldz #declMemBufOffset
    jsr loadStackValue
    stq ptr1
    lda #fieldOffset
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq stackPointer
    clc
    adcq intOp32
    stq ptr2
    lda #2
    ldx #0
    jsr writeToMemBuf

    ; Write fieldLabel
    ldz #declMemBufOffset
    jsr loadStackValue
    stq ptr1
    lda #fieldLabelOffset
    sta intOp32
    lda #0
    sta intOp32+1
    sta intOp32+2
    sta intOp32+3
    ldq stackPointer
    clc
    adcq intOp32
    stq ptr2
    ; Count the length
    ldz #0
:   nop
    lda (ptr2),z
    beq :+
    inz
    bne :-
:   inz
    tza
    ldx #0
    jsr writeToMemBuf

    rts
.endproc

.proc formatFieldLabel
    ; Copy the label to the fieldLabel
    ldz #labelOffset
    jsr loadStackValue
    stq ptr1
    lda #0
    sta tmp1
    lda #fieldLabelOffset
    sta tmp2
:   ldz tmp1
    nop
    lda (ptr1),z
    beq :+
    ldz tmp2
    nop
    sta (stackPointer),z
    inc tmp1
    inc tmp2
    bne :-
:   lda #'.'
    ldz tmp2
    nop
    sta (stackPointer),z
    inc tmp2
    lda tmp2
    pha
    
    ; lda tmp2
    ; pha             ; Save field label offset
    ; lda heapOffset
    ; sta intOp1
    ; lda heapOffset+1
    ; sta intOp1+1
    ; lda #<intBuf
    ; ldx #>intBuf
    ; jsr writeInt16
    ; ; Concat intBuf onto fieldLabel
    ; pla         ; Restore fieldOffset
    ; sta tmp1

    ; Format fieldOffset
    ldz #fieldOffset
    nop
    lda (stackPointer),z
    sta intOp1
    inz
    nop
    lda (stackPointer),z
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    pla
    sta tmp1
    ldx #0
:   ldz tmp1
    lda intBuf,x
    nop
    sta (stackPointer),z
    beq :+
    inx
    inc tmp1
    bne :-
:   rts
.endproc
