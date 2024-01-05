/**
 * common.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Code to initialize common data shared between overlays
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdio.h>
#include <common.h>
#include <symtab.h>
#include <cbm.h>
#include <conio.h>
#include <membuf.h>
#include <ast.h>
#include <string.h>

short cntSymtabs;
CHUNKNUM firstSymtabChunk;
CHUNKNUM globalSymtab;
CHUNKNUM units;
char isFatalError;
short currentLineNumber;

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

    initMemBufCache();
}

void freeCommon(void)
{
	struct unit _unit;
	CHUNKNUM chunkNum = units;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_unit);
		decl_free(_unit.astRoot);
		chunkNum = _unit.next;
	}

	units = 0;
}

char isStopKeyPressed()
{
    char ch = 0;

    if (kbhit()) {
        ch = cgetc();
    }

    return ch == CH_STOP;
}

void getBaseType(struct type* pType)
{
	struct symbol sym;
	char name[CHUNK_LEN + 1];
	char wasSubrange = 0;

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

