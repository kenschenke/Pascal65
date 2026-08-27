.include "tokenizer.inc"
.include "cbm_kernal.inc"
.include "zeropage.inc"
.include "asmlib.inc"
.include "4510macros.inc"

.export dumpTokens

.import openSourceFile, closeSourceFile, tokenCode, tokenString
.import handleTokenize, currentLineNumber

.data

sourceFn: .asciiz "hello.pas"
tokenStr: .asciiz "Token "
byteStr: .asciiz "Byte "
wordStr: .asciiz "Word "
cardinalStr: .asciiz "Cardinal "
lineNumStr: .asciiz "Line "
errorStr: .asciiz "Error"
realStr: .asciiz "Real "

tknDummy: .asciiz "Dummy"
tknIdentifier: .asciiz "Identifier"
tknNumber: .asciiz "Number Literal"
tknString: .asciiz "String Literal"
tknEndOfFile: .asciiz "End Of File"
tknError: .asciiz "Error"
tknBOOLEAN: .asciiz "BOOLEAN"
tknBYTE: .asciiz "BYTE"
tknCARDINAL: .asciiz "CARDINAL"
tknCHAR: .asciiz "CHAR"
tknINTEGER: .asciiz "INTEGER"
tknLONGINT: .asciiz "LONGINT"
tknREAL: .asciiz "REAL"
tknSTRING: .asciiz "STRING"
tknSHORTINT: .asciiz "SHORTINT"
tknWORD: .asciiz "WORD"
tknFALSE: .asciiz "FALSE"
tknTRUE: .asciiz "TRUE"
tknSTACKSIZE: .asciiz "STACKSIZE"
tknUpArrow: .asciiz "^"
tknStar: .asciiz "*"
tknLParen: .asciiz "("
tknRParen: .asciiz ")"
tknMinus: .asciiz "-"
tknPlus: .asciiz "+"
tknEqual: .asciiz "="
tknLBracket: .asciiz "["
tknRBracket: .asciiz "]"
tknColon: .asciiz ":"
tknSemiColon: .asciiz ";"
tknLt: .asciiz "<"
tknGt: .asciiz ">"
tknComma: .asciiz ","
tknPeriod: .asciiz "."
tknSlash: .asciiz "/"
tknColonEqual: .asciiz ":="
tknLe: .asciiz "<="
tknGe: .asciiz ">="
tknNe: .asciiz "<>"
tknDotDot: .asciiz ".."
tknBang: .asciiz "!"
tknAmpersand: .asciiz "&"
tknLShift: .asciiz "<<"
tknRShift: .asciiz ">>"
tknAt: .asciiz "@"
tknAND: .asciiz "AND"
tknARRAY: .asciiz "ARRAY"
tknBEGIN: .asciiz "BEGIN"
tknCASE: .asciiz "CASE"
tknCONST: .asciiz "CONST"
tknDIV: .asciiz "DIV"
tknDO: .asciiz "DO"
tknDOWNTO: .asciiz "DOWNTO"
tknELSE: .asciiz "ELSE"
tknEND: .asciiz "END"
tknFILE: .asciiz "FILE"
tknFOR: .asciiz "FOR"
tknFUNCTION: .asciiz "FUNCTION"
tknGOTO: .asciiz "GOTO"
tknIF: .asciiz "IF"
tknIMPLEMENTATION: .asciiz "IMPLEMENTATION"
tknIN: .asciiz "IN"
tknINTERFACE: .asciiz "INTERFACE"
tknLABEL: .asciiz "LABEL"
tknMOD: .asciiz "MOD"
tknNIL: .asciiz "NIL"
tknNOT: .asciiz "NOT"
tknOF: .asciiz "OF"
tknOR: .asciiz "OR"
tknXOR: .asciiz "XOR"
tknPACKED: .asciiz "PACKED"
tknPROCEDURE: .asciiz "PROCEDURE"
tknPROGRAM: .asciiz "PROGRAM"
tknRECORD: .asciiz "RECORD"
tknREPEAT: .asciiz "REPEAT"
tknSET: .asciiz "SET"
tknTEXT: .asciiz "TEXT"
tknTHEN: .asciiz "THEN"
tknTO: .asciiz "TO"
tknTYPE: .asciiz "TYPE"
tknUNIT: .asciiz "UNIT"
tknUNTIL: .asciiz "UNTIL"
tknUSES: .asciiz "USES"
tknVAR: .asciiz "VAR"
tknWHILE: .asciiz "WHILE"
tknWITH: .asciiz "WITH"

