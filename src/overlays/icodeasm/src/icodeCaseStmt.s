;
; icodeCaseStmt.s
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

branchStmtOffset = 0
branchNumOffset = branchStmtOffset + 4
caseStmtOffset = branchNumOffset + 2

.export icodeCaseStmt

.import icodeLabel, loadStackValue, icodeOper1Label, icodeWriteInstruction
.import icodeExprRead, icodeStmts, icodeOper1Short, icodeOper2Short

.bss

intBuf: .res 10
labelExpr: .res 4

.data

lblCase: .asciiz "case"
lblBody: .asciiz "-body"
lblEndCase: .asciiz "endcase"
lblDash: .asciiz "-"

.code

.proc icodeCaseStmt
    stq ptr1
    jsr pushQ               ; case statement

    lda #1
    ldx #0
    jsr pushAX              ; branch number

    ; Loop through the case branches
    ldz #stmt::body
    neg
    neg
    nop
    lda (ptr1),z
    jsr pushQ               ; current branch stmt

L1: ldz #branchStmtOffset
    jsr loadStackValue
    jsr isQZero
    bne :+
    jmp DN

    ; Branch label
:   jsr formatBranchLabel
    jsr icodeOper1Label
    lda #IC_LOC
    jsr icodeWriteInstruction

    ; Loop through the labels for this case branch
    ldz #branchStmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::expr
    neg
    neg
    nop
    lda (ptr1),z

L2: jsr isQZero
    bne :+
    jmp L3
:   stq labelExpr

    ldz #caseStmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::expr
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ; Get the case statement's expression type
    ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2
    ldz #type::kind
    nop
    lda (ptr2),z
    pha
    ldq ptr1
    jsr icodeExprRead
    ldq labelExpr
    jsr icodeExprRead
    pla
    jsr icodeOper1Short
    ldq labelExpr
    stq ptr1
    ldz #expr::evalType
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #type::kind
    nop
    lda (ptr1),z
    jsr icodeOper2Short
    lda #IC_EQU
    jsr icodeWriteInstruction
    jsr formatBodyLabel
    jsr icodeOper1Label
    lda #IC_BIT
    jsr icodeWriteInstruction

    ldq labelExpr
    stq ptr1
    ldz #expr::right
    neg
    neg
    nop
    lda (ptr1),z
    jmp L2

    ; Write the code at the end of the branch label tests.
    ; If the code reaches this point, none of the branch labels matched
    ; the case statement expression. In that case, jump to the next
    ; branch (if any) or to the end of the case statement.
L3: ldz #branchStmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::next
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq L4
    ; Jump to the next branch
    jsr formatNextBanchLabel
    bra L5

    ; There are no other branches. Jump to the end label.
L4: jsr formatEndLabel
L5: jsr icodeOper1Label
    lda #IC_BRA
    jsr icodeWriteInstruction

    ; Write the label for the body
    jsr formatBodyLabel
    jsr icodeOper1Label
    lda #IC_LOC
    jsr icodeWriteInstruction

    ; Write this branch's body
    ldz #branchStmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::body
    neg
    neg
    nop
    lda (ptr1),z
    jsr icodeStmts

    ; If there are more branches, jump to the end of the case statement.
    ldz #branchStmtOffset
    jsr loadStackValue
    stq ptr1
    ldz #stmt::next
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    beq DN
    stq ptr1
    ldz #branchStmtOffset
    ldx #0
:   lda ptr1,x
    nop
    sta (stackPointer),z
    inz
    inx
    cpx #4
    bne :-

    ; Jump to the end of the case statement
    jsr formatEndLabel
    jsr icodeOper1Label
    lda #IC_BRA
    jsr icodeWriteInstruction

    ; Increment the branch number
    ldz #branchNumOffset
    nop
    lda (stackPointer),z
    clc
    adc #1
    nop
    sta (stackPointer),z
    inz
    nop
    lda (stackPointer),z
    adc #0
    nop
    sta (stackPointer),z
    jmp L1

    ; Write end label
DN: jsr formatEndLabel
    jsr icodeOper1Label
    lda #IC_LOC
    jsr icodeWriteInstruction

    jsr popQ
    jsr popAX
    jsr popQ
    rts
.endproc

; Formats the branch label in the format:
;    "case" + caseStmtPtr + "-" + branchNumber
.proc formatBranchLabel
    ; Write a null to the first position in the label
    lda #0
    sta icodeLabel
    lda #<lblCase
    ldx #>lblCase
    jsr appendLabel

    ; Format the caseStmtPtr
    ldz #caseStmtOffset
    jsr loadStackValue
    stq intOp32
    lda #<intBuf
    ldx #>intBuf
    jsr hexstr
    lda #<intBuf
    ldx #>intBuf
    jsr appendLabel

    ; Append a dash
    lda #<lblDash
    ldx #>lblDash
    jsr appendLabel

    ; Append the branch number
    ldz #branchNumOffset
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
    lda #<intBuf
    ldx #>intBuf
    jsr appendLabel

    rts
.endproc

; Formats the body label in the format:
;    "case" + caseStmtPtr + "-" + branchNumber + "-body"
.proc formatBodyLabel
    jsr formatBranchLabel

    ; Append "-body"
    lda #<lblBody
    ldx #>lblBody
    jsr appendLabel

    rts
.endproc

; Formats the end of case statement label in the format:
;    "endcase" + caseStmtPtr
.proc formatEndLabel
    lda #0
    sta icodeLabel
    lda #<lblEndCase
    ldx #>lblEndCase
    jsr appendLabel

    ; Format the caseStmtPtr
    ldz #caseStmtOffset
    jsr loadStackValue
    stq intOp32
    lda #<intBuf
    ldx #>intBuf
    jsr hexstr
    lda #<intBuf
    ldx #>intBuf
    jsr appendLabel

    rts
.endproc

; Formats the branch label in the format:
;    "case" + caseStmtPtr + "-" + (branchNumber+1)
.proc formatNextBanchLabel
    ; Write a null to the first position in the label
    lda #0
    sta icodeLabel
    lda #<lblCase
    ldx #>lblCase
    jsr appendLabel

    ; Format the caseStmtPtr
    ldz #caseStmtOffset
    jsr loadStackValue
    stq intOp32
    lda #<intBuf
    ldx #>intBuf
    jsr hexstr
    lda #<intBuf
    ldx #>intBuf
    jsr appendLabel

    ; Append a dash
    lda #<lblDash
    ldx #>lblDash
    jsr appendLabel

    ; Append the branch number + 1
    clc
    ldz #branchNumOffset
    nop
    lda (stackPointer),z
    adc #1
    sta intOp1
    inz
    nop
    lda (stackPointer),z
    adc #0
    sta intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    lda #<intBuf
    ldx #>intBuf
    jsr appendLabel

    rts
.endproc

; This routine appends a null-terminated string to the label.
; The string pointer is passed in A/X.
.proc appendLabel
    sta ptr4
    stx ptr4+1

    ; First, find the last character in the label
    ldx #0
:   lda icodeLabel,x
    beq :+
    inx
    bne :-

    ; Append the string
:   ldy #0
:   lda (ptr4),y
    beq :+
    sta icodeLabel,x
    inx
    iny
    bne :-

    ; Null-terminate the string
:   lda #0
    sta icodeLabel,x

    rts
.endproc
