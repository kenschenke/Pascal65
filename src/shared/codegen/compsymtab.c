/**
 * codegen.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Linker symbol table
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <string.h>

#include <codegen.h>
#include <chunks.h>
#include <membuf.h>
#include <error.h>

// Size of the stack used to free the symbol table
#define SYMBOL_STACK_SIZE 36

static CHUNKNUM linkerSymtab;
CHUNKNUM linkerTags;

// These two variables are used to free the symbol table
static char symbolStackTop;
static CHUNKNUM symbolStack[SYMBOL_STACK_SIZE];

static CHUNKNUM bindLinkerSymbol(const char* name, unsigned short address);
static CHUNKNUM newLinkerSymbol(const char* name, unsigned short address);
static CHUNKNUM popSymbolStack(void);
static void pushSymbolStack(CHUNKNUM chunkNum);

static CHUNKNUM bindLinkerSymbol(const char* name, unsigned short address)
{
	int comp;
	struct LINKSYMBOL sym;
	CHUNKNUM chunkNum, newChunkNum, lastChunkNum;

	if (linkerSymtab == 0) {
		linkerSymtab = newLinkerSymbol(name, address);
		return linkerSymtab;
	}

	chunkNum = linkerSymtab;
	while (chunkNum) {
		retrieveChunk(chunkNum, &sym);
		comp = strcmp(name, sym.name);
		if (comp == 0) {
			if (address) {
				sym.address = address;
				storeChunk(chunkNum, &sym);
			}
			return chunkNum;
		}

		lastChunkNum = chunkNum;
		chunkNum = comp < 0 ? sym.left : sym.right;
	}

	newChunkNum = newLinkerSymbol(name, address);
	// Update the current node
	if (comp < 0) {
		sym.left = newChunkNum;
	}
	else {
		sym.right = newChunkNum;
	}

	storeChunk(lastChunkNum, &sym);

	return newChunkNum;
}

void freeLinkerSymbolTable(void)
{
    char done = 0;
    CHUNKNUM chunkNum = linkerSymtab;
	struct LINKSYMBOL sym;

    symbolStackTop = 0;

    while (!done) {
        if (chunkNum) {
            retrieveChunk(chunkNum, &sym);
            pushSymbolStack(chunkNum);
            chunkNum = sym.left;
        } else {
            if (symbolStackTop) {
                chunkNum = popSymbolStack();
                retrieveChunk(chunkNum, &sym);
                freeChunk(chunkNum);
                chunkNum = sym.right;
            } else {
                done = 1;
            }
        }
    }

	freeMemBuf(linkerTags);
}

void initLinkerSymbolTable(void)
{
	linkerSymtab = 0;
	allocMemBuf(&linkerTags);
}

static CHUNKNUM newLinkerSymbol(const char* name, unsigned short address)
{
	struct LINKSYMBOL sym;
	CHUNKNUM chunkNum;

	allocChunk(&chunkNum);
	memset(&sym, 0, sizeof(struct LINKSYMBOL));

	strcpy(sym.name, name);
	sym.address = address;
	storeChunk(chunkNum, &sym);

	return chunkNum;
}

char linkAddressLookup(const char* name, unsigned short position, char whichNeeded)
{
	CHUNKNUM chunkNum;
	struct LINKTAG tag;

	chunkNum = bindLinkerSymbol(name, 0);

	tag.chunkNum = chunkNum;
	tag.position = position;
	tag.which = whichNeeded;
	writeToMemBuf(linkerTags, &tag, sizeof(struct LINKTAG));

	return 0;
}

void linkAddressSet(const char* name, unsigned short offset)
{
	bindLinkerSymbol(name, offset + codeBase);
}

static void pushSymbolStack(CHUNKNUM chunkNum)
{
    if (symbolStackTop >= SYMBOL_STACK_SIZE) {
        runtimeError(rteStackOverflow);
    }
    symbolStack[symbolStackTop++] = chunkNum;
}

static CHUNKNUM popSymbolStack(void)
{
    return symbolStack[--symbolStackTop];
}

