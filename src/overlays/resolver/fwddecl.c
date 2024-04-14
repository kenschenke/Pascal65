/**
 * fwddecl.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Verify forward declarations
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include "ast.h"
#include "chunks.h"
#include "common.h"
#include "error.h"
#include "resolver.h"
#include <string.h>

static void verify_decl(CHUNKNUM chunkNum);
static void verify_stmt(CHUNKNUM chunkNum);

static void verify_decl(CHUNKNUM chunkNum)
{
    char name[CHUNK_LEN + 1];
    struct decl _decl;
    struct symbol sym;
    struct type _type;

    while (chunkNum) {
        retrieveChunk(chunkNum, &_decl);

        currentLineNumber = _decl.lineNumber;
        retrieveChunk(_decl.type, &_type);

        if (_decl.name) {
            memset(name, 0, sizeof(name));
            retrieveChunk(_decl.name, name);

			if ((_type.kind == TYPE_PROCEDURE || _type.kind == TYPE_FUNCTION) 
				&& _type.flags & TYPE_FLAG_ISFORWARD) {
					if (!scope_lookup(name, &sym) || sym.decl == chunkNum) {
                        Error(errUnresolvedFwd);
					}
				}
        }

        if (_decl.code) {
            scope_enter_symtab(_decl.symtab);
            verify_stmt(_decl.code);
            scope_exit();
        }

        chunkNum = _decl.next;
    }
}

void verify_fwd_declarations(CHUNKNUM astRoot)
{
    verify_decl(astRoot);
}

static void verify_stmt(CHUNKNUM chunkNum)
{
    struct stmt _stmt;

    while (chunkNum) {
        retrieveChunk(chunkNum, &_stmt);

        verify_decl(_stmt.decl);

        chunkNum = _stmt.next;
    }
}
