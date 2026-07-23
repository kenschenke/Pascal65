;
; prgChain.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Chain PRG 

.include "asm.inc"
.include "asmlib.inc"
.include "linker.inc"
.include "codegen.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"

.export setChainProg, writeChainCode, chainPrgLength

.import incCodeOffset, genThreeAddr

.bss

; These two variables are used when the generated program is to
; chain-load another PRG when it finishes. If chainPrg is non-null,
; the next PRG is loaded. If chainPrompt is non-zero, the user is
; prompted to press a key before the PRG is loaded.

chainPrg: .res 2                ; 16-bit pointer to filename to call next
chainPrgLength: .res 1          ; length of filename (calculated by setChainProg)
chainPrompt: .res 1             ; non-zero if user is prompted to press a key

.data

tagChainPrompt: .asciiz "chainprompt"
tagChainCode: .asciiz "chaincode"
tagPromptMsg: .asciiz "promptmsg"

; The following blocks handle chain-loading the next PRG.

; This block of code is what is copied up to $9000
CHAINCALL_STRLEN = 10
CHAINCALL_LENGTH = 28
prgChainCall:
    .byte OC_LDA_IMMEDIATE, 0
    .byte OC_LDX_IMMEDIATE, 8   ; device
    .byte OC_LDY_IMMEDIATE, $ff
    .byte OC_JSR, .lobyte(SETLFS), .hibyte(SETLFS)

    .byte OC_LDA_IMMEDIATE, 0   ; strlen(name)
    .byte OC_LDX_IMMEDIATE, $1c ; lower name address
    .byte OC_LDY_IMMEDIATE, $90 ; upper name address
    .byte OC_JSR, .lobyte(SETNAM), .hibyte(SETNAM)

    .byte OC_LDA_IMMEDIATE, 0
    .byte OC_TAX
    .byte OC_TAY
    .byte OC_JSR, .lobyte(LOAD), .hibyte(LOAD)

    .byte OC_JMP, $11, $20      ; Entry point for loaded program
    ; filename to load

; This block of code is placed at the end of the clean up code in the PRG.
; It copies the loader up to $9000 then JMPs to that code.
CHAINCODE_SRCL = 1
CHAINCODE_SRCH = 5
CHAINCODE_COPYLENGTH = 17
CHAINCODE_LENGTH = 26
prgChainCode:
    .byte OC_LDA_IMMEDIATE, 0           ; low byte of source
    .byte OC_STA_ZEROPAGE, ZP_PTR2L
    .byte OC_LDA_IMMEDIATE, 0           ; high byte of source
    .byte OC_STA_ZEROPAGE, ZP_PTR2H
    .byte OC_LDA_IMMEDIATE, $00         ; low byte of $9000
    .byte OC_STA_ZEROPAGE, ZP_PTR1L
    .byte OC_LDA_IMMEDIATE, $90         ; high byte of $9000
    .byte OC_STA_ZEROPAGE, ZP_PTR1H
    .byte OC_LDA_IMMEDIATE, 0           ; low byte of length to copy
    .byte OC_LDX_IMMEDIATE, 0           ; high byte of length to copy
    .byte OC_JSR, .lobyte(RT_MEMCOPY), .hibyte(RT_MEMCOPY)
    .byte OC_JMP, $00, $90      ; JMP to $9000
    ; filename to load

; This block of code is placed at the end of the clean up code in the PRG.
; It prompts the user to press a key then waits for that keypress.
CHAINPROMPT_MSGLO = 8
CHAINPROMPT_MSGHI = 10
CHAINPROMPT_LENGTH = 20
prgChainPrompt:
    .byte OC_LDA_IMMEDIATE, FH_STDIO
    .byte OC_LDX_IMMEDIATE, 0
    .byte OC_JSR, .lobyte(RT_SETFH), .hibyte(RT_SETFH)
    .byte OC_LDA_IMMEDIATE, 0
    .byte OC_LDX_IMMEDIATE, 0
    .byte OC_JSR, .lobyte(RT_PRINTZ), .hibyte(RT_PRINTZ)
    .byte OC_JSR, .lobyte(CHRIN), .hibyte(CHRIN)
    .byte OC_BEQ, $fb
    .byte OC_RTS

