/**
 * tokenizer.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Tokenizer
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <tokenizer.h>
#include <membuf.h>
#include <error.h>
#include <scanner.h>
#include <string.h>
#include <common.h>

/**
 * The tokenizer creates a membuf to store the tokenized code.  In addition
 * to the Pascal language tokens such as tcSemicolon or tcIf, identifiers and
 * literals are stored in the intermediate code like this:
 * 
 * tzIdentifier
 *    The tzIdentifier code is followed by a one-byte integer string
 *    length followed by the string value (not null-terminated).
 * 
 * tzLineNum
 *    This code is followed by the two-byte line number integer.
 * 
 * tzToken
 *    The tzToken code is followed by the one-byte TTokenCode value.
 *
 * tzByte, tzWord, tzCardinal
 *    The code is followed by the one, two, or four-byte integer value.
 *    Integers are always stored as unsigned. This is followed by a
 *    one-byte integer string length then the integer as a string.
 *    The negative sign (if present) is stored as a separate token.
 * 
 * tzReal
 *    This is followed by a one-byte integer string length then the
 *    float as a string.
 * 
 * tzString
 *    The tzString code is followed by a two-byte integer string
 *    length followed by the string value (not null-terminated).
 *    The string is stored with the quotes.
 */

static char directiveHasParam(void);
static void writeTzIdentifier(CHUNKNUM Icode);

// Returns a 1 if the compiler directive has a parameter
static char directiveHasParam(void)
{
    return tokenCode == tcSTACKSIZE ? 1 : 0;
}

// Returns a 1 if the current token is a compiler directive
char isCompilerDirective(void)
{
    return tokenCode == tcSTACKSIZE ? 1 : 0;
}

CHUNKNUM tokenize(const char *filename) {
    char isDirective;     // non-zero if processing a compiler directive
    char directiveParam;  // non-zero if the current loop iteration
                          // is processing a compiler directive param
    CHUNKNUM Icode;
    TTokenizerCode tzType;
    extern char lineNumberChanged;
    
    allocMemBuf(&Icode);

    tinOpen(filename, abortSourceFileOpenFailed);

    isDirective = 0;
    directiveParam = 0;
    while (!isBufferEof()) {
        // If processing a compiler directive but not looking for a parameter,
        // then the tokenizer needs to consume the remainder of the comment block
        // before retrieving the next token.
        if (isDirective && !directiveParam) {
            // Consume characters until *) is reached.
            char ch = getCurrentChar();
            while (ch != eofChar) {
                if (ch == '*') {
                    ch = getChar();
                    if (ch == ')') {
                        getChar();
                        break;
                    }
                }
                ch = getChar();
            }
            isDirective = 0;
        }

        getNextToken();

        if (lineNumberChanged) {
            tzType = tzLineNum;
            writeToMemBuf(Icode, &tzType, 1);
            writeToMemBuf(Icode, &currentLineNumber, 2);
            lineNumberChanged = 0;
        }

        switch (tokenCode) {
            case tcIdentifier:
            case tcString: {
                char len = (char) strlen(tokenString);
                tzType = tokenCode == tcIdentifier ? tzIdentifier : tzString;
                writeToMemBuf(Icode, &tzType, 1);
                writeToMemBuf(Icode, &len, 1);
                writeToMemBuf(Icode, tokenString, len);
                directiveParam = 0;
                break;
            }

            case tcNumber: {
                char len = (char) strlen(tokenString);
                tzType = tokenizerCode;
                writeToMemBuf(Icode, &tzType, 1);
                if (tzType == tzByte) {
                    writeToMemBuf(Icode, &tokenValue.byte, 1);
                } else if (tzType == tzWord) {
                    writeToMemBuf(Icode, &tokenValue.word, 2);
                } else if (tzType == tzCardinal) {
                    writeToMemBuf(Icode, &tokenValue.cardinal, 4);
                }
                writeToMemBuf(Icode, &len, 1);
                writeToMemBuf(Icode, tokenString, len);
                directiveParam = 0;
                break;
            }

            default:
                tzType = tzToken;
                writeToMemBuf(Icode, &tzType, 1);
                writeToMemBuf(Icode, &tokenCode, 1);
                if (isCompilerDirective()) {
                    isDirective = 1;
                    directiveParam = directiveHasParam() ? 1 : 0;
                    tokenCode = 0;
                }
                break;
        }
    }

    tinClose();

    return Icode;
}
