#include <parser.h>
#include <scanner.h>
#include <error.h>
#include <common.h>
#include <symtab.h>

static void getToken(SCANNER *scanner);

SYMTABNODE *enterGlobalSymtab(const char *pString)
{
    return enterSymtab(pGlobalSymtab, pString);
}

static void getToken(SCANNER *scanner)
{
    getNextToken(scanner);
}

void getTokenAppend(SCANNER *scanner, ICODE *Icode)
{
    getToken(scanner);
    putTokenToIcode(Icode, scanner->token.code);
}

void parse(SCANNER *scanner)
{
    TOKEN *token;
    int i;

    for (i = 0; i <= 127; ++i) charCodeMap[i] = ccError;

    do {
        token = getNextToken(scanner);
        if (scanner_isFatalError(scanner))
            break;
        // Enter each identifier into the symbol table
        if (token->code == tcIdentifier) {
            SYMTABNODE *pNode = searchSymtab(pGlobalSymtab, token->string);
            if (pNode == NULL) {
                enterSymtab(pGlobalSymtab, token->string);
            }
        }
    } while (token->code != tcEndOfFile);

    // printf("\n%20d source lines.\n", scanner->pTinBuf->currentLineNumber);
    // printf("%20d syntax errors.\n", errorCount);
}

SYMTABNODE *searchGlobalSymtab(const char *pString)
{
    return searchSymtab(pGlobalSymtab, pString);
}
