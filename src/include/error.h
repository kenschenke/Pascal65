/**
 * error.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Header for error codes and messages
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef ERROR_H
#define ERROR_H

extern unsigned errorCount;
extern unsigned errorArrowFlag;
extern unsigned errorArrowOffset;

typedef enum {
    abortInvalidCommandLineArgs = -1,
    abortSourceFileOpenFailed   = -2,
    abortIFormFileOpenFailed    = -3,
    abortAssemblyFileOpenFailed = -4,
    abortTooManySyntaxErrors    = -5,
    abortStackOverflow          = -6,
    abortCodeSegmentOverflow    = -7,
    abortNestingTooDeep         = -8,
    abortRuntimeError           = -9,
    abortUnimplementedFeature   = -10,
    abortOutOfMemory            = -11,
    abortSourceLineTooLong      = -12,
    abortSourceFileReadFailed   = -13,
    numAbortErrors              =  13,
} TAbortCode;

void abortTranslation(TAbortCode ac);

typedef enum {
    errNone,
    errUnrecognizable,
    errTooMany,
    errUnexpectedEndOfFile,
    errInvalidNumber,
    errTooManyDigits,
    errIntegerOutOfRange,
    errMissingRightParen,
    errInvalidExpression,
    errInvalidAssignment,
    errMissingIdentifier,
    errMissingColonEqual,
    errUndefinedIdentifier,
    errStackOverflow,
    errInvalidStatement,
    errUnexpectedToken,
    errMissingSemicolon,
    errMissingComma,
    errMissingDO,
    errMissingUNTIL,
    errMissingTHEN,
    errInvalidFORControl,
    errMissingOF,
    errInvalidConstant,
    errMissingConstant,
    errMissingColon,
    errMissingEND,
    errMissingTOorDOWNTO,
    errRedefinedIdentifier,
    errMissingEqual,
    errInvalidType,
    errNotATypeIdentifier,
    errInvalidSubrangeType,
    errNotAConstantIdentifier,
    errMissingDotDot,
    errIncompatibleTypes,
    errInvalidTarget,
    errInvalidIdentifierUsage,
    errIncompatibleAssignment,
    errMinGtMax,
    errMissingLeftBracket,
    errMissingRightBracket,
    errInvalidIndexType,
    errMissingBEGIN,
    errMissingPeriod,
    errTooManySubscripts,
    errInvalidField,
    errNestingTooDeep,
    errMissingPROGRAM,
    errAlreadyForwarded,
    errWrongNumberOfParams,
    errInvalidVarParm,
    errNotARecordVariable,
    errMissingVariable,
    errCodeSegmentOverflow,
    errUnimplementedFeature,
    errIdentifierTooLong,
    numParserErrors,
} TErrorCode;

void Error(TErrorCode ec);

typedef enum {
    rteNone,
    rteStackOverflow,
    rteValueOutOfRange,
    rteInvalidCaseValue,
    rteDivisionByZero,
    rteInvalidFunctionArgument,
    rteInvalidUserInput,
    rteUnimplementedRuntimeFeature,
    rteOutOfMemory,
    numRuntimeErrors,
} TRuntimeErrorCode;

void runtimeError(TRuntimeErrorCode ec);

#endif // end of ERROR_H
