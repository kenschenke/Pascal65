/**
 * ast_symtab.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <ast.h>
#include <error.h>
#include <symtab.h>
#include <string.h>

#define MAX_STACK_DEPTH 8

static CHUNKNUM symbol_stack[MAX_STACK_DEPTH];

static short currentStackLevel;

static int comp_symbol(const char* identifier, CHUNKNUM other);
static char lookup_symbol(const char* identifier, CHUNKNUM root, struct symbol* sym);
static void initStandardRoutines(void);

static int comp_symbol(const char* identifier, CHUNKNUM other) {
    char otherIdent[CHUNK_LEN];

	if (retrieveChunk(other, (unsigned char*)otherIdent) == 0) {
        abortTranslation(abortOutOfMemory);
    }

    return strncmp(identifier, otherIdent, CHUNK_LEN);
}

void free_scope_stack(void)
{
	symtab_free(symbol_stack[0]);
}

void init_scope_stack(void)
{
	currentStackLevel = 0;
	symbol_stack[currentStackLevel] = 0;

	initStandardRoutines();
}

static struct TStdRtn {
	char* pName;
	TRoutineCode rc;
	char type;
} stdRtnList[] = {
	{"read", rcRead, TYPE_PROCEDURE},
	{"readln", rcReadln, TYPE_PROCEDURE},
	{"readstr", rcReadStr, TYPE_PROCEDURE},
	{"write", rcWrite, TYPE_PROCEDURE},
	{"writeln", rcWriteln, TYPE_PROCEDURE},
	{"writestr", rcWriteStr, TYPE_FUNCTION},
	{"abs", rcAbs, TYPE_FUNCTION},
	{"eof", rcEof, TYPE_FUNCTION},
	{"eoln", rcEoln, TYPE_FUNCTION},
	{"ord", rcOrd, TYPE_FUNCTION},
	{"pred", rcPred, TYPE_FUNCTION},
	{"succ", rcSucc, TYPE_FUNCTION},
	{"round", rcRound, TYPE_FUNCTION},
	{"sqr", rcSqr, TYPE_FUNCTION},
	{"trunc", rcTrunc, TYPE_FUNCTION},
	// {"dec", rcDec, TYPE_PROCEDURE},
	// {"inc", rcInc, TYPE_PROCEDURE},
	{0},
};

static void initStandardRoutines(void)
{
	struct symbol sym;
	struct type _type;
	int i = 0;
	CHUNKNUM typeChunk, symChunk;

	do {
		typeChunk = typeCreate(stdRtnList[i].type, 0, 0, 0);
		retrieveChunk(typeChunk, &_type);
		_type.flags |= TYPE_FLAG_ISSTD;
		_type.routineCode = stdRtnList[i].rc;
		storeChunk(typeChunk, &_type);

		symChunk = symbol_create(SYMBOL_GLOBAL, typeChunk, stdRtnList[i].pName);
		retrieveChunk(symChunk, &sym);

		if (symbol_stack[currentStackLevel] == 0) {
			symbol_stack[currentStackLevel] = symChunk;
		}
		else {
			scope_bind_symtab(stdRtnList[i].pName, &sym, symbol_stack[currentStackLevel], 1);
		}
	} while (stdRtnList[++i].pName);
}

void scope_enter(void)
{
	if (++currentStackLevel >= MAX_STACK_DEPTH) {
		Error(errNestingTooDeep);
		abortTranslation(abortNestingTooDeep);
	}

	symbol_stack[currentStackLevel] = 0;
}

CHUNKNUM scope_exit(void)
{
	return symbol_stack[currentStackLevel--];
}

void scope_enter_symtab(CHUNKNUM symtab)
{
	symbol_stack[++currentStackLevel] = symtab;
}

short scope_level(void)
{
	return currentStackLevel;  // scope levels start at 1
}

static char lookup_symbol(const char* name, CHUNKNUM root, struct symbol* sym)
{
	int comp;
	CHUNKNUM chunkNum = root;

	while (chunkNum) {
		retrieveChunk(chunkNum, sym);
		comp = comp_symbol(name, sym->name);
		if (comp == 0) {
			return 1;
		}
		chunkNum = comp < 0 ? sym->leftChild : sym->rightChild;
	}

	return 0;  // not found
}

char scope_lookup(const char* name, struct symbol* sym)
{
	short level = currentStackLevel;

	while (level >= 0) {
		if (lookup_symbol(name, symbol_stack[level], sym)) {
			return 1;
		}
		level--;
	}

	return 0;
}

char scope_lookup_parent(const char* name, struct symbol* sym)
{
	short level = currentStackLevel - 1;

	while (level >= 0) {
		if (lookup_symbol(name, symbol_stack[level], sym)) {
			return 1;
		}
		level--;
	}

	return 0;
}

char scope_lookup_current(const char* name, struct symbol* sym)
{
	return lookup_symbol(name, symbol_stack[currentStackLevel], sym);
}

char symtab_lookup(CHUNKNUM symtab, const char* name, struct symbol* sym)
{
	return lookup_symbol(name, symtab, sym);
}

// Return zero if symbol already exists
char scope_bind(const char* name, struct symbol* sym, char failIfExists)
{
	if (!symbol_stack[currentStackLevel]) {
		// Tree is empty.  This node becomes the root.
		symbol_stack[currentStackLevel] = sym->nodeChunkNum;
		return 1;
	}

	return scope_bind_symtab(name, sym, symbol_stack[currentStackLevel], failIfExists);
}

// Return zero if symbol already exists
char scope_bind_symtab(const char* name, struct symbol* sym, CHUNKNUM symtab, char failIfExists)
{
	int comp;
	struct symbol _symbol;
	CHUNKNUM chunkNum = symtab;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_symbol);
		comp = comp_symbol(name, _symbol.name);
		if (comp == 0) {
			// Already there
			if (failIfExists) Error(errInvalidIdentifierUsage);
			return 0;
		}

		chunkNum = comp < 0 ? _symbol.leftChild : _symbol.rightChild;
	}

	// Update the current node.
	if (comp < 0) {
		_symbol.leftChild = sym->nodeChunkNum;
	}
	else {
		_symbol.rightChild = sym->nodeChunkNum;
	}
	storeChunk(_symbol.nodeChunkNum, &_symbol);

	return 1;
}

