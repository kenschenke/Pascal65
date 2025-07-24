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
				icodeWriteUnary(IC_DIA, icodeOperWord(1, sym.decl));
				localVars[num] = LOCALVARS_ARRAY;
				break;

			case TYPE_RECORD:
				localVars[num] = LOCALVARS_RECORD;
				icodeWriteUnary(IC_NEW, icodeOperInt(1, _type.size));
				heapOffset = 0;
				icodeFormatLabel(label, "di", chunkNum);
				icodeWriteUnary(IC_DIR, icodeOperWord(1, sym.decl));
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