tokens: .byte .LOBYTE(tknDummy), .HIBYTE(tknDummy)
        .byte .LOBYTE(tknIdentifier), .HIBYTE(tknIdentifier)
        .byte .LOBYTE(tknNumber), .HIBYTE(tknNumber)
        .byte .LOBYTE(tknString), .HIBYTE(tknString)
        .byte .LOBYTE(tknEndOfFile), .HIBYTE(tknEndOfFile)
        .byte .LOBYTE(tknError), .HIBYTE(tknError)
        .byte .LOBYTE(tknBOOLEAN), .HIBYTE(tknBOOLEAN)
        .byte .LOBYTE(tknBYTE), .HIBYTE(tknBYTE)
        .byte .LOBYTE(tknCARDINAL), .HIBYTE(tknCARDINAL)
        .byte .LOBYTE(tknCHAR), .HIBYTE(tknCHAR)
        .byte .LOBYTE(tknINTEGER), .HIBYTE(tknINTEGER)
        .byte .LOBYTE(tknLONGINT), .HIBYTE(tknLONGINT)
        .byte .LOBYTE(tknREAL), .HIBYTE(tknREAL)
        .byte .LOBYTE(tknSTRING), .HIBYTE(tknSTRING)
        .byte .LOBYTE(tknSHORTINT), .HIBYTE(tknSHORTINT)
        .byte .LOBYTE(tknWORD), .HIBYTE(tknWORD)
        .byte .LOBYTE(tknFALSE), .HIBYTE(tknFALSE)
        .byte .LOBYTE(tknTRUE), .HIBYTE(tknTRUE)
        .byte .LOBYTE(tknSTACKSIZE), .HIBYTE(tknSTACKSIZE)
        .byte .LOBYTE(tknUpArrow), .HIBYTE(tknUpArrow)
        .byte .LOBYTE(tknStar), .HIBYTE(tknStar)
        .byte .LOBYTE(tknLParen), .HIBYTE(tknLParen)
        .byte .LOBYTE(tknRParen), .HIBYTE(tknRParen)
        .byte .LOBYTE(tknMinus), .HIBYTE(tknMinus)
        .byte .LOBYTE(tknPlus), .HIBYTE(tknPlus)
        .byte .LOBYTE(tknEqual), .HIBYTE(tknEqual)
        .byte .LOBYTE(tknLBracket), .HIBYTE(tknLBracket)
        .byte .LOBYTE(tknRBracket), .HIBYTE(tknRBracket)
        .byte .LOBYTE(tknColon), .HIBYTE(tknColon)
        .byte .LOBYTE(tknSemiColon), .HIBYTE(tknSemiColon)
        .byte .LOBYTE(tknLt), .HIBYTE(tknLt)
        .byte .LOBYTE(tknGt), .HIBYTE(tknGt)
        .byte .LOBYTE(tknComma), .HIBYTE(tknComma)
        .byte .LOBYTE(tknPeriod), .HIBYTE(tknPeriod)
        .byte .LOBYTE(tknSlash), .HIBYTE(tknSlash)
        .byte .LOBYTE(tknColonEqual), .HIBYTE(tknColonEqual)
        .byte .LOBYTE(tknLe), .HIBYTE(tknLe)
        .byte .LOBYTE(tknGe), .HIBYTE(tknGe)
        .byte .LOBYTE(tknNe), .HIBYTE(tknNe)
        .byte .LOBYTE(tknDotDot), .HIBYTE(tknDotDot)
        .byte .LOBYTE(tknBang), .HIBYTE(tknBang)
        .byte .LOBYTE(tknAmpersand), .HIBYTE(tknAmpersand)
        .byte .LOBYTE(tknLShift), .HIBYTE(tknLShift)
        .byte .LOBYTE(tknRShift), .HIBYTE(tknRShift)
        .byte .LOBYTE(tknAt), .HIBYTE(tknAt)
        .byte .LOBYTE(tknAND), .HIBYTE(tknAND)
        .byte .LOBYTE(tknARRAY), .HIBYTE(tknARRAY)
        .byte .LOBYTE(tknBEGIN), .HIBYTE(tknBEGIN)
        .byte .LOBYTE(tknCASE), .HIBYTE(tknCASE)
        .byte .LOBYTE(tknCONST), .HIBYTE(tknCONST)
        .byte .LOBYTE(tknDIV), .HIBYTE(tknDIV)
        .byte .LOBYTE(tknDO), .HIBYTE(tknDO)
        .byte .LOBYTE(tknDOWNTO), .HIBYTE(tknDOWNTO)
        .byte .LOBYTE(tknELSE), .HIBYTE(tknELSE)
        .byte .LOBYTE(tknEND), .HIBYTE(tknEND)
        .byte .LOBYTE(tknFILE), .HIBYTE(tknFILE)
        .byte .LOBYTE(tknFOR), .HIBYTE(tknFOR)
        .byte .LOBYTE(tknFUNCTION), .HIBYTE(tknFUNCTION)
        .byte .LOBYTE(tknGOTO), .HIBYTE(tknGOTO)
        .byte .LOBYTE(tknIF), .HIBYTE(tknIF)
        .byte .LOBYTE(tknIMPLEMENTATION), .HIBYTE(tknIMPLEMENTATION)
        .byte .LOBYTE(tknIN), .HIBYTE(tknIN)
        .byte .LOBYTE(tknINTERFACE), .HIBYTE(tknINTERFACE)
        .byte .LOBYTE(tknLABEL), .HIBYTE(tknLABEL)
        .byte .LOBYTE(tknMOD), .HIBYTE(tknMOD)
        .byte .LOBYTE(tknNIL), .HIBYTE(tknNIL)
        .byte .LOBYTE(tknNOT), .HIBYTE(tknNOT)
        .byte .LOBYTE(tknOF), .HIBYTE(tknOF)
        .byte .LOBYTE(tknOR), .HIBYTE(tknOR)
        .byte .LOBYTE(tknXOR), .HIBYTE(tknXOR)
        .byte .LOBYTE(tknPACKED), .HIBYTE(tknPACKED)
        .byte .LOBYTE(tknPROCEDURE), .HIBYTE(tknPROCEDURE)
        .byte .LOBYTE(tknPROGRAM), .HIBYTE(tknPROGRAM)
        .byte .LOBYTE(tknRECORD), .HIBYTE(tknRECORD)
        .byte .LOBYTE(tknREPEAT), .HIBYTE(tknREPEAT)
        .byte .LOBYTE(tknSET), .HIBYTE(tknSET)
        .byte .LOBYTE(tknTEXT), .HIBYTE(tknTEXT)
        .byte .LOBYTE(tknTHEN), .HIBYTE(tknTHEN)
        .byte .LOBYTE(tknTO), .HIBYTE(tknTO)
        .byte .LOBYTE(tknTYPE), .HIBYTE(tknTYPE)
        .byte .LOBYTE(tknUNIT), .HIBYTE(tknUNIT)
        .byte .LOBYTE(tknUNTIL), .HIBYTE(tknUNTIL)
        .byte .LOBYTE(tknUSES), .HIBYTE(tknUSES)
        .byte .LOBYTE(tknVAR), .HIBYTE(tknVAR)
        .byte .LOBYTE(tknWHILE), .HIBYTE(tknWHILE)
        .byte .LOBYTE(tknWITH), .HIBYTE(tknWITH)

