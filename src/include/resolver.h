/**
 * resolver.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Definitions and declarations for resolver stage
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef RESOLVER_H
#define RESOLVER_H

#include <chunks.h>

void resolve_units(void);

void decl_resolve(CHUNKNUM chunkNum, CHUNKNUM* symtab);
void expr_resolve(CHUNKNUM chunkNum, CHUNKNUM symtab, char isRtnCall);
void param_list_resolve(CHUNKNUM chunkNum);
void stmt_resolve(CHUNKNUM chunkNum);

void fix_global_offsets(CHUNKNUM astRoot);
void inject_system_unit(void);
short set_decl_offsets(CHUNKNUM chunkNum, short offset, short level);
void set_unit_offsets(CHUNKNUM firstUnit, short rootOffset);
void verify_fwd_declarations(CHUNKNUM astRoot);

#endif // end of RESOLVER_H
