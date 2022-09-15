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

static ICODE cachedIcodeHdr;
static CHUNKNUM cachedIcodeHdrChunkNum;

static ICODE_CHUNK cachedIcodeData;
static CHUNKNUM cachedIcodeDataChunkNum;

static char extractSymtabNode(CHUNKNUM chunkNum, SYMTABNODE *pNode);
static void flushIcodeCache(void);
static void initIcodeChunk(CHUNKNUM chunkNum);
static void loadDataCache(CHUNKNUM chunkNum);
static void loadHeaderCache(CHUNKNUM chunkNum);
static void pullDataFromIcode(CHUNKNUM chunkNum, unsigned char *data, unsigned len);
static void putDataToIcode(CHUNKNUM chunkNum, unsigned char *data, unsigned len);

const TTokenCode mcLineMarker = ((TTokenCode) 127);

void checkIcodeBounds(CHUNKNUM chunkNum, int size)
{
    loadHeaderCache(chunkNum);
    if (cachedIcodeHdr.posGlobal + size > codeSegmentSize) {
        Error(errCodeSegmentOverflow);
        abortTranslation(abortCodeSegmentOverflow);
    }
}

static char extractSymtabNode(CHUNKNUM hdrChunkNum, SYMTABNODE *pNode)
{
    CHUNKNUM chunkNum;

    pullDataFromIcode(hdrChunkNum, (unsigned char *)&chunkNum, sizeof(CHUNKNUM));

    return retrieveChunk(chunkNum, (unsigned char *)pNode);
}

void freeIcode(CHUNKNUM chunkNum)
{
    ICODE_CHUNK dataChunk;

    flushIcodeCache();
    loadHeaderCache(chunkNum);
    cachedIcodeHdr.currentChunkNum = cachedIcodeHdr.firstChunkNum;

    while (cachedIcodeHdr.currentChunkNum) {
        if (retrieveChunk(cachedIcodeHdr.currentChunkNum, (unsigned char *)&dataChunk) == 0) {
            return;
        }
        freeChunk(cachedIcodeHdr.currentChunkNum);
        cachedIcodeHdr.currentChunkNum = dataChunk.nextChunk;
    }

    freeChunk(chunkNum);
    cachedIcodeHdrChunkNum = 0;
    cachedIcodeDataChunkNum = 0;
}

static void flushIcodeCache(void) {
    if (cachedIcodeHdrChunkNum) {
        storeChunk(cachedIcodeHdrChunkNum, (unsigned char *)&cachedIcodeHdr);
        cachedIcodeHdrChunkNum = 0;
    }

    if (cachedIcodeDataChunkNum) {
        storeChunk(cachedIcodeDataChunkNum, (unsigned char *)&cachedIcodeData);
        cachedIcodeDataChunkNum = 0;
    }
}

unsigned getCurrentIcodeLocation(CHUNKNUM chunkNum)
{
    loadHeaderCache(chunkNum);
    return cachedIcodeHdr.posGlobal;
}

void getNextTokenFromIcode(CHUNKNUM chunkNum, TOKEN *pToken, SYMTABNODE *pNode)
{
    char code;
    SYMTABNODE symtabNode;
    TTokenCode tc;

    // Loop to process any line markers
    // and extract the next token code.
    do {
        // First read the token
        pullDataFromIcode(chunkNum, (unsigned char *)&code, sizeof(char));
        tc = (TTokenCode) code;

        // If it's a line marker, extract the line number.
        if (tc == mcLineMarker) {
            short number;
            pullDataFromIcode(chunkNum, (unsigned char *)&number, sizeof(short));
            currentLineNumber = number;
        }
    } while (tc == mcLineMarker);

    // Determine the token class, based on the token code.
    switch (tc) {
        case tcNumber:
        case tcIdentifier:
        case tcString:
            extractSymtabNode(chunkNum, &symtabNode);
            memset(pToken->string, 0, sizeof(pToken->string));
            retrieveChunk(symtabNode.nameChunkNum, (unsigned char *)pToken->string);
            if (pNode) {
                memcpy(pNode, &symtabNode, sizeof(SYMTABNODE));
            }
            break;

        default:
            // Special token or reserved word
            strcpy(pToken->string, symbolStrings[code]);
            break;
    }

    pToken->code = tc;
}

