#include <formatter.h>
#include <icode.h>
#include <parscommon.h>

void fmtPrintAssignmentOrCall(CHUNKNUM Icode, SYMBNODE *pNode, TOKEN *pToken) {
    fmtPrintIdentifier(Icode, pNode, pToken);

    if (pToken->code == tcColonEqual) {
        fmtPut(" := ");

        getNextTokenFromIcode(Icode, pToken, pNode);
        fmtPrintExpression(Icode, pNode, pToken);
    }
}

void fmtPrintCASE(CHUNKNUM Icode, SYMBNODE *pNode, TOKEN *pToken) {
    fmtPut("CASE ");

    getNextTokenFromIcode(Icode, pToken, pNode);
    fmtPrintExpression(Icode, pNode, pToken);
    fmtPutLine(" OF ");

    fmtIndent();
    getNextTokenFromIcode(Icode, pToken, pNode);

    // Loop to print CASE branches.
    while (pToken->code != tcEND) {
        // Loop to print the CASE labels of a branch.
        do {
            fmtPrintExpression(Icode, pNode, pToken);
            if (pToken->code == tcComma) {
                fmtPut(", ");
                getNextTokenFromIcode(Icode, pToken, pNode);
            }
        } while (pToken->code != tcColon);

        fmtPutLine(":");
        
        fmtIndent();
        getNextTokenFromIcode(Icode, pToken, pNode);
        fmtPrintStatement(Icode, pNode, pToken);
        fmtDetent();
    }

    fmtDetent();
    fmtPut("END");
    getNextTokenFromIcode(Icode, pToken, pNode);
}

void fmtPrintCompound(CHUNKNUM Icode, SYMBNODE *pNode, TOKEN *pToken) {
    fmtPutLine("BEGIN");
    fmtIndent();

    getNextTokenFromIcode(Icode, pToken, pNode);
    fmtPrintStatementList(Icode, pNode, pToken, tcEND);

    fmtDetent();
    fmtPut("END");

    getNextTokenFromIcode(Icode, pToken, pNode);
}

void fmtPrintExpression(CHUNKNUM Icode, SYMBNODE *pNode, TOKEN *pToken) {
    char doneFlag = 0;  // non-zero if done with expression, 0 if note

    // Loop over the entire expresion
    do {
        switch (pToken->code) {
            case tcIdentifier:
                fmtPrintIdentifier(Icode, pNode, pToken);
                break;

            case tcNumber: fmtPut(pToken->string); getNextTokenFromIcode(Icode, pToken, pNode); break;
            case tcString: fmtPut(pToken->string); getNextTokenFromIcode(Icode, pToken, pNode); break;

            case tcPlus:  fmtPut(" + ");   getNextTokenFromIcode(Icode, pToken, pNode); break;
            case tcMinus: fmtPut(" - ");   getNextTokenFromIcode(Icode, pToken, pNode); break;
            case tcStar:  fmtPut("*");     getNextTokenFromIcode(Icode, pToken, pNode); break;
            case tcSlash: fmtPut("/");     getNextTokenFromIcode(Icode, pToken, pNode); break;
            case tcDIV:   fmtPut(" DIV "); getNextTokenFromIcode(Icode, pToken, pNode); break;
            case tcMOD:   fmtPut(" MOD "); getNextTokenFromIcode(Icode, pToken, pNode); break;
            case tcAND:   fmtPut(" AND "); getNextTokenFromIcode(Icode, pToken, pNode); break;
            case tcOR:    fmtPut(" OR ");  getNextTokenFromIcode(Icode, pToken, pNode); break;
            case tcEqual: fmtPut(" = ");   getNextTokenFromIcode(Icode, pToken, pNode); break;
            case tcNe:    fmtPut(" <> ");  getNextTokenFromIcode(Icode, pToken, pNode); break;
            case tcLt:    fmtPut(" < ");   getNextTokenFromIcode(Icode, pToken, pNode); break;
            case tcLe:    fmtPut(" <= ");  getNextTokenFromIcode(Icode, pToken, pNode); break;
            case tcGt:    fmtPut(" > ");   getNextTokenFromIcode(Icode, pToken, pNode); break;
            case tcGe:    fmtPut(" >= ");  getNextTokenFromIcode(Icode, pToken, pNode); break;
            case tcNOT:   fmtPut("NOT ");  getNextTokenFromIcode(Icode, pToken, pNode); break;

            case tcLParen:
                fmtPut("(");
                getNextTokenFromIcode(Icode, pToken, pNode);
                fmtPrintExpression(Icode, pNode, pToken);
                fmtPut(")");
                getNextTokenFromIcode(Icode, pToken, pNode);
                break;

            default:
                doneFlag = 1;
                break;
        }
    } while (!doneFlag);
}

void fmtPrintFOR(CHUNKNUM Icode, SYMBNODE *pNode, TOKEN *pToken) {
    fmtPut("FOR ");

    getNextTokenFromIcode(Icode, pToken, pNode);
    fmtPrintIdentifier(Icode, pNode, pToken);
    fmtPut(" := ");

    getNextTokenFromIcode(Icode, pToken, pNode);
    fmtPrintExpression(Icode, pNode, pToken);
    fmtPut(pToken->code == tcTO ? " TO " : " DOWNTO ");

    getNextTokenFromIcode(Icode, pToken, pNode);
    fmtPrintExpression(Icode, pNode, pToken);
    fmtPutLine(" DO");

    fmtIndent();
    getNextTokenFromIcode(Icode, pToken, pNode);
    fmtPrintStatement(Icode, pNode, pToken);
    fmtDetent();
}

