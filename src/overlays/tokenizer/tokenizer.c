#include <tokenizer.h>
#include <membuf.h>
#include <error.h>
#include <scanner.h>
#include <string.h>

/**
 * The tokenizer creates a membuf to store the tokenized code.  In addition
 * to the Pascal language tokens such as tcSemicolon or tcIf, identifiers and
 * literals are stored in the intermediate code like this:
 * 
 * REWRITE: The tokenizer needs to create the symbol table nodes and populate
 * with enough information for the parser to add them to a symbol table.  This
 * would allow node creation code to be moved into the tokenizer overlay.
 * 
 * REWRITE: initPredefinedTypes can happen in the tokenizer, maybe in a
 * initTokenizer function.
 * 
 * TODO: Remove membuf's dependency on int16 and float shared routines.
 * 
 * TODO: Move testing code from shared code in parsertest to the parsertest overlay.
 * 
 * tzIdentifier
 *    The tzIdentifier code is followed by the two-byte chunk number
 *    containing the indentifier name.  Identifiers are limited to 22
 *    characters in length and thus fit in one chunk.
 * 
 * tzToken
 *    The tzToken code is followed by the one-byte TTokenCode value.
 * 
 * tzInteger
 *    The tzInteger code is followed by the two-byte integer value.
 * 
 * tzReal
 *    The tzReal code is followed by the four-byte real value.
 * 
 * tzChar
 *    The tzChar code is followed by the one-byte character value.
 * 
 * tzString
 *    The tzString code is followed by a two-byte integer string
 *    length followed by the string value (not null-terminated).
 */

static void writeTzIdentifier(CHUNKNUM Icode);

CHUNKNUM tokenize(const char *filename) {
    CHUNKNUM Icode, stringChunk;
    TTokenizerCode tzType;
    
    allocMemBuf(&Icode);

    tinOpen(filename, abortSourceFileOpenFailed);

    while (!isBufferEof()) {
        getNextToken();

        switch (tokenCode) {
            case tcIdentifier: {
                char chunk[CHUNK_LEN];
                CHUNKNUM identChunk;

                if (strlen(tokenString) > CHUNK_LEN) {
                    Error(errIdentifierTooLong);
                    tokenString[CHUNK_LEN] = 0;
                }

                allocChunk(&identChunk);
                memset(chunk, 0, CHUNK_LEN);
                memcpy(chunk, tokenString, strlen(tokenString));
                storeChunk(identChunk, (unsigned char *)chunk);

                tzType = tzIdentifier;
                writeToMemBuf(Icode, &tzType, 1);
                writeToMemBuf(Icode, &identChunk, 2);
                break;
            }

            case tcNumber:
                if (tokenType == tyInteger) {
                    tzType = tzInteger;
                    writeToMemBuf(Icode, &tzType, 1);
                    writeToMemBuf(Icode, &tokenValue.integer, 2);
                } else {
                    tzType = tzReal;
                    writeToMemBuf(Icode, &tzType, 1);
                    writeToMemBuf(Icode, &tokenValue.real, 4);
                }
                break;
            
            case tcString: {
                int len = strlen(tokenString);
                if (len == 3) {
                    tzType = tzChar;
                    writeToMemBuf(Icode, &tzType, 1);
                    writeToMemBuf(Icode, tokenString + 1, 1);
                } else {
                    allocMemBuf(&stringChunk);

                    len -= 2;
                    reserveMemBuf(stringChunk, len);
                    copyToMemBuf(stringChunk, tokenString + 1, 0, len);

                    tzType = tzString;
                    writeToMemBuf(Icode, &len, 2);
                    writeToMemBuf(Icode, &stringChunk, 2);
                }
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
