/**
 * typecheck.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Definitions and declarations for typechecking stage
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef TYPECHECK_H
#define TYPECHECK_H

#include <chunks.h>

void typecheck_units(void);
void decl_typecheck(CHUNKNUM chunkNum);
void stmt_typecheck(CHUNKNUM chunkNum);

#endif // end of TYPECHECK_H
