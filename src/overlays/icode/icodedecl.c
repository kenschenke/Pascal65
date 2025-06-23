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
static CHUNKNUM addStringArrayLiteral(CHUNKNUM exprChunk, short *numLiterals);
static int getArrayLimit(CHUNKNUM chunkNum);
static void icodeArrayInit(char *label, struct type* pType,
	CHUNKNUM exprInitChunk, struct symbol *pSym);
static void icodeRecordInit(char *label, struct type* pType,
	struct symbol *pSym);

static CHUNKNUM addArrayLiteral(CHUNKNUM exprChunk, int *bufSize, int elemSize)
{
	struct expr _expr;
	CHUNKNUM memChunk;

	*bufSize = 0;
	if (!exprChunk) {
		return 0;
	}

	allocMemBuf(&memChunk);

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

static CHUNKNUM addStringArrayLiteral(CHUNKNUM exprChunk, short *numLiterals)
{
	char ch;
	struct expr _expr;
	CHUNKNUM memChunk;

	if (!exprChunk) {
		return 0;
	}

	allocMemBuf(&memChunk);

	while (exprChunk) {
		retrieveChunk(exprChunk, &_expr);
		setMemBufPos(_expr.value.stringChunkNum, 0);
		while (!isMemBufAtEnd(_expr.value.stringChunkNum)) {
			readFromMemBuf(_expr.value.stringChunkNum, &ch, 1);
			writeToMemBuf(memChunk, &ch, 1);
		}
		ch = 0;
		writeToMemBuf(memChunk, &ch, 1);

		exprChunk = _expr.right;
		(*numLiterals)++;
	}

	return memChunk;
}

static void icodeArrayInit(char *label, struct type* pType,
	CHUNKNUM exprInitChunk, struct symbol *pSym)
{
	int bufSize, index;
	CHUNKNUM declMemBuf;
	struct expr exprInit;
	struct ARRAYDECL arrayDecl;
	struct type indexType, elemType;
	int numElements, lowBound, highBound;

	memset(&arrayDecl, 0, sizeof(struct ARRAYDECL));

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

	arrayDecl.elemSize = elemType.size;
	arrayDecl.heapOffset = heapOffset;
	arrayDecl.minIndex = lowBound;
	arrayDecl.maxIndex = highBound;
	if (elemType.kind == TYPE_ARRAY) {
		arrayDecl.elemType = ARRAYDECL_ARRAY;
	} else if (elemType.kind == TYPE_RECORD) {
		arrayDecl.elemType = ARRAYDECL_RECORD;
	} else if (elemType.kind == TYPE_STRING_VAR) {
		arrayDecl.elemType = ARRAYDECL_STRING;
		arrayDecl.literals = addStringArrayLiteral(exprInitChunk, &arrayDecl.numLiterals);
	} else if (elemType.kind == TYPE_FILE || elemType.kind == TYPE_TEXT) {
		arrayDecl.elemType = ARRAYDECL_FILE;
	} else if (elemType.kind != TYPE_ARRAY && elemType.kind != TYPE_RECORD) {
		if (elemType.kind == TYPE_REAL) {
			arrayDecl.literals = addRealArrayLiteral(exprInitChunk, &bufSize);
			arrayDecl.elemType = ARRAYDECL_REAL;
			arrayDecl.numLiterals = bufSize / 3;
		} else {
			arrayDecl.literals = addArrayLiteral(exprInitChunk, &bufSize, elemType.size);
			arrayDecl.numLiterals = bufSize / elemType.size;
		}
	}

	if (!arrayInits) {
		allocMemBuf(&arrayInits);
	}

	writeToMemBuf(arrayInits, label, strlen(label)+1);

	allocMemBuf(&declMemBuf);
	writeToMemBuf(declMemBuf, &arrayDecl, sizeof(struct ARRAYDECL));
	writeToMemBuf(arrayInits, &declMemBuf, sizeof(CHUNKNUM));

	icodeWriteBinary(IC_DCI, icodeOperLabel(1, label),
		icodeOperShort(2, LOCALVARS_ARRAY));

	heapOffset += 6;  // move past array header

	if (elemType.kind == TYPE_ARRAY || elemType.kind == TYPE_RECORD) {
		int i;
		for (index = lowBound, i = 1; index <= highBound; ++index,++i) {
			char elemLabel[20];
			strcpy(elemLabel, label);
			strcat(elemLabel, ".");
			strcat(elemLabel, formatInt16(i));
			if (elemType.kind == TYPE_ARRAY) {
				icodeArrayInit(elemLabel, &elemType, exprInit.left, pSym);
			} else {
				icodeRecordInit(elemLabel, &elemType, pSym);
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

static void icodeRecordInit(char *label, struct type* pType, struct symbol *pSym)
{
	char memberType;
	struct symbol sym;
	struct decl _decl;
	struct type _type;
	short fieldOffset = 0;
	short recordOffset = heapOffset;  // heap offset at start of record
	short saveHeapOffset;  // save the heap offset and revert it for embedded arrays
	CHUNKNUM chunkNum = pType->paramsFields;
	CHUNKNUM declMemBuf = 0;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_decl);
		retrieveChunk(_decl.type, &_type);

		memberType = 0;

		if (_decl.node) {
			retrieveChunk(_decl.node, &sym);
		} else {
			memset(&sym, 0, sizeof(struct symbol));
		}

		if (_type.kind == TYPE_DECLARED) {
			retrieveChunk(sym.type, &_type);
		}

		if (_type.kind == TYPE_RECORD) {
			char label[25];
			// Record field is an embedded record
			icodeFormatLabel(label, "di", pSym->decl);
			icodeRecordInit(label, &_type, pSym);
		} else if (_type.kind == TYPE_STRING_VAR) {
			memberType = LOCALVARS_STRING;
		} else if (_type.kind == TYPE_FILE || _type.kind == TYPE_TEXT) {
			memberType = LOCALVARS_FILE;
		} else if (_type.kind == TYPE_ARRAY) {
			char fieldLabel[25];
			// Record field is an array
			// strcpy(label, "di");
			strcpy(fieldLabel, label);
			strcat(fieldLabel, formatInt16(pSym->decl));
			strcat(fieldLabel, ".");
			strcat(fieldLabel, formatInt16(fieldOffset));
			saveHeapOffset = heapOffset;
			icodeArrayInit(fieldLabel, &_type, _decl.value, pSym);
			heapOffset = saveHeapOffset;
			memberType = LOCALVARS_ARRAY;
		}
	
		if (!declMemBuf) {
			allocMemBuf(&declMemBuf);
			writeToMemBuf(declMemBuf, &recordOffset, sizeof(short));
			writeToMemBuf(declMemBuf, &pType->size, sizeof(short));
		}

		if (memberType) {
			writeToMemBuf(declMemBuf, &memberType, 1);
			writeToMemBuf(declMemBuf, &pSym->decl, sizeof(CHUNKNUM));
			writeToMemBuf(declMemBuf, &fieldOffset, sizeof(short));
		}
	
		heapOffset += _type.size;
		fieldOffset += _type.size;
		chunkNum = _decl.next;
	}

	if (declMemBuf) {
		char eob = 0;  // end of buffer character
		writeToMemBuf(declMemBuf, &eob, 1);

		if (!recordInits) {
			allocMemBuf(&recordInits);
		}

		writeToMemBuf(recordInits, label, strlen(label)+1);
		writeToMemBuf(recordInits, &declMemBuf, sizeof(CHUNKNUM));

		icodeWriteBinary(IC_DCI, icodeOperLabel(1, label),
			icodeOperShort(2, LOCALVARS_RECORD));
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
				localVars[num] = LOCALVARS_FILE;
				break;

			case TYPE_BOOLEAN:
				icodeBoolValue(_decl.value);
				break;
			
			case TYPE_POINTER:
				icodeWordValue(0);
				break;

			case TYPE_ROUTINE_POINTER:
				icodeDWordValue(0);
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
				heapOffset = 0;
				if (_decl.value) {
					retrieveChunk(_decl.value, &_expr);
					_decl.value = _expr.left;
				}
				icodeWriteUnary(IC_NEW, icodeOperInt(1, _type.size));
				icodeFormatLabel(label, "di", chunkNum);
				icodeArrayInit(label, &_type, _decl.value, &sym);
				localVars[num] = LOCALVARS_ARRAY;
				break;

			case TYPE_RECORD:
				localVars[num] = LOCALVARS_RECORD;
				icodeWriteUnary(IC_NEW, icodeOperInt(1, _type.size));
				heapOffset = 0;
				icodeFormatLabel(label, "di", chunkNum);
				icodeRecordInit(label, &_type, &sym);
				break;

			case TYPE_STRING_VAR:
				localVars[num] = LOCALVARS_DEL;
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
				icodeFormatLabel(label, "libdecl", sym.type);
				icodeWriteUnaryLabel(IC_SSP, label);
			}
			
			++num;
		}

		chunkNum = _decl.next;
	}

	return num;
}
