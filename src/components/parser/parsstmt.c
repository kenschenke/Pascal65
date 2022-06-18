#include <parser.h>
#include <error.h>
#include <icode.h>

void parseAssignment(SCANNER *scanner, ICODE *Icode)
{
    SYMTABNODE *pTargetNode;
    
    // Search for the target variable's identifier and enter it
    // if necessary.  Append the symbol table node handle
    // to the icode.
    pTargetNode = searchGlobalSymtab(scanner->token.string);
    if (!pTargetNode) {
        enterGlobalSymtab(scanner->token.string);
    }

    putSymtabNodeToIcode(Icode, pTargetNode);
    getTokenAppend(scanner, Icode);

    // :=
    if (scanner->token.code == tcColonEqual) {
        getTokenAppend(scanner, Icode);
    } else {
        Error(errMissingColonEqual);
    }

    // <expr>
    parseExpression(scanner, Icode);
}

void parseStatement(SCANNER *scanner, ICODE *Icode)
{
    insertLineMarker(Icode);

    // Only assignment statements for now
    if (scanner->token.code == tcIdentifier) {
        parseAssignment(scanner, Icode);
    }
}

