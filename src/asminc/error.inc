;;;
 ; error.inc
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; Error constants
 ; 
 ; Copyright (c) 2024
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

abortInvalidCommandLineArgs = 256-1
abortSourceFileOpenFailed   = 256-2
abortIFormFileOpenFailed    = 256-3
abortAssemblyFileOpenFailed = 256-4
abortTooManySyntaxErrors    = 256-5
abortStackOverflow          = 256-6
abortCodeSegmentOverflow    = 256-7
abortNestingTooDeep         = 256-8
abortRuntimeError           = 256-9
abortUnimplementedFeature   = 256-10
abortOutOfMemory            = 256-11
abortSourceLineTooLong      = 256-12
abortSourceFileReadFailed   = 256-13
numAbortErrors              = 13

errNone = 0
errUnrecognizable = 1
errTooMany = 2
errUnexpectedEndOfFile = 3
errInvalidNumber = 4
errTooManyDigits = 5
errIntegerOutOfRange = 6
errMissingRightParen = 7
errInvalidExpression = 8
errInvalidAssignment = 9
errMissingIdentifier = 10
errMissingColonEqual = 11
errUndefinedIdentifier = 12
errStackOverflow = 13
errInvalidStatement = 14
errUnexpectedToken = 15
errMissingSemicolon = 16
errMissingComma = 17
errMissingDO = 18
errMissingUNTIL = 19
errMissingTHEN = 20
errInvalidFORControl = 21
errMissingOF = 22
errInvalidConstant = 23
errMissingConstant = 24
errMissingColon = 25
errMissingEND = 26
errMissingTOorDOWNTO = 27
errRedefinedIdentifier = 28
errMissingEqual = 29
errInvalidType = 30
errNotATypeIdentifier = 31
errInvalidSubrangeType = 32
errNotAConstantIdentifier = 33
errMissingDotDot = 34
errIncompatibleTypes = 35
errInvalidTarget = 36
errInvalidIdentifierUsage = 37
errIncompatibleAssignment = 38
errMinGtMax = 39
errMissingLeftBracket = 40
errMissingRightBracket = 41
errInvalidIndexType = 42
errMissingBEGIN = 43
errMissingPeriod = 44
errTooManySubscripts = 45
errInvalidField = 46
errNestingTooDeep = 47
errMissingPROGRAM = 48
errAlreadyForwarded = 49
errWrongNumberOfParams = 50
errInvalidVarParm = 51
errNotARecordVariable = 52
errMissingVariable = 53
errCodeSegmentOverflow = 54
errUnimplementedFeature = 55
errIdentifierTooLong = 56
numParserErrors = 57

rteNone = 0
rteStackOverflow = 1
rteValueOutOfRange = 2
rteInvalidCaseValue = 3
rteDivisionByZero = 4
rteInvalidFunctionArgument = 5
rteInvalidUserInput = 6
rteUnimplementedRuntimeFeature = 7
rteOutOfMemory = 8
rteStringOverflow = 9
rteInvalidFileHandle = 10
rteFileOpenFailed = 11
rteFileIOFailed = 12
