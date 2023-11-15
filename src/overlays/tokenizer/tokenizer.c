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
 * TODO: Remove membuf's dependency on int16 and float shared routines.
 * 
 * TODO: Move testing code from shared code in parsertest to the parsertest overlay.
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
 * tzInteger
 *    The tzInteger code is followed by the two-byte integer value.
 *    This is followed by a one-byte integer string length then the
 *    integer as a string.
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
                if (tokenType == tyInteger) {
                    tzType = tzInteger;
                    writeToMemBuf(Icode, &tzType, 1);
                    writeToMemBuf(Icode, &tokenValue.integer, 2);
                } else {
                    tzType = tzReal;
                    writeToMemBuf(Icode, &tzType, 1);
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