.bss

memBuf: .res 4
buf: .res 4

.code

.proc dumpTokens
    lda #<sourceFn
    ldx #>sourceFn
    jsr handleTokenize
    stq memBuf

    stq ptr1
    lda #0
    ldx #0
    jsr setMemBufPos

L1: ldq memBuf
    jsr isMemBufAtEnd
    bne :+
    jmp L9

    ; Read the next token
:   lda #<tokenCode
    ldx #>tokenCode
    ldy #1
    jsr readBytes

    lda tokenCode
    cmp #tzToken
    bne :+
    jsr showToken
    bra L1
:   cmp #tzIdentifier
    bne :+
    jsr showIdentifier
    bra L1
:   cmp #tzString
    bne :+
    jsr showString
    bra L1
:   cmp #tzByte
    bne :+
    jsr showNumber
    bra L1
:   cmp #tzWord
    bne :+
    jsr showNumber
    bra L1
:   cmp #tzCardinal
    bne :+
    jsr showNumber
    bra L1
:   cmp #tzLineNum
    bne :+
    jsr showLineNum
    bra L1
:   cmp #tzReal
    bne :+
    jsr showReal
    bra L1
:   jsr showError
    bra L1
L9: rts
.endproc

.proc showIdentifier
    ldx #0
:   lda tknIdentifier,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #' '
    jsr CHROUT

    ; Read the string length from the membuf
    lda #<buf
    ldx #>buf
    ldy #1
    jsr readBytes

    ; Read the string
    lda #<tokenString
    ldx #>tokenString
    ldy buf
    phy
    jsr readBytes

    ; Write the string to the screen
    pla
    sta tmp1
    ldx #0
:   lda tokenString,x
    jsr CHROUT
    inx
    dec tmp1
    bne :-
    lda #13
    jmp CHROUT
.endproc

.proc showError
    ldx #0
:   lda errorStr,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #13
    jmp CHROUT
.endproc

.proc showLineNum
    ldx #0
:   lda lineNumStr,x
    beq :+
    jsr CHROUT
    inx
    bne :-

