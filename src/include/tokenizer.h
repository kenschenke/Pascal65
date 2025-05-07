/**
 * tokenizer.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Definitions and declarations for tokenizer stage
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef TOKENIZER_H
#define TOKENIZER_H

#include <chunks.h>

typedef enum {
    tzDummy, tzLineNum, tzIdentifier, tzToken, tzReal, tzChar, tzString,
    tzByte, tzWord, tzCardinal
} TTokenizerCode;

// Returns membuf of intermediate code containing tokenized code
CHUNKNUM tokenize(const char *filename);
char isCompilerDirective(void);

#endif // end of TOKENIZER_H
