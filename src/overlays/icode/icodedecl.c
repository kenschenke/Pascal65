/**
 * icodedecl.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Intermediate Code
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <icode.h>
#include <ast.h>
#include <codegen.h>
#include <string.h>
#include <error.h>
#include <stdlib.h>
#include <membuf.h>
#include <int16.h>

static CHUNKNUM addArrayLiteral(CHUNKNUM exprChunk, int *bufSize, int elemSize);
static CHUNKNUM addRealArrayLiteral(CHUNKNUM exprChunk, int *bufSize);
static int getArrayLimit(CHUNKNUM chunkNum);
static void icodeArrayInit(struct type* pType, CHUNKNUM exprInitChunk,
	struct symbol *pSym);
static void icodeRecordInit(struct type* pType, struct symbol *pSym);
static void writeArrayInit(void);

static CHUNKNUM addArrayLiteral(CHUNKNUM exprChunk, int *bufSize, int elemSize)
{
	struct expr _expr;
	CHUNKNUM memChunk;

	if (!exprChunk) {
		return 0;
	}

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

static void icodeArrayInit(struct type* pType, CHUNKNUM exprInitChunk,
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
				icodeArrayInit(&elemType, exprInit.left, pSym);
			} else {
				icodeRecordInit(&elemType, pSym);
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

static int getArrayLimit(CHUNKNUM chunkNum)
{
	struct expr _expr;

	retrieveChunk(chunkNum, &_expr);
	if (_expr.kind == EXPR_BYTE_LITERAL) {
		return _expr.neg ? -_expr.value.shortInt : _expr.value.shortInt;
	}
	else if (_expr.kind == EXPR_WORD_LITERAL) {
		return _expr.neg ? -_expr.value.integer : _expr.value.integer;
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

static void icodeRecordInit(struct type* pType, struct symbol *pSym)
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
			icodeRecordInit(&_type, pSym);
		}

		if (_type.kind == TYPE_ARRAY) {
			if (offset > heapOffset) {
				heapOffset = offset;
			}
			// Record field is an array
			icodeArrayInit(&_type, _decl.value, pSym);
		}

		offset += _type.size;
		chunkNum = _decl.next;
	}

	if (offset > heapOffset) {
		// Advance ptr1 the remainder of the record
		heapOffset = offset;
	}
}

int icodeVariableDeclarations(CHUNKNUM chunkNum, char *localVars)
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
		localVars[num] = 0;

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
                icodeShortValue(_decl.value);
				break;
			
			case TYPE_INTEGER:
			case TYPE_WORD:
			case TYPE_ENUMERATION:
				icodeWordValue(_decl.value);
				break;
			
			case TYPE_CHARACTER:
				icodeCharValue(_decl.value);
				break;

			case TYPE_LONGINT:
			case TYPE_CARDINAL:
				icodeDWordValue(_decl.value);
				break;
			
			case TYPE_FILE:
			case TYPE_TEXT:
				icodeDWordValue(0);
				localVars[num] = 2;
				break;

			case TYPE_BOOLEAN:
				icodeBoolValue(_decl.value);
				break;
			
			case TYPE_POINTER:
				icodeWordValue(0);
				break;

			case TYPE_REAL: {
				struct expr _expr;

				if (_decl.value) {
					retrieveChunk(_decl.value, &_expr);
				} else {
					_expr.value.stringChunkNum = 0;
				}

				// Pointer to the real string in A/X
				icodeRealValue(_expr.value.stringChunkNum);
				break;
			}

			case TYPE_ARRAY:
				localVars[num] = 1;
				icodeWriteUnary(IC_NEW, icodeOperInt(1, _type.size));
				heapOffset = 0;
				if (_decl.value) {
					retrieveChunk(_decl.value, &_expr);
					_decl.value = _expr.left;
				}
				icodeArrayInit(&_type, _decl.value, &sym);
				break;

			case TYPE_RECORD:
				localVars[num] = 1;
				icodeWriteUnary(IC_NEW, icodeOperInt(1, _type.size));
				heapOffset = 0;
				icodeRecordInit(&_type, &sym);
				break;

			case TYPE_STRING_VAR:
				localVars[num] = 1;
				if (_decl.kind == DECL_CONST || _decl.value) {
					struct expr strExpr;
					retrieveChunk(_decl.value, &strExpr);
					if (strExpr.kind == EXPR_NAME) {
						struct symbol sym;
						struct decl _decl;
						retrieveChunk(strExpr.node, &sym);
						retrieveChunk(sym.decl, &_decl);
						retrieveChunk(_decl.value, &strExpr);
					}
					icodeWriteUnary(IC_SST, icodeOperStr(1, strExpr.value.stringChunkNum));
				} else {
					// Allocate an empty string
					icodeWriteUnaryWord(IC_SST, 0);
				}
				break;
			}

			if (_decl.isLibrary) {
				// Write the address of this library declaration
				// to the library's jump table.
				strcpy(label, "libdecl");
				strcat(label, formatInt16(sym.type));
				icodeWriteUnaryLabel(IC_SSP, label);
			}
			
			++num;
		}

		chunkNum = _decl.next;
	}

	writeArrayInit();

	return num;
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
	icodeWriteUnaryLabel(IC_ARR, label);

	arrayInitsForScope = 0;
	numArrayInitsForScope = 0;
}