:   lda #<currentLineNumber
    ldx #>currentLineNumber
    ldy #2
    jsr readBytes
    lda currentLineNumber
    sta intOp1
    lda currentLineNumber+1
    sta intOp1+1
    lda #<tokenString
    ldx #>tokenString
    jsr writeInt16
    ldx #0
:   lda tokenString,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #13
    jmp CHROUT
.endproc

.proc showReal
    ldx #0
:   lda realStr,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   ; Read the string length from the membuf
    lda #<buf
    ldx #>buf
    ldy #1
    jsr readBytes

    ; Read the string
    lda #<tokenString
    ldx #>tokenString
    ldy buf
    phy
    jsr readBytes

    ; Write the string to the screen
    pla
    sta tmp1
    ldx #0
:   lda tokenString,x
    jsr CHROUT
    inx
    dec tmp1
    bne :-
    lda #13
    jmp CHROUT
.endproc

.proc showNumber
    cmp #tzByte
    beq showByte
    cmp #tzWord
    beq showWord
    jmp showCardinal

    ; Cardinal number
    jmp showCardinal
.endproc

.proc showByte
    lda #<buf
    ldx #>buf
    ldy #1
    jsr readBytes
    ldx #0
:   lda byteStr,x
    beq :+
    jsr CHROUT
    inx
    bne :-

    lda buf
    sta intOp1
    lda #0
    sta intOp1+1
    lda #<tokenString
    ldx #>tokenString
    jsr writeInt16

    ; Write the number string
    ldx #0
:   lda tokenString,x
    beq :+
    jsr CHROUT
    inx
    bne :-

:   ; Read the string length from the membuf
    lda #<buf
    ldx #>buf
    ldy #1
    jsr readBytes

    ; Read the string
    lda #<tokenString
    ldx #>tokenString
    ldy buf
    phy
    jmp readBytes
.endproc

.proc showWord
    lda #<buf
    ldx #>buf
    ldy #2
    jsr readBytes
    ldx #0
:   lda byteStr,x
    beq :+
    jsr CHROUT
    inx
    bne :-

    lda buf
    sta intOp1
    lda buf+1
    sta intOp1+1
    lda #<tokenString
    ldx #>tokenString
    jsr writeInt16

    ; Write the number string
    ldx #0
:   lda tokenString,x
    beq :+
    jsr CHROUT
    inx
    bne :-

:   ; Read the string length from the membuf
    lda #<buf
    ldx #>buf
    ldy #1
    jsr readBytes

    ; Read the string
    lda #<tokenString
    ldx #>tokenString
    ldy buf
    phy
    jmp readBytes
.endproc

.proc showCardinal
    lda #<buf
    ldx #>buf
    ldy #4
    jsr readBytes
    ldx #0
:   lda cardinalStr,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   ; Read the string length from the membuf
    lda #<buf
    ldx #>buf
    ldy #1
    jsr readBytes

    ; Read the string
    lda #<tokenString
    ldx #>tokenString
    ldy buf
    phy
    jsr readBytes

    ; Write the string to the screen
    pla
    sta tmp1
    ldx #0
:   lda tokenString,x
    jsr CHROUT
    inx
    dec tmp1
    bne :-
    lda #13
    jmp CHROUT
.endproc

.proc showString
    ldx #0
:   lda tknString,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #' '
    jsr CHROUT

    ; Read the string length from the membuf
    lda #<buf
    ldx #>buf
    ldy #1
    jsr readBytes

    ; Read the string
    lda #<tokenString
    ldx #>tokenString
    ldy buf
    phy
    jsr readBytes

    ; Write the string to the screen
    pla
    sta tmp1
    ldx #0
:   lda tokenString,x
    jsr CHROUT
    inx
    dec tmp1
    bne :-
    lda #13
    jmp CHROUT
.endproc

.proc showToken
    ldx #0
:   lda tokenStr,x
    beq :+
    jsr CHROUT
    inx
    bne :-

    ; Read the token code
:   lda #<buf
    ldx #>buf
    ldy #1
    jsr readBytes
    lda buf

    ; Show the token string
    asl a
    tax
    lda tokens,x
    sta ptr1
    lda tokens+1,x
    sta ptr1+1
    ldy #0
:   lda (ptr1),y
    beq :+
    jsr CHROUT
    iny
    bne :-
:   lda #13
    jmp CHROUT
.endproc

; Reads bytes from the membuf
; Caller's buffer in A/X
; Number of bytes to read in Y
.proc readBytes
    sta ptr2
    stx ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    phy
    ldq memBuf
    stq ptr1
    pla
    ldx #0
    jmp readFromMemBuf
.endproc
