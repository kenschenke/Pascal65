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

static void genArrayInit(struct type* pType);
static void updateHeapOffset(short newOffset);

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
#define ARRAY_ALLOC_LEN 14
static unsigned char arrayAlloc[] = {
	LDA_IMMEDIATE, 0,
	LDX_IMMEDIATE, 0,
	JSR, WORD_LOW(RT_HEAPALLOC), WORD_HIGH(RT_HEAPALLOC),
	STA_ZEROPAGE, ZP_PTR1L,
	STX_ZEROPAGE, ZP_PTR1H,
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
	STA_X_INDEXED_ZP, ZP_PTR1L,
};

static void genArrayInit(struct type* pType)
{
	struct type indexType, elemType;
	int numElements, lowBound, highBound;

	retrieveChunk(pType->indextype, &indexType);
	retrieveChunk(pType->subtype, &elemType);

	// Push element size onto stack
	genTwo(LDA_IMMEDIATE, WORD_LOW(elemType.size));
	genTwo(LDX_IMMEDIATE, WORD_HIGH(elemType.size));
	genThreeAddr(JSR, RT_PUSHAX);

	lowBound = getArrayLimit(indexType.min);
	highBound = getArrayLimit(indexType.max);
	numElements = abs(highBound - lowBound) + 1;

	// Array upper bound
	genExpr(indexType.max, 0, 1, 0);
	genThreeAddr(JSR, RT_PUSHAX);
	// Array lower bound
	genExpr(indexType.min, 0, 1, 0);
	genThreeAddr(JSR, RT_PUSHAX);
	genTwo(LDA_ZEROPAGE, ZP_PTR1L);
	genTwo(LDX_ZEROPAGE, ZP_PTR1H);
	// Initialize the array header
	genThreeAddr(JSR, RT_INITARRAYHEAP);
	// Move the heap pointer past the array header
	updateHeapOffset(heapOffset + 6);

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

	// If the element is another array, set it up too.
	if (elemType.kind == TYPE_ARRAY || elemType.kind == TYPE_RECORD) {
		unsigned short counter = codeBase + codeOffset + 3;
		genThreeAddr(JMP, codeBase+codeOffset+5);
		genOne(WORD_LOW(numElements));
		genOne(WORD_HIGH(numElements));
		if (elemType.kind == TYPE_ARRAY) {
			genArrayInit(&elemType);
		} else {
			genRecordInit(&elemType);
		}
		genThreeAddr(DEC_ABSOLUTE, counter);
		genTwo(BNE, 8);		// If low byte is still non-zero skip upper byte and loop again
		genThreeAddr(LDA_ABSOLUTE, counter+1);
		// If high byte is zero, break out of loop
		genTwo(BEQ, elemType.kind==TYPE_ARRAY?19:6);
		genThreeAddr(DEC_ABSOLUTE, counter+1);
		if (elemType.kind == TYPE_ARRAY) {
			updateHeapOffset(heapOffset + elemType.size - 6);
		}
		genThreeAddr(JMP, counter+2);
	}
}

void genRecordInit(struct type* pType)
{
	struct decl _decl;
	struct type _type;
	short offset = heapOffset;
	CHUNKNUM chunkNum = pType->paramsFields;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_decl);
		retrieveChunk(_decl.type, &_type);

		if (_type.kind == TYPE_DECLARED) {
			struct symbol sym;
			retrieveChunk(_decl.node, &sym);
			retrieveChunk(sym.type, &_type);
		}

		if (_type.kind == TYPE_RECORD) {
			genRecordInit(&_type);
		}

		if (_type.kind == TYPE_ARRAY) {
			updateHeapOffset(offset);
			// Record field is an array
			genArrayInit(&_type);
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
	char name[CHUNK_LEN + 1];
	struct decl _decl;
	struct type _type;
	struct symbol sym;
	int num = 0, heapVar = 0;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_decl);

		if (_decl.kind == DECL_CONST || _decl.kind == DECL_VARIABLE) {
			retrieveChunk(_decl.type, &_type);
			getBaseType(&_type);

			if (_type.flags & TYPE_FLAG_ISRETVAL) {
				chunkNum = _decl.next;
				continue;
			}

			memset(name, 0, sizeof(name));
			retrieveChunk(_decl.name, name);

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
				genArrayInit(&_type);
				heapOffsets[heapVar++] = sym.offset;
				break;
			}

			case TYPE_RECORD:
				recordDeclCode[RECORD_DECL_SIZEL] = WORD_LOW(_type.size);
				recordDeclCode[RECORD_DECL_SIZEH] = WORD_HIGH(_type.size);
				writeCodeBuf(recordDeclCode, 14);
				heapOffset = 0;
				genRecordInit(&_type);
				heapOffsets[heapVar++] = sym.offset;
				break;

			case TYPE_STRING_VAR:
				if (_decl.kind == DECL_CONST) {
					// Allocate a string object
					// To do this, I'm gonna cheat a little and use the "WriteStr"
					// code to construct a string object.
					struct expr strExpr;
					genTwo(LDA_IMMEDIATE, FH_STRING);
					genThreeAddr(JSR, RT_SETFH);
					genThreeAddr(JSR, RT_RESETSTRBUFFER);
					retrieveChunk(_decl.value, &strExpr);
					genStringValueAX(strExpr.value.stringChunkNum);
					genThreeAddr(JSR, RT_PUSHINTSTACK);
					genTwo(LDA_IMMEDIATE, 0);
					genThreeAddr(JSR, RT_WRITESTRLITERAL);
					genThreeAddr(JSR, RT_GETSTRBUFFER);
					genThreeAddr(JSR, RT_PUSHINTSTACK);
				} else {
					// Allocate an empty string
					writeCodeBuf(strAlloc, STR_ALLOC_LEN);
					genTwo(LDA_ZEROPAGE, ZP_PTR1L);
					genTwo(LDX_ZEROPAGE, ZP_PTR1H);
					genThreeAddr(JSR, RT_PUSHINTSTACK);
				}
				break;
			}

			++num;
		}

		chunkNum = _decl.next;
	}

	heapOffsets[heapVar] = -1;

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

