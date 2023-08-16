.export _main

.import calcStackOffset, rtStackCleanup, rtStackInit, popAddrStack, pushIntStack, incsp4, readIntStack
.import popToIntOp1, popToIntOp2, addInt16, subInt16, pushFromIntOp1, multInt16, divInt16, writeInt16
.import intBuf, pushax, leftpad, _printz, storeIntStack, intOp1, intOp2

pvwrite = $fff7

.proc writechar
sta intBuf
lda #1
ldx #0
jsr pushax
lda #<intBuf
ldx #>intBuf
jsr pushax
lda #1
ldx #0
jmp pvwrite
.endproc

_main:
jsr rtStackInit         ; Initialize runtime stack

; Global variables

; -- minage (offset 0, level 1)
lda #1
ldx #0
jsr pushIntStack

; -- maxage (offset 1, level 1)
lda #56
ldx #1
jsr pushIntStack

; -- firstletter (offset 2, level 1)
lda #97
ldx #0
jsr pushIntStack

; -- lastletter (offset 3, level 1)
lda #122
ldx #0
jsr pushIntStack

; -- i (offset 4, level 1)
lda #0
tax
jsr pushIntStack

; -- j (offset 5, level 1)
lda #0
tax
jsr pushIntStack

; -- b (offset 6, level 1)
lda #0
tax
jsr pushIntStack

; -- c (offset 7, level 1)
lda #0
tax
jsr pushIntStack

; -- Statements in main block
; -- Line 13
lda #2
ldx #0
jsr pushIntStack        ; Push the integer in A/X onto the stack
lda #1
ldx #4
jsr calcStackOffset     ; Calculate offset of i
jsr storeIntStack       ; Store the int at the top of the stack into addr
; -- Line 14
lda #3
ldx #0
jsr pushIntStack        ; Push the integer in A/X onto the stack
lda #1
ldx #5
jsr calcStackOffset     ; Calculate offset of j
jsr storeIntStack       ; Store the int at the top of the stack into addr
; -- Line 16
lda #1
ldx #4
jsr calcStackOffset     ; Calculate offset of i
jsr readIntStack        ; Read the integer from the address and leave it in A/X
jsr pushIntStack        ; Push the integer in A/X onto the stack
lda #1
ldx #5
jsr calcStackOffset     ; Calculate offset of j
jsr readIntStack        ; Read the integer from the address and leave it in A/X
jsr pushIntStack        ; Push the integer in A/X onto the stack
lda #5
ldx #0
; jsr pushIntStack        ; Push the integer in A/X onto the stack


; lda #0
; rts

; jsr popToIntOp2 ; Store the int at the top of the stack in intOp2



; jsr popToIntOp1 ; Store the int at the top of the stack in intOp1
; jsr multInt16
; jsr pushFromIntOp1      ; Push intOp1 onto the stack
; jsr popToIntOp2 ; Store the int at the top of the stack in intOp2
; jsr popToIntOp1 ; Store the int at the top of the stack in intOp1
; jsr addInt16
; jsr pushFromIntOp1      ; Push intOp1 onto the stack
; jsr popToIntOp1 ; Store the int at the top of the stack in intOp1
; jsr writeInt16
; lda #<intBuf
; ldx #>intBuf
; jsr _printz
lda #' '
; jsr writechar
; lda #25
; ldx #0
; jsr pushIntStack        ; Push the integer in A/X onto the stack
; jsr popToIntOp1 ; Store the int at the top of the stack in intOp1
; jsr writeInt16
; lda #<intBuf
; ldx #>intBuf
; jsr _printz
lda #10 ; Linefeed
; jsr writechar

; -- Clean declarations off the stack
; jsr incsp4
; jsr incsp4
; jsr incsp4
; jsr incsp4
; jsr incsp4
; jsr incsp4
; jsr incsp4
; jsr incsp4

; -- Clean the program's stack frame up
; jsr rtStackCleanup

; -- Done
lda #0
rts