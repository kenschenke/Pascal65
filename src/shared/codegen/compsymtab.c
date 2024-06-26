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

static CHUNKNUM linkerSymtab;
CHUNKNUM linkerTags;

static CHUNKNUM bindLinkerSymbol(const char* name, unsigned short address);
static void freeLinkerSymbol(CHUNKNUM chunkNum);
static CHUNKNUM newLinkerSymbol(const char* name, unsigned short address);

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

static void freeLinkerSymbol(CHUNKNUM chunkNum)
{
	struct LINKSYMBOL sym;

	if (chunkNum == 0 || !isChunkAllocated(chunkNum)) {
		return;
	}

	retrieveChunk(chunkNum, &sym);
	freeLinkerSymbol(sym.left);
	freeLinkerSymbol(sym.right);
	freeChunk(chunkNum);
}

void freeLinkerSymbolTable(void)
{
	freeLinkerSymbol(linkerSymtab);
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

