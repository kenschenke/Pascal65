
CH_EOF = $7f

TOKENIZER_BASE = $6000

tokenize = TOKENIZER_BASE

MAX_LINE_LENGTH = 80

; Tokenizer character codes
.enum
    ccLetter
    ccDigit
    ccSpecial
    ccQuote
    ccWhiteSpace
    ccDollar
    ccHash
    ccPercent
    ccEndOfFile
    ccError
.endenum

; Tokenizer codes
.enum
    tzDummy
    tzLineNum
    tzIdentifier
    tzToken
    tzReal
    tzChar
    tzString
    tzByte
    tzWord
    tzCardinal
.endenum

; Pascal token codes
.enum
    tcDummy
    tcIdentifier
    tcNumber
    tcString
    tcEndOfFile
    tcError

    tcBOOLEAN
    tcBYTE
    tcCARDINAL
    tcCHAR
    tcINTEGER
    tcLONGINT
    tcREAL
    tcSTRING
    tcSHORTINT
    tcWORD

    tcFALSE
    tcTRUE

    tcSTACKSIZE

    tcUpArrow
    tcStar
    tcLParen
    tcRParen
    tcMinus
    tcPlus
    tcEqual
    tcLBracket
    tcRBracket
    tcColon
    tcSemicolon
    tcLt
    tcGt
    tcComma
    tcPeriod
    tcSlash
    tcColonEqual
    tcLe
    tcGe
    tcNe
    tcDotDot
    tcBang
    tcAmpersand
    tcLShift
    tcRShift
    tcAt

    tcAND
    tcARRAY
    tcBEGIN
    tcCASE
    tcCONST
    tcDIV
    tcDO
    tcDOWNTO
    tcELSE
    tcEND
    tcFILE
    tcFOR
    tcFUNCTION
    tcGOTO
    tcIF
    tcIMPLEMENTATION
    tcIN
    tcINTERFACE
    tcLABEL
    tcMOD
    tcNIL
    tcNOT
    tcOF
    tcOR
    tcXOR
    tcPACKED
    tcPROCEDURE
    tcPROGRAM
    tcRECORD
    tcREPEAT
    tcSET
    tcTEXT
    tcTHEN
    tcTO
    tcTYPE
    tcUNIT
    tcUNTIL
    tcUSES
    tcVAR
    tcWHILE
    tcWITH
.endenum

; Data Types
.enum
    tyDummy
    tyShortInt  ; -128..127
    tyByte      ; 0..255
    tyInteger   ; -32768..32767
    tyWord      ; 0..65535
    tyLongInt   ; -2147483648..2147483647
    tyCardinal  ; 0..4294967295
    tyReal
    tyCharacter
    tyString
.endenum
