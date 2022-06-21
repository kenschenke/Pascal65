#include <scanner.h>

void getSpecialToken(TOKEN *token, SCANNER *scanner)
{
    char ch = getCurrentChar(scanner->pTinBuf);
    char *ps = token->string;
    
    *ps++ = ch;

    switch (ch) {
        case '^': token->code = tcUpArrow;   ch = getChar(scanner->pTinBuf); break;
        case '*': token->code = tcStar;      ch = getChar(scanner->pTinBuf); break;
        case '(': token->code = tcLParen;    ch = getChar(scanner->pTinBuf); break;
        case ')': token->code = tcRParen;    ch = getChar(scanner->pTinBuf); break;
        case '-': token->code = tcMinus;     ch = getChar(scanner->pTinBuf); break;
        case '+': token->code = tcPlus;      ch = getChar(scanner->pTinBuf); break;
        case '=': token->code = tcEqual;     ch = getChar(scanner->pTinBuf); break;
        case '[': token->code = tcLBracket;  ch = getChar(scanner->pTinBuf); break;
        case ']': token->code = tcRBracket;  ch = getChar(scanner->pTinBuf); break;
        case ';': token->code = tcSemicolon; ch = getChar(scanner->pTinBuf); break;
        case ',': token->code = tcComma;     ch = getChar(scanner->pTinBuf); break;
        case '/': token->code = tcSlash;     ch = getChar(scanner->pTinBuf); break;

        case ':':
            ch = getChar(scanner->pTinBuf);     // : or :=
            if (ch == '=') {
                *ps++ = '=';
                token->code = tcColonEqual;
                getChar(scanner->pTinBuf);
            } else {
                token->code = tcColon;
            }
            break;

        case '<':
            ch = getChar(scanner->pTinBuf);     // < or <= or <>
            if (ch == '=') {
                *ps++ = '=';
                token->code = tcLe;
                getChar(scanner->pTinBuf);
            } else if (ch == '>') {
                *ps++ = '>';
                token->code = tcNe;
                getChar(scanner->pTinBuf);
            } else {
                token->code = tcLt;
            }
            break;

        case '>':
            ch = getChar(scanner->pTinBuf);     // > or >=
            if (ch == '=') {
                *ps++ = '=';
                token->code = tcGe;
                getChar(scanner->pTinBuf);
            } else {
                token->code = tcGt;
            }
            break;

        case '.':
            ch = getChar(scanner->pTinBuf);     // . or ..
            if (ch == '.') {
                *ps++ = '.';
                token->code = tcDotDot;
                getChar(scanner->pTinBuf);
            } else {
                token->code = tcPeriod;
            }
            break;
        
        default:
            token->code = tcError;
            getChar(scanner->pTinBuf);
            Error(errUnrecognizable);
            break;
    }

    *ps = 0;
}
