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

static CHUNKNUM bindLinkerSymbol(const char* name, unsigned short address, struct LINKSYMBOL* pSym);
static void freeLinkerSymbol(CHUNKNUM chunkNum);
static CHUNKNUM newLinkerSymbol(const char* name, unsigned short address, struct LINKSYMBOL* pSym);

static CHUNKNUM bindLinkerSymbol(const char* name, unsigned short address, struct LINKSYMBOL* pSym)
{
	int comp;
	struct LINKSYMBOL newSym;
	CHUNKNUM chunkNum, newChunkNum, lastChunkNum;

	if (linkerSymtab == 0) {
		linkerSymtab = newLinkerSymbol(name, address, pSym);
		return linkerSymtab;
	}

	chunkNum = linkerSymtab;
	while (chunkNum) {
		retrieveChunk(chunkNum, pSym);
		comp = strcmp(name, pSym->name);
		if (comp == 0) {
			if (address) {
				pSym->address = address;
				storeChunk(chunkNum, pSym);
			}
			return chunkNum;
		}

		lastChunkNum = chunkNum;
		chunkNum = comp < 0 ? pSym->left : pSym->right;
	}

	newChunkNum = newLinkerSymbol(name, address, &newSym);
	// Update the current node
	if (comp < 0) {
		pSym->left = newChunkNum;
	}
	else {
		pSym->right = newChunkNum;
	}
	storeChunk(lastChunkNum, pSym);

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

static CHUNKNUM newLinkerSymbol(const char* name, unsigned short address, struct LINKSYMBOL* pSym)
{
	CHUNKNUM chunkNum;

	allocChunk(&chunkNum);
	memset(pSym, 0, sizeof(struct LINKSYMBOL));

	strcpy(pSym->name, name);
	pSym->address = address;
	storeChunk(chunkNum, pSym);

	return chunkNum;
}

char linkAddressLookup(const char* name, unsigned short position, char whichNeeded)
{
	CHUNKNUM chunkNum;
	struct LINKTAG tag;
	struct LINKSYMBOL sym;

	chunkNum = bindLinkerSymbol(name, 0, &sym);

	tag.chunkNum = chunkNum;
	tag.position = position;
	tag.which = whichNeeded;
	writeToMemBuf(linkerTags, &tag, sizeof(struct LINKTAG));

	return 0;
}

void linkAddressSet(const char* name, unsigned short offset)
{
	struct LINKSYMBOL sym;

	bindLinkerSymbol(name, offset + codeBase, &sym);
}

