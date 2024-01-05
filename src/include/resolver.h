#ifndef RESOLVER_H
#define RESOLVER_H

#include <chunks.h>

void resolve_units(void);

void decl_resolve(CHUNKNUM chunkNum, CHUNKNUM* symtab);
void expr_resolve(CHUNKNUM chunkNum, CHUNKNUM symtab, char isRtnCall);
void param_list_resolve(CHUNKNUM chunkNum);
void stmt_resolve(CHUNKNUM chunkNum);

void fix_global_offsets(CHUNKNUM astRoot);
short set_decl_offsets(CHUNKNUM chunkNum, short offset, short level);
void set_unit_offsets(CHUNKNUM firstUnit, short rootOffset);

#endif // end of RESOLVER_H
