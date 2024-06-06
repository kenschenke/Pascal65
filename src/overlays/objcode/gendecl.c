/**
 * gendecl.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Generate identifier declarations in object code
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdio.h>
#include <stdlib.h>
#include <codegen.h>
#include <ast.h>
#include <asm.h>
#include <string.h>
#include <error.h>
#include <int16.h>
#include <membuf.h>

static CHUNKNUM addArrayLiteral(CHUNKNUM exprChunk, int *bufSize, int elemSize);
static CHUNKNUM addRealArrayLiteral(CHUNKNUM exprChunk, int *bufSize);
static void genArrayInit(struct type* pType, CHUNKNUM exprArrayInit, struct symbol *pSym);
static void genRecordInit(struct type* pType, struct symbol *pSym);
static void updateHeapOffset(short newOffset);
static void writeArrayInit(void);

#define RECORD_DECL_SIZEL 1
#define RECORD_DECL_SIZEH 3
static unsigned char recordDeclCode[] = {
	LDA_IMMEDIATE, 0,
	LDX_IMMEDIATE, 0,
	JSR, WORD_LOW(RT_HEAPALLOC), WORD_HIGH(RT_HEAPALLOC),
	STA_ZEROPAGE, ZP_PTR1L,
	STX_ZEROPAGE, ZP_PTR1H,
	JSR, WORD_LOW(RT_PUSHINTSTACK), WORD_HIGH(RT_PUSHINTSTACK),
};

#define ARRAY_ALLOC_SIZEL 1
#define ARRAY_ALLOC_SIZEH 3
#define ARRAY_ALLOC_LEN 10
static unsigned char arrayAlloc[] = {
	LDA_IMMEDIATE, 0,
	LDX_IMMEDIATE, 0,
	JSR, WORD_LOW(RT_HEAPALLOC), WORD_HIGH(RT_HEAPALLOC),
	JSR, WORD_LOW(RT_PUSHINTSTACK), WORD_HIGH(RT_PUSHINTSTACK),
};

#define HEAP_OFFSET_LOW 4
#define HEAP_OFFSET_HIGH 10
static unsigned char heapOffsetCode[] = {
	LDA_ZEROPAGE, ZP_PTR1L,
	CLC,
	ADC_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_PTR1L,
	LDA_ZEROPAGE, ZP_PTR1H,
	ADC_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_PTR1H,
};

#define STR_ALLOC_LEN 17
static unsigned char strAlloc[] = {
	LDA_IMMEDIATE, 1,
	LDX_IMMEDIATE, 0,
	JSR, WORD_LOW(RT_HEAPALLOC), WORD_HIGH(RT_HEAPALLOC),
	STA_ZEROPAGE, ZP_PTR1L,
	STX_ZEROPAGE, ZP_PTR1H,
	LDY_IMMEDIATE, 0,
	LDA_IMMEDIATE, 0,
	STA_ZPINDIRECT, ZP_PTR1L,
};

#define LIBDECL_SPL 1
#define LIBDECL_SPH 5
#define LIBDECL_LEN 19
static unsigned char libDecl[] = {
	LDA_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_PTR1L,
	LDA_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_PTR1H,
	LDY_IMMEDIATE, 0,
	LDA_ZEROPAGE, ZP_SPL,
	STA_ZPINDIRECT, ZP_PTR1L,
	INY,
	LDA_ZEROPAGE, ZP_SPH,
	STA_ZPINDIRECT, ZP_PTR1L,
};

static CHUNKNUM addArrayLiteral(CHUNKNUM exprChunk, int *bufSize, int elemSize)
{
	struct expr _expr;
	CHUNKNUM memChunk;

	allocMemBuf(&memChunk);
	*bufSize = 0;

	while (exprChunk) {
		retrieveChunk(exprChunk, &_expr);
		if (_expr.neg) _expr.value.longInt = -_expr.value.longInt;
		writeToMemBuf(memChunk, &_expr.value, elemSize);

		exprChunk = _expr.right;
		*bufSize += elemSize;
	}

	return memChunk;
}

static CHUNKNUM addRealArrayLiteral(CHUNKNUM exprChunk, int *bufSize)
{
	struct expr _expr;
	CHUNKNUM memChunk;

	allocMemBuf(&memChunk);
	*bufSize = 0;

	while (exprChunk) {
		retrieveChunk(exprChunk, &_expr);
		writeToMemBuf(memChunk, &_expr.neg, 1);
		writeToMemBuf(memChunk, &_expr.value.stringChunkNum, 2);

		exprChunk = _expr.right;
		*bufSize += 3;
	}

	return memChunk;
}

static void genArrayInit(struct type* pType, CHUNKNUM exprInitChunk,
	struct symbol *pSym)
{
	int bufSize, index;
	struct expr exprInit;
	struct ARRAYINIT arrayInit;
	struct type indexType, elemType;
	int numElements, lowBound, highBound;

	memset(&arrayInit, 0, sizeof(struct ARRAYINIT));

	retrieveChunk(pType->indextype, &indexType);
	retrieveChunk(pType->subtype, &elemType);

	lowBound = getArrayLimit(indexType.min);
	highBound = getArrayLimit(indexType.max);
	numElements = abs(highBound - lowBound) + 1;

	if (exprInitChunk) {
		retrieveChunk(exprInitChunk, &exprInit);
	} else {
		memset(&exprInit, 0, sizeof(struct expr));
	}

	arrayInit.scopeLevel = pSym->level;
	arrayInit.scopeOffset = pSym->offset;
	arrayInit.elemSize = elemType.size;
	arrayInit.heapOffset = heapOffset;
	arrayInit.minIndex = lowBound;
	arrayInit.maxIndex = highBound;
	if (elemType.kind != TYPE_ARRAY && elemType.kind != TYPE_RECORD) {
		if (elemType.kind == TYPE_REAL) {
			arrayInit.literals = addRealArrayLiteral(exprInitChunk, &bufSize);
			arrayInit.areLiteralsReals = 1;
			arrayInit.numLiterals = bufSize / 3;
		} else {
			arrayInit.literals = addArrayLiteral(exprInitChunk, &bufSize, elemType.size);
			arrayInit.numLiterals = bufSize / elemType.size;
		}
	}

	if (!arrayInitsForScope) {
		allocMemBuf(&arrayInitsForScope);
	}
	writeToMemBuf(arrayInitsForScope, &arrayInit, sizeof(struct ARRAYINIT));
	++numArrayInitsForScope;

	heapOffset += 6;  // move past array header

	// Check if the element is a record
	if (elemType.kind == TYPE_DECLARED) {
		char name[CHUNK_LEN + 1];
		struct symbol sym;
		memset(name, 0, sizeof(name));
		retrieveChunk(elemType.name, name);
		if (!scope_lookup(name, &sym)) {
			Error(errUndefinedIdentifier);
			return;
		}
		retrieveChunk(sym.type, &elemType);
	}

	if (elemType.kind == TYPE_ARRAY || elemType.kind == TYPE_RECORD) {
		for (index = lowBound; index <= highBound; ++index) {
			if (elemType.kind == TYPE_ARRAY) {
				genArrayInit(&elemType, exprInit.left, pSym);
			} else {
				genRecordInit(&elemType, pSym);
			}
			if (exprInit.right) {
				retrieveChunk(exprInit.right, &exprInit);
			} else {
				exprInit.left = exprInit.right = 0;
			}
		}
	} else {
		heapOffset += elemType.size * numElements;
	}
}

static void genRecordInit(struct type* pType, struct symbol *pSym)
{
	struct symbol sym;
	struct decl _decl;
	struct type _type;
	short offset = heapOffset;
	CHUNKNUM chunkNum = pType->paramsFields;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_decl);
		retrieveChunk(_decl.type, &_type);

		if (_decl.node) {
			retrieveChunk(_decl.node, &sym);
		} else {
			memset(&sym, 0, sizeof(struct symbol));
		}

		if (_type.kind == TYPE_DECLARED) {
			retrieveChunk(sym.type, &_type);
		}

		if (_type.kind == TYPE_RECORD) {
			genRecordInit(&_type, pSym);
		}

		if (_type.kind == TYPE_ARRAY) {
			updateHeapOffset(offset);
			// Record field is an array
			genArrayInit(&_type, _decl.value, pSym);
		}

		offset += _type.size;
		chunkNum = _decl.next;
	}

	if (offset > heapOffset) {
		// Advance ptr1 the remainder of the record
		updateHeapOffset(offset);
	}
}

int genVariableDeclarations(CHUNKNUM chunkNum, short* heapOffsets)
{
	char label[CHUNK_LEN + 1];
	struct decl _decl;
	struct type _type;
	struct expr _expr;
	struct symbol sym;
	int num = 0, heapVar = 0;
	CHUNKNUM firstDecl = chunkNum;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_decl);

		if (_decl.kind == DECL_CONST || _decl.kind == DECL_VARIABLE) {
			retrieveChunk(_decl.type, &_type);
			getBaseType(&_type);

			if (_type.flags & TYPE_FLAG_ISRETVAL) {
				chunkNum = _decl.next;
				continue;
			}

			if (_decl.node) {
				retrieveChunk(_decl.node, &sym);
			}
			else {
				sym.offset = -1;
			}

			switch (_type.kind) {
			case TYPE_BYTE:
			case TYPE_SHORTINT:
				genIntValueAX(_decl.value);
				genThreeAddr(JSR, RT_PUSHBYTESTACK);
				break;

			case TYPE_INTEGER:
			case TYPE_WORD:
			case TYPE_BOOLEAN:
			case TYPE_ENUMERATION:
				genIntValueAX(_decl.value);
				genThreeAddr(JSR, RT_PUSHINTSTACK);
				break;

			case TYPE_LONGINT:
			case TYPE_CARDINAL:
				genIntValueEAX(_decl.value);
				genThreeAddr(JSR, RT_PUSHEAX);
				break;

			case TYPE_CHARACTER:
				genCharValueA(_decl.value);
				genTwo(LDX_IMMEDIATE, 0);
				genThreeAddr(JSR, RT_PUSHINTSTACK);
				break;

			case TYPE_REAL:
				genRealValueEAX(_decl.value);
				genThreeAddr(JSR, RT_PUSHREALSTACK);
				break;

			case TYPE_ARRAY: {
				heapOffset = 0;
				arrayAlloc[ARRAY_ALLOC_SIZEL] = WORD_LOW(_type.size);
				arrayAlloc[ARRAY_ALLOC_SIZEH] = WORD_HIGH(_type.size);
				writeCodeBuf(arrayAlloc, ARRAY_ALLOC_LEN);
				if (_decl.value) {
					retrieveChunk(_decl.value, &_expr);
					_decl.value = _expr.left;
				}
				genArrayInit(&_type, _decl.value, &sym);
				heapOffsets[heapVar++] = sym.offset;
				break;
			}

			case TYPE_RECORD:
				recordDeclCode[RECORD_DECL_SIZEL] = WORD_LOW(_type.size);
				recordDeclCode[RECORD_DECL_SIZEH] = WORD_HIGH(_type.size);
				writeCodeBuf(recordDeclCode, 14);
				heapOffset = 0;
				genRecordInit(&_type, &sym);
				heapOffsets[heapVar++] = sym.offset;
				break;

			case TYPE_STRING_VAR:
				if (_decl.kind == DECL_CONST || _decl.value) {
					// Allocate a string object
					// To do this, I'm gonna cheat a little and use the "WriteStr"
					// code to construct a string object.
					struct expr strExpr;
					genTwo(LDA_IMMEDIATE, FH_STRING);
					genThreeAddr(JSR, RT_SETFH);
					genOne(PHA);
					genThreeAddr(JSR, RT_RESETSTRBUFFER);
					retrieveChunk(_decl.value, &strExpr);
					if (strExpr.kind == EXPR_NAME) {
						struct symbol sym;
						struct decl _decl;
						retrieveChunk(strExpr.node, &sym);
						retrieveChunk(sym.decl, &_decl);
						retrieveChunk(_decl.value, &strExpr);
					}
					genStringValueAX(strExpr.value.stringChunkNum);
					genThreeAddr(JSR, RT_PUSHINTSTACK);
					genTwo(LDA_IMMEDIATE, 0);
					genThreeAddr(JSR, RT_WRITESTRLITERAL);
					genThreeAddr(JSR, RT_GETSTRBUFFER);
					genThreeAddr(JSR, RT_PUSHINTSTACK);
					genOne(PLA);
					genThreeAddr(JSR, RT_SETFH);
				} else {
					// Allocate an empty string
					writeCodeBuf(strAlloc, STR_ALLOC_LEN);
					genTwo(LDA_ZEROPAGE, ZP_PTR1L);
					genTwo(LDX_ZEROPAGE, ZP_PTR1H);
					genThreeAddr(JSR, RT_PUSHINTSTACK);
				}
				break;
			}

			if (_decl.isLibrary) {
				// Write the address of this library declaration
				// to the library's jump table.
				strcpy(label, "libdecl");
				strcat(label, formatInt16(sym.type));
				linkAddressLookup(label, codeOffset+LIBDECL_SPL, 0, LINKADDR_LOW);
				linkAddressLookup(label, codeOffset+LIBDECL_SPH, 0, LINKADDR_HIGH);
				writeCodeBuf(libDecl, LIBDECL_LEN);
			}
			
			++num;
		}

		chunkNum = _decl.next;
	}

	heapOffsets[heapVar] = -1;

	writeArrayInit();

	return num;
}

int getArrayLimit(CHUNKNUM chunkNum)
{
	struct expr _expr;

	retrieveChunk(chunkNum, &_expr);
	if (_expr.kind == EXPR_BYTE_LITERAL) {
		return _expr.value.shortInt;
	}
	else if (_expr.kind == EXPR_WORD_LITERAL) {
		return _expr.value.integer;
	}
	else if (_expr.kind == EXPR_CHARACTER_LITERAL) {
		return _expr.value.character;
	}
	else if (_expr.kind == EXPR_NAME) {
		struct symbol sym;
		struct decl _decl;
		char name[CHUNK_LEN + 1];
		memset(name, 0, sizeof(name));
		retrieveChunk(_expr.name, name);
		scope_lookup(name, &sym);
		retrieveChunk(sym.decl, &_decl);
		return getArrayLimit(_decl.value);
	}
	else {
		Error(errInvalidIndexType);
	}

	return 0;
}

static void updateHeapOffset(short newOffset)
{
	if (newOffset != heapOffset) {
		int offset = newOffset - heapOffset;
		heapOffsetCode[HEAP_OFFSET_LOW] = WORD_LOW(offset);
		heapOffsetCode[HEAP_OFFSET_HIGH] = WORD_HIGH(offset);
		writeCodeBuf(heapOffsetCode, 13);

		heapOffset = newOffset;
	}
}

static void writeArrayInit(void)
{
	char label[20];

	if (!arrayInitsForScope || !numArrayInitsForScope) {
		return;
	}

	if (!arrayInitsForAllScopes) {
		allocMemBuf(&arrayInitsForAllScopes);
	}
	writeToMemBuf(arrayInitsForAllScopes, &arrayInitsForScope, sizeof(CHUNKNUM));
	++numArrayInitsForAllScopes;

	strcpy(label, "arrayInits");
	strcat(label, formatInt16(arrayInitsForScope));
	linkAddressLookup(label, codeOffset+1, 0, LINKADDR_LOW);
	genTwo(LDA_IMMEDIATE, 0);
	linkAddressLookup(label, codeOffset+1, 0, LINKADDR_HIGH);
	genTwo(LDX_IMMEDIATE, 0);
	genThreeAddr(JSR, RT_INITARRAYS);

	arrayInitsForScope = 0;
	numArrayInitsForScope = 0;
}

