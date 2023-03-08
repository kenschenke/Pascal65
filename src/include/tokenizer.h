#ifndef TOKENIZER_H
#define TOKENIZER_H

#include <chunks.h>

extern CHUNKNUM tokenizerIcode;

typedef enum {
    tzDummy, tzIdentifier, tzToken, tzInteger, tzReal, tzChar, tzString
} TTokenizerCode;

// Returns membuf of intermediate code containing tokenized code
CHUNKNUM tokenize(const char *filename);

#endif // end of TOKENIZER_H
