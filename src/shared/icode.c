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
static void initIcodeChunk(ICODE *Icode);
static void pullDataFromIcode(ICODE *Icode, unsigned char *data, unsigned len);
static void putDataToIcode(ICODE *Icode, unsigned char *data, unsigned len);
static void retrieveIcodeChunk(ICODE *Icode, CHUNKNUM chunkNum);

const TTokenCode mcLineMarker = ((TTokenCode) 127);

void checkIcodeBounds(ICODE *Icode, int size)
{
    if (Icode->posGlobal + size > codeSegmentSize) {
        Error(errCodeSegmentOverflow);
        abortTranslation(abortCodeSegmentOverflow);
    }
}

void freeIcode(ICODE *Icode)
{
    Icode->currentChunkNum = Icode->firstChunkNum;

    while (Icode->currentChunkNum) {
        if (retrieveChunk(Icode->currentChunkNum, (unsigned char *)&Icode->chunk) == 0) {
            return;
        }
        freeChunk(Icode->currentChunkNum);
        Icode->currentChunkNum = Icode->chunk.nextChunk;
    }

    free(Icode);
}

unsigned getCurrentIcodeLocation(ICODE *Icode)
{
    return Icode->posGlobal;
}

TOKEN *getNextTokenFromIcode(ICODE *Icode)
{
    char code;
    TTokenCode tc;

    // Loop to process any line markers
    // and extract the next token code.
    do {
        // First read the token
        pullDataFromIcode(Icode, (unsigned char *)&code, sizeof(char));
        tc = (TTokenCode) code;

        // If it's a line marker, extract the line number.
        if (tc == mcLineMarker) {
            short number;
            pullDataFromIcode(Icode, (unsigned char *)&number, sizeof(short));
            currentLineNumber = number;
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
    if (Icode->currentChunkNum) {
        if (storeChunk(Icode->currentChunkNum, (unsigned char *)&Icode->chunk) == 0) {
            return;
        }
    }

    Icode->posGlobal = 0;
    Icode->posChunk = 0;
    Icode->currentChunkNum = Icode->firstChunkNum;

    while (1) {
        if (retrieveChunk(Icode->currentChunkNum, (unsigned char *)&Icode->chunk) == 0) {
            return;
        }

        if (position < ICODE_CHUNK_LEN) {
            Icode->posGlobal += position;
            Icode->posChunk = position;
            break;
        }

        Icode->posGlobal += ICODE_CHUNK_LEN;
        position -= ICODE_CHUNK_LEN;
        Icode->currentChunkNum = Icode->chunk.nextChunk;
    }
}

static char extractSymtabNode(ICODE *Icode)
{
    CHUNKNUM chunkNum;

    pullDataFromIcode(Icode, (unsigned char *)&chunkNum, sizeof(CHUNKNUM));

    return retrieveChunk(chunkNum, (unsigned char *)&Icode->symtabNode);
}

static void initIcodeChunk(ICODE *Icode) {
    CHUNKNUM chunkNum;

    if (allocChunk(&chunkNum) == 0) {
        Error(errCodeSegmentOverflow);
        abortTranslation(abortCodeSegmentOverflow);
        return;
    }

    if (Icode->firstChunkNum == 0) {
        Icode->firstChunkNum = chunkNum;
    } else if (Icode->currentChunkNum) {
        Icode->chunk.nextChunk = chunkNum;
        if (storeChunk(Icode->currentChunkNum, (unsigned char *)&Icode->chunk) == 0) {
            Error(errCodeSegmentOverflow);
            abortTranslation(abortCodeSegmentOverflow);
            return;
        }
    }

    memset(&Icode->chunk, 0, sizeof(ICODE_CHUNK));
    Icode->currentChunkNum = chunkNum;
    Icode->posChunk = 0;
}

void insertLineMarker(ICODE *Icode)
{
    char code, lastCode;
    short number;

    if (errorCount > 0) {
        return;
    }

    // Remember the last appended token code
    if (Icode->posChunk == 0) {
        if (Icode->posGlobal == 0) {
            // Already at the start.
            return;
        }
        // We're already at the starting byte of this chunk.
        // We have to back up the previous chunk's last position.
        gotoIcodePosition(Icode, Icode->posGlobal - 1);
    } else {
        Icode->posChunk--;
        Icode->posGlobal--;
    }
    memcpy(&lastCode, Icode->chunk.data + Icode->posChunk, sizeof(char));

    // Insert a line marker code
    code = mcLineMarker;
    number = currentLineNumber;
    checkIcodeBounds(Icode, sizeof(char) + sizeof(short));
    putDataToIcode(Icode, (unsigned char *)&code, sizeof(char));
    putDataToIcode(Icode, (unsigned char *)&number, sizeof(short));

    // Re-append the last token code
    putDataToIcode(Icode, (unsigned char *)&lastCode, sizeof(char));
}

ICODE *makeIcode(void)
{
    ICODE *Icode = malloc(sizeof(ICODE));
    if (Icode == NULL) {
        abortTranslation(abortOutOfMemory);
    }

    Icode->currentChunkNum = 0;
    Icode->firstChunkNum = 0;
    Icode->posGlobal = 0;
    Icode->posChunk = 0;

    return Icode;
}

#if 0
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
#endif

static void pullDataFromIcode(ICODE *Icode, unsigned char *data, unsigned len) {
    unsigned toCopy;

    if (Icode->currentChunkNum == 0) {
        if (Icode->firstChunkNum == 0) {
            return;
        }

        retrieveIcodeChunk(Icode, Icode->firstChunkNum);
        Icode->posGlobal = 0;
    }

    while (len) {
        toCopy = len > ICODE_CHUNK_LEN - Icode->posChunk
            ? ICODE_CHUNK_LEN - Icode->posChunk : len;

        if (toCopy) {
            memcpy(data, Icode->chunk.data + Icode->posChunk, toCopy);
            Icode->posChunk += toCopy;
            Icode->posGlobal += toCopy;
            data += toCopy;
            len -= toCopy;
        }

        if (len) {
            if (Icode->chunk.nextChunk == 0) {
                return;
            }

            retrieveIcodeChunk(Icode, Icode->chunk.nextChunk);
        }
    }
}

static void putDataToIcode(ICODE *Icode, unsigned char *data, unsigned len) {
    unsigned toCopy;

    if (Icode->firstChunkNum == 0) {
        initIcodeChunk(Icode);
    }

    while (len) {
        toCopy = len > ICODE_CHUNK_LEN - Icode->posChunk
            ? ICODE_CHUNK_LEN - Icode->posChunk : len;
        
        if (toCopy) {
            memcpy(Icode->chunk.data + Icode->posChunk, data, toCopy);
            Icode->posChunk += toCopy;
            Icode->posGlobal += toCopy;
            data += toCopy;
            len -= toCopy;
        }

        if (len) {
            initIcodeChunk(Icode);
        }
    }
}

void putSymtabNodeToIcode(ICODE *Icode, SYMTABNODE *pNode)
{
    if (errorCount > 0) {
        return;
    }

    checkIcodeBounds(Icode, sizeof(CHUNKNUM));
    putDataToIcode(Icode, (unsigned char *)&pNode->nodeChunkNum, sizeof(CHUNKNUM));
}

void putTokenToIcode(ICODE *Icode, TTokenCode tc)
{
    char code;

    if (errorCount > 0) {
        return;
    }

    code = tc;
    checkIcodeBounds(Icode, sizeof(char));
    putDataToIcode(Icode, (unsigned char *)&code, sizeof(char));
}

void resetIcodePosition(ICODE *Icode)
{
    if (Icode->currentChunkNum) {
        storeChunk(Icode->currentChunkNum, (unsigned char *)&Icode->chunk);
    }

    Icode->currentChunkNum = 0;
    Icode->posGlobal = 0;
    Icode->posChunk = 0;
}

static void retrieveIcodeChunk(ICODE *Icode, CHUNKNUM chunkNum) {
    if (retrieveChunk(chunkNum, (unsigned char *)&Icode->chunk) == 0) {
        return;
    }

    Icode->posChunk = 0;
    Icode->currentChunkNum = chunkNum;
}
