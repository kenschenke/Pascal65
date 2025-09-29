.include "tokenizer.inc"

.export tlAddOps, tlColonEqual, tlDeclarationFollow, tlDeclarationStart
.export tlEnumConstFollow, tlEnumConstStart
.export tlExpressionFollow, tlExpressionStart, tlFieldDeclFollow
.export tlFormalParamsFollow, tlGlobalDirectives, tlHeaderFollow
.export tlIdentifierFollow, tlIdentifierStart, tlMulOps, tlProcFuncStart
.export tlProgProcIdFollow, tlProgramEnd, tlRelOps, tlStatementStart
.export tlStatementFollow, tlSublistFollow, tlUnaryOps

.data

tlAddOps: .byte tcPlus, tcMinus, tcOR, tcXOR, tcLShift, tcRShift, tcDummy
tlColonEqual: .byte tcColonEqual, tcDummy
tlDeclarationFollow: .byte tcSemicolon, tcIdentifier, tcDummy
tlDeclarationStart: .byte tcCONST, tcTYPE, tcVAR, tcPROCEDURE, tcFUNCTION, tcDummy
tlEnumConstFollow: .byte tcComma, tcIdentifier, tcRParen, tcSemicolon, tcDummy
tlEnumConstStart: .byte tcIdentifier, tcDummy
tlExpressionFollow: .byte tcComma, tcRParen, tcRBracket, tcColon, tcTHEN, tcTO, tcDOWNTO, tcDO, tcOF, tcDummy
tlExpressionStart: .byte tcPlus, tcMinus, tcIdentifier, tcNumber, tcString, tcNOT, tcLParen, tcAt, tcDummy
tlFieldDeclFollow: .byte tcSemicolon, tcIdentifier, tcEND, tcDummy
tlFormalParamsFollow: .byte tcRParen, tcSemicolon, tcDummy
tlGlobalDirectives: .byte tcSTACKSIZE, tcDummy
tlHeaderFollow: .byte tcSemicolon, tcDummy
tlIdentifierFollow: .byte tcComma, tcIdentifier, tcColon, tcSemicolon, tcDummy
tlIdentifierStart: .byte tcIdentifier, tcDummy
tlMulOps: .byte tcStar, tcSlash, tcDIV, tcMOD, tcAND, tcAmpersand, tcBang, tcDummy
tlProcFuncStart: .byte tcPROCEDURE, tcFUNCTION, tcDummy
tlProgProcIdFollow: .byte tcLParen, tcColon, tcSemicolon, tcDummy
tlProgramEnd: .byte tcPeriod, tcDummy
tlRelOps: .byte tcEqual, tcNe, tcLt, tcGt, tcLe, tcGe, tcDummy
tlStatementStart: .byte tcBEGIN, tcCASE, tcFOR, tcREPEAT, tcWHILE, tcIdentifier, tcDummy
tlStatementFollow: .byte tcSemicolon, tcPeriod, tcEND, tcELSE, tcUNTIL, tcDummy
tlSublistFollow: .byte tcColon, tcDummy
tlUnaryOps: .byte tcPlus, tcMinus, tcDummy
