#ifndef TOKENIZER_H
#define TOKENIZER_H

#include <chunks.h>

typedef enum {
    tzDummy, tzLineNum, tzIdentifier, tzToken, tzReal, tzChar, tzString,
    tzByte, tzWord, tzCardinal
} TTokenizerCode;

// Returns membuf of intermediate code containing tokenized code
CHUNKNUM tokenize(const char *filename);

#endif // end of TOKENIZER_H
