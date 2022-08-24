/**
 * icode.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Functions for intermediate code.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdlib.h>
#include <string.h>
#include <icode.h>
#include <error.h>
#include <scanner.h>

const int codeSegmentSize = 1024;

static const char *symbolStrings[] = {
    NULL,
    NULL, NULL, NULL, NULL, NULL,

    "^", "*", "(", ")", "-", "+",
    "=", "[", "]", ":", ";", "<",
    ">", ",", ".", "/", ":=", "<=", ">=",
    "<>", "..",

    "and", "array", "begin", "case", "const", "div",
    "do", "downto", "else", "end", "file", "for", "function",
    "goto", "if", "in", "label", "mod", "nil", "not", "of", "or",
    "packed", "procedure", "program", "record", "repeat", "set",
    "then", "to", "type", "until", "var", "while", "with",
};

static char extractSymtabNode(ICODE *Icode);

const TTokenCode mcLineMarker = ((TTokenCode) 127);

void checkIcodeBounds(ICODE *Icode, int size)
{
    if (Icode->cursor + size > &Icode->pCode[codeSegmentSize]) {
        Error(errCodeSegmentOverflow);
        abortTranslation(abortCodeSegmentOverflow);
    }
}

void freeIcode(ICODE *Icode)
{
    free(Icode->pCode);
    free(Icode);
}

unsigned getCurrentIcodeLocation(ICODE *Icode)
{
    return Icode->cursor - Icode->pCode;
}

TOKEN *getNextTokenFromIcode(ICODE *Icode)
{
    char code;
    TTokenCode tc;

    // Loop to process any line markers
    // and extract the next token code.
    do {
        // First read the token
        memcpy(&code, Icode->cursor, sizeof(char));
        Icode->cursor += sizeof(char);
        tc = (TTokenCode) code;

        // If it's a line marker, extract the line number.
        if (tc == mcLineMarker) {
            short number;
            memcpy(&number, Icode->cursor, sizeof(short));
            currentLineNumber = number;
            Icode->cursor += sizeof(short);
        }
    } while (tc == mcLineMarker);

    // Determine the token class, based on the token code.
    switch (tc) {
        case tcNumber:
        case tcIdentifier:
        case tcString:
            extractSymtabNode(Icode);
            memset(Icode->token.string, 0, sizeof(Icode->token.string));
            retrieveChunk(Icode->symtabNode.nameChunkNum, (unsigned char *)Icode->token.string);
            break;

        default:
            // Special token or reserved word
            // Icode->pNode = NULL;
            strcpy(Icode->token.string, symbolStrings[code]);
            break;
    }

    Icode->token.code = tc;
    return &Icode->token;
}

void gotoIcodePosition(ICODE *Icode, unsigned position)
{
    Icode->cursor = Icode->pCode + position;
}

static char extractSymtabNode(ICODE *Icode)
{
    CHUNKNUM chunkNum;

    memcpy(&chunkNum, Icode->cursor, sizeof(CHUNKNUM));
    Icode->cursor += sizeof(CHUNKNUM);

    return retrieveChunk(chunkNum, (unsigned char *)&Icode->symtabNode);
}

void insertLineMarker(ICODE *Icode)
{
    char code, lastCode;
    short number;

    if (errorCount > 0) {
        return;
    }

    // Remember the last appended token code
    Icode->cursor -= sizeof(char);
    memcpy(&lastCode, Icode->cursor, sizeof(char));

    // Insert a line marker code
    code = mcLineMarker;
    number = currentLineNumber;
    checkIcodeBounds(Icode, sizeof(char) + sizeof(short));
    memcpy(Icode->cursor, &code, sizeof(char));
    Icode->cursor += sizeof(char);
    memcpy(Icode->cursor, &number, sizeof(short));
    Icode->cursor += sizeof(short);

    // Re-append the last token code
    memcpy(Icode->cursor, &lastCode, sizeof(char));
    Icode->cursor += sizeof(char);
}

ICODE *makeIcode(void)
{
    ICODE *Icode = malloc(sizeof(ICODE));
    if (Icode == NULL) {
        abortTranslation(abortOutOfMemory);
    }

    Icode->pCode = malloc(codeSegmentSize);
    if (Icode->pCode == NULL) {
        abortTranslation(abortOutOfMemory);
    }
    Icode->cursor = Icode->pCode;

    return Icode;
}

ICODE *makeIcodeFrom(ICODE *other)
{
    int length;
    ICODE *Icode;

    length = (int)(other->cursor - other->pCode);

    Icode = malloc(sizeof(ICODE));
    if (Icode == NULL) {
        abortTranslation(abortOutOfMemory);
    }

    Icode->pCode = malloc(length);
    if (Icode->pCode == NULL) {
        abortTranslation(abortOutOfMemory);
    }

    memcpy(Icode->pCode, other->pCode, length);
    Icode->cursor = Icode->pCode;

    return Icode;
}

void putSymtabNodeToIcode(ICODE *Icode, SYMTABNODE *pNode)
{
    if (errorCount > 0) {
        return;
    }

    checkIcodeBounds(Icode, sizeof(CHUNKNUM));
    memcpy(Icode->cursor, &pNode->nodeChunkNum, sizeof(CHUNKNUM));
    Icode->cursor += sizeof(CHUNKNUM);
}

void putTokenToIcode(ICODE *Icode, TTokenCode tc)
{
    char code;

    if (errorCount > 0) {
        return;
    }

    code = tc;
    checkIcodeBounds(Icode, sizeof(char));
    memcpy(Icode->cursor, &code, sizeof(char));
    Icode->cursor += sizeof(char);
}

void resetIcodePosition(ICODE *Icode)
{
    Icode->cursor = Icode->pCode;
}