static TTokenCode tlIdModStart[] = {tcLBracket, tcLParen, tcPeriod, tcDummy};
static TTokenCode tlIdModEnd[] = {tcRBracket, tcRParen, tcDummy};

void fmtPrintIdentifier(CHUNKNUM Icode, SYMBNODE *pNode, TOKEN *pToken) {
    int saveMargin;

    fmtPut(pToken->string);
    getNextTokenFromIcode(Icode, pToken, pNode);

    // Loop to print any modifiers (subscripts, record fields, or
    // actual parameter lists).
    while (tokenIn(pToken->code, tlIdModStart)) {
        // Record field
        if (pToken->code == tcPeriod) {
            fmtPut(".");
            getNextTokenFromIcode(Icode, pToken, pNode);
            fmtPrintIdentifier(Icode, pNode, pToken);
        }

        // Subscripts or actual parameters
        else {
            // Set margin for actual parameters
            if (pToken->code == tcLParen) {
                fmtPut("(");
                saveMargin = fmtSetMargin();
            } else {
                fmtPut("[");
            }

            getNextTokenFromIcode(Icode, pToken, pNode);

            while (!tokenIn(pToken->code, tlIdModEnd)) {
                fmtPrintExpression(Icode, pNode, pToken);

                // Write and writeln field width and precision
                while (pToken->code == tcColon) {
                    fmtPut(":");
                    getNextTokenFromIcode(Icode, pToken, pNode);
                    fmtPrintExpression(Icode, pNode, pToken);
                }

                if (pToken->code == tcComma) {
                    fmtPut(", ");
                    getNextTokenFromIcode(Icode, pToken, pNode);
                }
            }

            // Reset actual parameter margin
            if (pToken->code == tcRParen) {
                fmtPut(")");
                fmtResetMargin(saveMargin);
            } else {
                fmtPut("]");
            }

            getNextTokenFromIcode(Icode, pToken, pNode);
        }
    }
}

void fmtPrintIF(CHUNKNUM Icode, SYMBNODE *pNode, TOKEN *pToken) {
    fmtPut("IF ");

    getNextTokenFromIcode(Icode, pToken, pNode);
    fmtPrintExpression(Icode, pNode, pToken);
    fmtPutLine(" THEN");

    fmtIndent();
    getNextTokenFromIcode(Icode, pToken, pNode);
    fmtPrintStatement(Icode, pNode, pToken);
    fmtDetent();

    if (pToken->code == tcELSE) {
        fmtPutLine("ELSE");

        fmtIndent();
        getNextTokenFromIcode(Icode, pToken, pNode);
        fmtPrintStatement(Icode, pNode, pToken);
        fmtDetent();
    }
}

void fmtPrintStatement(CHUNKNUM Icode, SYMBNODE *pNode, TOKEN *pToken) {
    switch (pToken->code) {
        case tcIdentifier: fmtPrintAssignmentOrCall(Icode, pNode, pToken); break;
        case tcBEGIN:      fmtPrintCompound(Icode, pNode, pToken);         break;
        case tcREPEAT:     fmtPrintREPEAT(Icode, pNode, pToken);           break;
        case tcWHILE:      fmtPrintWHILE(Icode, pNode, pToken);            break;
        case tcIF:         fmtPrintIF(Icode, pNode, pToken);               break;
        case tcFOR:        fmtPrintFOR(Icode, pNode, pToken);              break;
        case tcCASE:       fmtPrintCASE(Icode, pNode, pToken);             break;
    }

    while (pToken->code == tcSemicolon) {
        fmtPut(";");
        getNextTokenFromIcode(Icode, pToken, pNode);
    }

    fmtPutLine("");
}

void fmtPrintREPEAT(CHUNKNUM Icode, SYMBNODE *pNode, TOKEN *pToken) {
    int saveMargin;

    fmtPutLine("REPEAT");
    fmtIndent();

    getNextTokenFromIcode(Icode, pToken, pNode);
    fmtPrintStatementList(Icode, pNode, pToken, tcUNTIL);

    fmtDetent();
    fmtPut("UNTIL ");
    saveMargin = fmtSetMargin();

    getNextTokenFromIcode(Icode, pToken, pNode);
    fmtPrintExpression(Icode, pNode, pToken);
    fmtResetMargin(saveMargin);
}

void fmtPrintStatementList(CHUNKNUM Icode, SYMBNODE *pNode, TOKEN *pToken, TTokenCode terminator) {
    while (pToken->code != terminator) {
        fmtPrintStatement(Icode, pNode, pToken);
    }
}

void fmtPrintWHILE(CHUNKNUM Icode, SYMBNODE *pNode, TOKEN *pToken) {
    int saveMargin;

    fmtPut("WHILE ");
    saveMargin = fmtSetMargin();
    getNextTokenFromIcode(Icode, pToken, pNode);
    fmtPrintExpression(Icode, pNode, pToken);
    fmtResetMargin(saveMargin);
    fmtPutLine(" DO");

    fmtIndent();
    getNextTokenFromIcode(Icode, pToken, pNode);
    fmtPrintStatement(Icode, pNode, pToken);
    fmtDetent();
}

