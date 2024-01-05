#ifndef TYPECHECK_H
#define TYPECHECK_H

#include <chunks.h>

void typecheck_units(void);
void decl_typecheck(CHUNKNUM chunkNum);
void stmt_typecheck(CHUNKNUM chunkNum);

#endif // end of TYPECHECK_H
