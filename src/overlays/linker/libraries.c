/**
 * libraries.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Code to load and relocate libraries in program file.
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdio.h>
#include <asm.h>
#include <ast.h>
#include <codegen.h>
#include <membuf.h>
#include <string.h>
#include <chunks.h>
#include <libcommon.h>
#include <int16.h>
#include <common.h>

#define BUFLEN 20

// Page number of the library
static unsigned char page;

// Base of library after relocation
static unsigned short libBase;

// Buffer to store library
static CHUNKNUM libBuf;

// Private function prototypes
static FILE* openLibrary(const char* library);
static unsigned short relocate(unsigned char p, unsigned char o);
static char processJumpTable(CHUNKNUM libRoot);
static int readLibrary(FILE* fp);
static void loadLibrary(const char* library, CHUNKNUM libRoot);

static FILE* openLibrary(const char* library)
{
    char filename[16 + 1];

    strcpy(filename, library);
    strcat(filename, ".lib");

    return fopen(filename, "rb");
}

// This function returns the relocated address from the
// page (p) and the offset (o) of the supplied address.
static unsigned short relocate(unsigned char p, unsigned char o)
{
    return libBase + ((unsigned short)p - page) * 256 + o;
}

static char processJumpTable(CHUNKNUM libRoot)
{
    struct decl _decl;
    struct stmt _stmt;
    struct type _type;
    unsigned char buffer[3];
    char name[16 + 1];
    CHUNKNUM chunkNum;
    unsigned short relocAddr;

    retrieveChunk(libRoot, &_decl);
    retrieveChunk(_decl.code, &_stmt);
    chunkNum = _stmt.interfaceDecl;
    while (chunkNum) {
        retrieveChunk(chunkNum, &_decl);
        retrieveChunk(_decl.type, &_type);

        if (_type.kind == TYPE_FUNCTION || _type.kind == TYPE_PROCEDURE) {
            readFromMemBuf(libBuf, buffer, 3);

            if (buffer[0] != JMP) {
                return 0;
            }

            relocAddr = relocate(buffer[2], buffer[1]);
            buffer[1] = WORD_LOW(relocAddr);
            buffer[2] = WORD_HIGH(relocAddr);

            strcpy(name, "RTN");
            strcat(name, formatInt16(chunkNum));
            strcat(name, "ENTER");
            linkAddressSet(name, codeOffset);

            writeCodeBuf(buffer, 3);
        }
        else if (_decl.kind == DECL_VARIABLE) {
            strcpy(name, "libdecl");
            strcat(name, formatInt16(_decl.type));
            linkAddressSet(name, codeOffset);
            readFromMemBuf(libBuf, buffer, 2);
            writeCodeBuf(buffer, 2);
        }

        chunkNum = _decl.next;
    }

    return 1;
}

static int readLibrary(FILE* fp)
{
    int n, total = 0;
    char buffer[BUFLEN];

    while (!feof(fp)) {
        n = fread(buffer, 1, BUFLEN, fp);
        if (!n) {
            break;
        }
        writeToMemBuf(libBuf, buffer, n);
        total += n;
    }

    setMemBufPos(libBuf, 0);
    return total;
}

// This function loads a library into the codeBuf.
// The library parameter is the name of library (without the .lib suffix).
// The base address of the code is assumed to start at the current
// position in codeBuf (codeBase + codeOffset).
// The libRoot parameter is the AST for the library.
static void loadLibrary(const char* library, CHUNKNUM libRoot)
{
    int i, n, pos, numRead;
    char pages;             // number of pages in the library file
    FILE* fp;
    unsigned char buffer[BUFLEN];

    libBase = codeBase + codeOffset;

    fp = openLibrary(library);

    if (fread(buffer, 1, 2, fp) != 2) {
        fclose(fp);
        return;
    }

    if (buffer[0]) {
        fclose(fp);
        return;
    }

    page = buffer[1];

    allocMemBuf(&libBuf);
    numRead = readLibrary(fp);
    fclose(fp);
    pages = numRead / 256 + (numRead % 256 ? 1 : 0);

    if (!processJumpTable(libRoot)) {
        freeMemBuf(libBuf);
        return;
    }

    // This loop reads object code from the library file.
    // It loads bytes into the buffer and searches for addresses
    // to relocate.  Because addresses are two bytes, it doesn't
    // want to miss an address that might be in the last byte of
    // a read cycle.  For this reason it always retains the
    // last byte from the previous cycle.
    pos = getMemBufPos(libBuf);
    // prime the buffer
    readFromMemBuf(libBuf, buffer, 1);
    ++pos;
    while (pos < numRead) {
        n = (pos + BUFLEN < (numRead+1) ? (BUFLEN-1) : numRead - pos);
        readFromMemBuf(libBuf, buffer+1, n);

        for (i = 0; i <= n; ++i) {
            if (i < n && buffer[i + 1] >= page && buffer[i + 1] <= page + pages - 1) {
                short relocAddr = relocate(buffer[i + 1], buffer[i]);
                buffer[i] = WORD_LOW(relocAddr);
                buffer[i + 1] = WORD_HIGH(relocAddr);
                ++i;
            }
        }
        writeCodeBuf(buffer, n);

        buffer[0] = buffer[n];
        pos += n;
    }

    freeMemBuf(libBuf);
    writeCodeBuf(buffer, 1);
}

void loadLibraries(CHUNKNUM astRoot)
{
    struct decl _decl, unitDecl;
    struct stmt _stmt;
    struct unit _unit;
    char name[CHUNK_LEN + 1];
    CHUNKNUM chunkNum;

    retrieveChunk(astRoot, &_decl);
    retrieveChunk(_decl.code, &_stmt);

    chunkNum = _stmt.decl;
    while (chunkNum) {
        retrieveChunk(chunkNum, &_decl);

        if (_decl.kind == DECL_USES) {
            memset(name, 0, sizeof(name));
            retrieveChunk(_decl.name, name);

            findUnit(_decl.name, &_unit);
            retrieveChunk(_unit.astRoot, &unitDecl);
            if (unitDecl.isLibrary) {
                loadLibrary(name, _unit.astRoot);
            }
        }
        
        chunkNum = _decl.next;
    }
}