void gotoIcodePosition(CHUNKNUM chunkNum, unsigned position)
{
    loadHeaderCache(chunkNum);

    cachedIcodeHdr.posGlobal = 0;
    cachedIcodeHdr.posChunk = 0;
    cachedIcodeHdr.currentChunkNum = cachedIcodeHdr.firstChunkNum;

    while (1) {
        loadDataCache(cachedIcodeHdr.currentChunkNum);

        if (position < ICODE_CHUNK_LEN) {
            cachedIcodeHdr.posGlobal += position;
            cachedIcodeHdr.posChunk = position;
            break;
        }

        cachedIcodeHdr.posGlobal += ICODE_CHUNK_LEN;
        position -= ICODE_CHUNK_LEN;
        cachedIcodeHdr.currentChunkNum = cachedIcodeData.nextChunk;
    }
}

void initIcodeCache(void) {
    cachedIcodeHdrChunkNum = cachedIcodeDataChunkNum = 0;
}

static void initIcodeChunk(CHUNKNUM hdrChunkNum) {
    CHUNKNUM chunkNum;

    flushIcodeCache();
    loadHeaderCache(hdrChunkNum);

    if (allocChunk(&chunkNum) == 0) {
        Error(errCodeSegmentOverflow);
        abortTranslation(abortCodeSegmentOverflow);
        return;
    }

    if (cachedIcodeHdr.firstChunkNum == 0) {
        cachedIcodeHdr.firstChunkNum = chunkNum;
    } else if (cachedIcodeHdr.currentChunkNum) {
        retrieveChunk(cachedIcodeHdr.currentChunkNum, (unsigned char *)&cachedIcodeData);
        cachedIcodeData.nextChunk = chunkNum;
        if (storeChunk(cachedIcodeHdr.currentChunkNum, (unsigned char *)&cachedIcodeData) == 0) {
            Error(errCodeSegmentOverflow);
            abortTranslation(abortCodeSegmentOverflow);
            return;
        }
    }

    memset(&cachedIcodeData, 0, sizeof(ICODE_CHUNK));
    cachedIcodeHdr.currentChunkNum = chunkNum;
    cachedIcodeHdr.posChunk = 0;
    loadDataCache(chunkNum);
}

void insertLineMarker(CHUNKNUM chunkNum)
{
    char code, lastCode;
    short number;

    if (errorCount > 0) {
        return;
    }

    loadHeaderCache(chunkNum);

    // Remember the last appended token code
    if (cachedIcodeHdr.posChunk == 0) {
        if (cachedIcodeHdr.posGlobal == 0) {
            // Already at the start.
            return;
        }
        // We're already at the starting byte of this chunk.
        // We have to back up the previous chunk's last position.
        gotoIcodePosition(chunkNum, cachedIcodeHdr.posGlobal - 1);
    } else {
        cachedIcodeHdr.posChunk--;
        cachedIcodeHdr.posGlobal--;
    }
    loadDataCache(cachedIcodeHdr.currentChunkNum);
    memcpy(&lastCode, cachedIcodeData.data + cachedIcodeHdr.posChunk, sizeof(char));

    // Insert a line marker code
    code = mcLineMarker;
    number = currentLineNumber;
    checkIcodeBounds(chunkNum, sizeof(char) + sizeof(short));
    putDataToIcode(chunkNum, (unsigned char *)&code, sizeof(char));
    putDataToIcode(chunkNum, (unsigned char *)&number, sizeof(short));

    // Re-append the last token code
    putDataToIcode(chunkNum, (unsigned char *)&lastCode, sizeof(char));
}

static void loadDataCache(CHUNKNUM chunkNum) {
    if (cachedIcodeDataChunkNum != chunkNum) {
        if (cachedIcodeDataChunkNum) {
            storeChunk(cachedIcodeDataChunkNum, (unsigned char *)&cachedIcodeData);
        }

        retrieveChunk(chunkNum, (unsigned char *)&cachedIcodeData);
        cachedIcodeDataChunkNum = chunkNum;
    }
}

