/**
 * common.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Code to initialize common data shared between overlays
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdio.h>
#include <common.h>
#include <symtab.h>
#include <membuf.h>
#include <ast.h>
#include <string.h>
#include <codegen.h>
#include <error.h>
#include <int16.h>

#ifndef __GNUC__
#include <cbm.h>
#include <conio.h>
#endif

#define DEFAULT_RUNTIMESTACKSIZE 512

short cntSymtabs;
CHUNKNUM firstSymtabChunk;
CHUNKNUM globalSymtab;
CHUNKNUM units;
CHUNKNUM exports;
char isFatalError;
short currentLineNumber;
unsigned short runtimeStackSize;
unsigned char libsNeeded[MAX_LIBS / 8];

static void saveLib(char num);

// Returns 0 if unit not found
char findUnit(CHUNKNUM name, struct unit* pUnit)
{
	CHUNKNUM chunkNum = units;
	char buf[CHUNK_LEN + 1];

	memset(buf, 0, sizeof(buf));
	retrieveChunk(name, buf);

	while (chunkNum) {
		retrieveChunk(chunkNum, pUnit);
		if (!strcmp(buf, pUnit->name)) {
			return 1;
		}

		chunkNum = pUnit->next;
	}

	return 0;
}

void initCommon(void)
{
    cntSymtabs = 0;
    firstSymtabChunk = 0;
    isFatalError = 0;
	runtimeStackSize = DEFAULT_RUNTIMESTACKSIZE;

    initMemBufCache();
}

void freeCommon(void)
{
	struct unit _unit;
	CHUNKNUM chunkNum = units;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_unit);
		decl_free(_unit.astRoot);
		freeChunk(chunkNum);
		chunkNum = _unit.next;
	}

	units = 0;
}

char isStopKeyPressed()
{
#ifdef __GNUC__
	return 0;
#else
    char ch = 0;

    if (kbhit()) {
        ch = cgetc();
    }

    return ch == CH_STOP;
#endif
}

void getBaseType(struct type* pType)
{
	struct symbol sym;
	char name[CHUNK_LEN + 1];
	char wasSubrange = 0;

	name[CHUNK_LEN] = 0;
	while (1) {
		if (pType->kind == TYPE_ENUMERATION || pType->kind == TYPE_ENUMERATION_VALUE) {
			break;
		}
		else if (pType->kind == TYPE_DECLARED) {
			if (pType->subtype) {
				retrieveChunk(pType->subtype, pType);
			}
			else if (pType->name) {
				retrieveChunk(pType->name, name);
				if (scope_lookup(name, &sym) && sym.type) {
					retrieveChunk(sym.type, pType);
					if (wasSubrange && pType->kind == TYPE_ENUMERATION_VALUE) {
						// This happens when a subrange lower limit is an enumeration.
						// The subrange type is the type of the enumeration value, so
						// the kind needs to be TYPE_ENUMERATION.
						pType->kind = TYPE_ENUMERATION;
					}
					if (pType->kind == TYPE_ENUMERATION && pType->subtype == 0) {
						pType->subtype = sym.type;
					}
				}
			}
		}
		else if (pType->kind == TYPE_SUBRANGE && pType->subtype) {
			wasSubrange = 1;
			retrieveChunk(pType->subtype, pType);
		}
		else {
			break;
		}
	}
}

char isConcatOperand(CHUNKNUM exprChunk)
{
	struct expr _expr;
	struct type _type;

	if (!exprChunk) {
		return 0;
	}

	retrieveChunk(exprChunk, &_expr);
	if (!_expr.evalType) {
		return 0;
	}
	retrieveChunk(_expr.evalType, &_type);
	getBaseType(&_type);
	if (_type.kind == TYPE_ARRAY) {
		retrieveChunk(_type.subtype, &_type);
		getBaseType(&_type);
	}

	return (_type.kind == TYPE_CHARACTER ||
		_type.kind == TYPE_STRING_LITERAL ||
		_type.kind == TYPE_STRING_OBJ ||
		_type.kind == TYPE_STRING_VAR) ? 1 : 0;
}

char isStringConcat(CHUNKNUM exprChunk)
{
	struct expr _expr;

	retrieveChunk(exprChunk, &_expr);
	return (_expr.kind == EXPR_ADD &&
		isConcatOperand(_expr.left) &&
		isConcatOperand(_expr.right)) ? 1 : 0;
}

static void saveLib(char num)
{
    if (num > MAX_LIBS) {
        abortTranslation(abortRuntimeError);
    }

    libsNeeded[num / 8] |= (1 << (num % 8));
}

void setRuntimeRef(unsigned char exportNum, unsigned short offset)
{
    char name[15];
    struct rtroutine routine;
    CHUNKNUM chunkNum = exports;

    while (chunkNum) {
        retrieveChunk(chunkNum, &routine);

        if (exportNum == routine.routineNum) {
            break;
        }

        chunkNum = exportNum < routine.routineNum ? routine.left : routine.right;
    }

    if (chunkNum) {
        saveLib(routine.libNum);
        strcpy(name, "rt_");
        strcat(name, formatInt16(exportNum));
        linkAddressLookup(name, offset, LINKADDR_BOTH);
    }
}

