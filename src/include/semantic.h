#ifndef SEMANTIC_H
#define SEMANTIC_H

#include <chunks.h>

void initSemantic(void);

void decl_resolve(CHUNKNUM chunkNum, CHUNKNUM* symtab);
void expr_resolve(CHUNKNUM chunkNum, CHUNKNUM symtab, char isRtnCall);
void param_list_resolve(CHUNKNUM chunkNum);
void stmt_resolve(CHUNKNUM chunkNum);

void decl_typecheck(CHUNKNUM chunkNum);
void stmt_typecheck(CHUNKNUM chunkNum);

void set_decl_offsets(CHUNKNUM chunkNum, short offset, short level);

#endif // end of SEMANTIC_H
