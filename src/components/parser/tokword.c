#include <scanner.h>
#include <string.h>
#include <ctype.h>

const int minResWordLength = 2;
const int maxResWordLength = 9;

typedef struct {
    const char *pString;
    TTokenCode code;
} TResWord;

static TResWord rw2[] = {
    {"do", tcTO}, {"if", tcIF}, {"in", tcIN}, {"of", tcOF},
    {"or", tcOR}, {"to", tcTO}, {NULL},
};

static TResWord rw3[] = {
    {"and", tcAND}, {"div", tcDIV}, {"end", tcEND}, {"for", tcFOR},
    {"mod", tcMOD}, {"nil", tcNIL}, {"not", tcNOT}, {"set", tcSET},
    {"var", tcVAR}, {NULL},
};

static TResWord rw4[] = {
    {"case", tcCASE}, {"else", tcELSE}, {"file", tcFILE},
    {"goto", tcGOTO}, {"then", tcTHEN}, {"type", tcTYPE},
    {"with", tcWITH}, {NULL},
};

static TResWord rw5[] = {
    {"array", tcARRAY}, {"begin", tcBEGIN}, {"const", tcCONST},
    {"label", tcLABEL}, {"until", tcUNTIL}, {"while", tcWHILE},
    {NULL},
};

static TResWord rw6[] = {
    {"downto", tcDOWNTO}, {"packed", tcPACKED}, {"record", tcRECORD},
    {"repeat", tcREPEAT}, {NULL},
};

static TResWord rw7[] = {
    {"program", tcPROGRAM}, {NULL},
};

static TResWord rw8[] = {
    {"function", tcFUNCTION}, {NULL},
};

static TResWord rw9[] = {
    {"procedure", tcPROCEDURE}, {NULL},
};

static TResWord *rwTable[] = {
    NULL, NULL, rw2, rw3, rw4, rw5, rw6, rw7, rw8, rw9,
};

static void checkForReservedWord(TOKEN *token)
{
    int len = strlen(token->string);
    TResWord *prw;

    token->code = tcIdentifier;

    if (len >= minResWordLength && len <= maxResWordLength) {
        for (prw = rwTable[len]; prw->pString; prw++) {
            if (strcmp(token->string, prw->pString) == 0) {
                token->code = prw->code;
                break;
            }
        }
    }
}

void getWordToken(TOKEN *token, SCANNER *scanner)
{
    char ch, *ps;

    ch = getCurrentChar(scanner->pTinBuf);
    ps = token->string;

    // Extract the word
    do {
        *ps++ = ch;
        ch = getChar(scanner->pTinBuf);
    } while (charCodeMap[ch] == ccLetter || charCodeMap[ch] == ccDigit);

    *ps = 0;

    // If this file came from a PC, convert lower-case ASCII
    // to upper-case ASCII.
    for (ps = token->string; *ps; ps++) {
        if (*ps >= 97 && *ps <= 122) {
            *ps -= 32;
        }
    }
    strlwr(token->string);

    checkForReservedWord(token);
}

