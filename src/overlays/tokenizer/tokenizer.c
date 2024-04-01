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

static void writeTzIdentifier(CHUNKNUM Icode);

CHUNKNUM tokenize(const char *filename) {
    CHUNKNUM Icode;
    TTokenizerCode tzType;
    extern char lineNumberChanged;
    
    allocMemBuf(&Icode);

    tinOpen(filename, abortSourceFileOpenFailed);

    while (!isBufferEof()) {
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
                break;
            }
            
            default:
                tzType = tzToken;
                writeToMemBuf(Icode, &tzType, 1);
                writeToMemBuf(Icode, &tokenCode, 1);
                break;
        }
    }

    tinClose();

    return Icode;
}
