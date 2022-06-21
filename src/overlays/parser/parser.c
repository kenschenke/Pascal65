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
    int i;

    for (i = 0; i <= 127; ++i) charCodeMap[i] = ccError;
    enterGlobalSymtab("input");
    enterGlobalSymtab("output");

    getTokenAppend(scanner, pGlobalIcode);

    // Loop to parse statements until the end of the program.
    do {
        if (scanner_isFatalError(scanner))
            break;

        // Shouldn't see an end of file.
        if (scanner->token.code == tcEndOfFile) {
            Error(errUnexpectedEndOfFile);
            break;
        }

        parseStatement(scanner, pGlobalIcode);

        // If the current token is not a semicolon or the final period,
        // we have a syntax error.  If the current token is an identifier
        // (i.e. the start of the next statement), the error is a missing
        // semicolon.  Otherwise, the error is an unexpected token, and so
        // we skip tokens until we find a semicolon or a period, or until
        // we reach the end of the source file.
        if (scanner->token.code == tcSemicolon && scanner->token.code != tcPeriod) {
            if (scanner->token.code == tcIdentifier) {
                Error(errMissingSemicolon);

                while (scanner->token.code != tcSemicolon &&
                    scanner->token.code != tcPeriod &&
                    scanner->token.code != tcEndOfFile) {
                    getTokenAppend(scanner, pGlobalIcode);
                }
            }
        }

        // Skip over any semicolons before parsing the next statement.
        while (scanner->token.code == tcSemicolon) {
            getTokenAppend(scanner, pGlobalIcode);
        }

#if 0
        // Enter each identifier into the symbol table
        if (token->code == tcIdentifier) {
            SYMTABNODE *pNode = searchSymtab(pGlobalSymtab, token->string);
            if (pNode == NULL) {
                enterSymtab(pGlobalSymtab, token->string);
            }
        }
#endif
    } while (scanner->token.code != tcPeriod);

    // printf("\n%20d source lines.\n", scanner->pTinBuf->currentLineNumber);
    // printf("%20d syntax errors.\n", errorCount);
}

SYMTABNODE *searchGlobalSymtab(const char *pString)
{
    return searchSymtab(pGlobalSymtab, pString);
}