static void loadHeaderCache(CHUNKNUM chunkNum) {
    if (cachedIcodeHdrChunkNum != chunkNum) {
        if (cachedIcodeHdrChunkNum) {
            storeChunk(cachedIcodeHdrChunkNum, (unsigned char *)&cachedIcodeHdr);
        }

        retrieveChunk(chunkNum, (unsigned char *)&cachedIcodeHdr);
        cachedIcodeHdrChunkNum = chunkNum;
    }
}

void makeIcode(CHUNKNUM *newChunkNum)
{
    ICODE hdrChunk;

    hdrChunk.currentChunkNum = 0;
    hdrChunk.firstChunkNum = 0;
    hdrChunk.posGlobal = 0;
    hdrChunk.posChunk = 0;

    allocChunk(newChunkNum);
    storeChunk(*newChunkNum, (unsigned char *)&hdrChunk);
}

static void pullDataFromIcode(CHUNKNUM chunkNum, unsigned char *data, unsigned len) {
    unsigned toCopy;

    loadHeaderCache(chunkNum);

    if (cachedIcodeHdr.currentChunkNum == 0 && cachedIcodeHdr.firstChunkNum == 0) {
        return;
    }

    if (cachedIcodeHdr.currentChunkNum == 0) {
        cachedIcodeHdr.currentChunkNum = cachedIcodeHdr.firstChunkNum;
    }

    loadDataCache(cachedIcodeHdr.currentChunkNum);

    while (len) {
        toCopy = len > ICODE_CHUNK_LEN - cachedIcodeHdr.posChunk
            ? ICODE_CHUNK_LEN - cachedIcodeHdr.posChunk : len;

        if (toCopy) {
            memcpy(data, cachedIcodeData.data + cachedIcodeHdr.posChunk, toCopy);
            cachedIcodeHdr.posChunk += toCopy;
            cachedIcodeHdr.posGlobal += toCopy;
            data += toCopy;
            len -= toCopy;
        }

        if (len) {
            if (cachedIcodeData.nextChunk == 0) {
                break;
            }

            cachedIcodeHdr.posChunk = 0;
            cachedIcodeHdr.currentChunkNum = cachedIcodeData.nextChunk;

            loadDataCache(cachedIcodeData.nextChunk);
        }
    }
}

static void putDataToIcode(CHUNKNUM chunkNum, unsigned char *data, unsigned len) {
    unsigned toCopy;

    loadHeaderCache(chunkNum);

    if (cachedIcodeHdr.firstChunkNum == 0) {
        initIcodeChunk(chunkNum);
    } else {
        if (cachedIcodeHdr.currentChunkNum == 0) {
            cachedIcodeHdr.currentChunkNum = cachedIcodeHdr.firstChunkNum;
        }
        loadDataCache(cachedIcodeHdr.currentChunkNum);
    }
    
    while (len) {
        toCopy = len > ICODE_CHUNK_LEN - cachedIcodeHdr.posChunk
            ? ICODE_CHUNK_LEN - cachedIcodeHdr.posChunk : len;
        
        if (toCopy) {
            memcpy(cachedIcodeData.data + cachedIcodeHdr.posChunk, data, toCopy);
            cachedIcodeHdr.posChunk += toCopy;
            cachedIcodeHdr.posGlobal += toCopy;
            data += toCopy;
            len -= toCopy;
        }

        if (len) {
            initIcodeChunk(chunkNum);
        }
    }
}

void putSymtabNodeToIcode(CHUNKNUM chunkNum, SYMTABNODE *pNode)
{
    if (errorCount > 0) {
        return;
    }

    checkIcodeBounds(chunkNum, sizeof(CHUNKNUM));
    putDataToIcode(chunkNum, (unsigned char *)&pNode->nodeChunkNum, sizeof(CHUNKNUM));
}

void putTokenToIcode(CHUNKNUM chunkNum, TTokenCode tc)
{
    char code;

    if (errorCount > 0) {
        return;
    }

    code = tc;
    checkIcodeBounds(chunkNum, sizeof(char));
    putDataToIcode(chunkNum, (unsigned char *)&code, sizeof(char));
}

void resetIcodePosition(CHUNKNUM chunkNum)
{
    loadHeaderCache(chunkNum);

    cachedIcodeHdr.currentChunkNum = 0;
    cachedIcodeHdr.posGlobal = 0;
    cachedIcodeHdr.posChunk = 0;
}