promptMsg: .asciiz "Press a key."

.code

; This routine is called to set chainPrg and chainPrompt.
; A/X contains the 16-pointer to the filename of the PRG.
; Y is non-zero if the user is prompted before the next PRG is loaded.
.proc setChainProg
    sta chainPrg
    sta ptr1
    stx chainPrg+1
    stx ptr1+1
    sty chainPrompt

    lda #0
    sta chainPrgLength

    lda chainPrg
    ora chainPrg+1
    beq DN

    ldy #0
:   lda (ptr1),y
    beq :+
    iny
    bne :-
:   sty chainPrgLength

DN: rts
.endproc

; This routine writes the code to chain to the next PRG.
;
; Here is the rough layout of what is written to the PRG.
; 
; ... object code for PRG ...
; If the user is to be prompted, a JSR to the prompt code is put here.
; prgChainCode: copies the loader to $9000
; JMP $9000
; prgChainCall: this is the loader that is copied to $9000
; ... filename of next PRG to load ...
; prgChainPrompt: If the user is to be prompted, the prompt routine is put here.

.proc writeChainCode
    lda chainPrompt
    beq :+
    ; JSR to the chain prompt code
    lda #<tagChainPrompt
    ldx #>tagChainPrompt
    ldy #LINKADDR_BOTH
    ldz #1
    jsr linkAddressLookup
    genThree OC_JSR, 0

    ; Write the code that copies to the loader to $9000
:   lda #<tagChainCode
    ldx #>tagChainCode
    ldy #LINKADDR_LOW
    ldz #CHAINCODE_SRCL
    jsr linkAddressLookup

    lda #<tagChainCode
    ldx #>tagChainCode
    ldy #LINKADDR_HIGH
    ldz #CHAINCODE_SRCH
    jsr linkAddressLookup

    lda #CHAINCALL_LENGTH
    clc
    adc chainPrgLength
    ldx #CHAINCODE_COPYLENGTH
    sta prgChainCode,x

    ; Write the code to the object file
    ldx #0
:   lda prgChainCode,x
    jsr CHROUT
    inx
    cpx #CHAINCODE_LENGTH
    bne :-
    txa
    jsr incCodeOffset

    ; Write the code that is copied up to the $9000

    lda #<tagChainCode
    ldx #>tagChainCode
    jsr linkAddressSet

    lda chainPrgLength
    ldx #CHAINCALL_STRLEN
    sta prgChainCall,x
    ldx #0
:   lda prgChainCall,x
    jsr CHROUT
    inx
    cpx #CHAINCALL_LENGTH
    bne :-
    txa
    jsr incCodeOffset

    ; Write the filename
    lda chainPrg
    sta ptr1
    lda chainPrg+1
    sta ptr1+1
    lda #0
    sta tmp1
:   ldy tmp1
    lda (ptr1),y
    jsr CHROUT
    inc tmp1
    lda tmp1
    cmp chainPrgLength
    bne :-

    lda chainPrgLength
    jsr incCodeOffset

    ; If the user is prompted, write the chain prompt code
    lda chainPrompt
    beq DN

    jsr writeChainPrompt

DN: rts
.endproc

.proc writeChainPrompt
    lda #<tagPromptMsg
    ldx #>tagPromptMsg
    ldy #LINKADDR_LOW
    ldz #CHAINPROMPT_MSGLO
    jsr linkAddressLookup

    lda #<tagPromptMsg
    ldx #>tagPromptMsg
    ldy #LINKADDR_HIGH
    ldz #CHAINPROMPT_MSGHI
    jsr linkAddressLookup

    lda #<tagChainPrompt
    ldx #>tagChainPrompt
    jsr linkAddressSet

    ldx #0
:   lda prgChainPrompt,x
    jsr CHROUT
    inx
    cpx #CHAINPROMPT_LENGTH
    bne :-

    txa
    jsr incCodeOffset

    lda #<tagPromptMsg
    ldx #>tagPromptMsg
    jsr linkAddressSet

    ldx #0
:   lda promptMsg,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   jsr CHROUT
    inx
    txa
    jsr incCodeOffset

    rts
.endproc
