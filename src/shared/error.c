/**
 * error.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Code for raising errors.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>

#include <error.h>
#include <ovrlcommon.h>
#include <common.h>

unsigned errorCount = 0;
unsigned errorArrowFlag = 1;
unsigned errorArrowOffset = 8;

static char *abortMsg[] = {
    NULL,
    "Invalid command line arguments",
    "Failed to open source file",
    "Failed to open intermediate form file",
    "Failed to open assembly file",
    "Too many syntax errors",
    "Stack overflow",
    "Code segment overflow",
    "Nesting too deep",
    "Runtime error",
    "Unimplemented feature",
    "Out of memory",
    "Source file line too long",
    "Source file read failed",
};

static char *errorMessages[] = {
    "No error",
    "Unrecognizable input",
    "Too many syntax errors",
    "Unexpected end of file",
    "Invalid number",
    "Too many digits",
    "Integer literal out of range",
    "Missing )",
    "Invalid expression",
    "Invalid assignment statement",
    "Missing identifier",
    "Missing :=",
    "Undefined identifier",
    "Stack overflow",
    "Invalid statement",
    "Unexpected token",
    "Missing ;",
    "Missing ,",
    "Missing DO",
    "Missing UNTIL",
    "Missing THEN",
    "Invalid FOR control variable",
    "Missing OF",
    "Invalid constant",
    "Missing constant",
    "Missing :",
    "Missing END",
    "Missing TO or DOWNTO",
    "Redefined identifier",
    "Missing =",
    "Invalid type",
    "Not a type identifier",
    "Invalid subrange type",
    "Not a constant identifier",
    "Missing ..",
    "Incompatible types",
    "Invalid assignment target",
    "Invalid identifier usage",
    "Incompatible assignment",
    "Min limit greater than max limit",
    "Missing [",
    "Missing ]",
    "Invalid index type",
    "Missing BEGIN",
    "Missing .",
    "Too many subscripts",
    "Invalid field",
    "Nesting too deep",
    "Missing PROGRAM",
    "Already specified in FORWARD",
    "Wrong number of actual parameters",
    "Invalid VAR parameter",
    "Not a record variable",
    "Missing variable",
    "Code segment overflow",
    "Unimplemented feature",
};

static const char *runtimeErrorMessages[] = {
    "No runtime error",
    "Runtime stack overflow",
    "Value out of range",
    "Invalid CASE expression value",
    "Division by zero",
    "Invalid standard function argument",
    "Invalid user input",
    "Unimplemented runtime feature",
    "Out of memory",
};

void abortTranslation(TAbortCode ac)
{
    logFatalError(abortMsg[-ac]);
    isFatalError = 1;
}

void Error(TErrorCode ec)
{
    const int maxSyntaxErrors = 25;

    logError(errorMessages[ec], 0);
    if (++errorCount > maxSyntaxErrors) {
        abortTranslation(abortTooManySyntaxErrors);
    }
}

void runtimeError(TRuntimeErrorCode ec)
{
    logRuntimeError(runtimeErrorMessages[ec], currentLineNumber);
}

