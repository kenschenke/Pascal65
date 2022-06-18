#include <scanner.h>
#include <string.h>

static void initCharCodeMap(void);
static void skipWhiteSpace(SCANNER *scanner);

TCharCode   charCodeMap[128];

TOKEN *getNextToken(SCANNER *scanner)
{
    skipWhiteSpace(scanner);

    switch (charCodeMap[getCurrentChar(scanner->pTinBuf)]) {
        case ccLetter:
            // printf("Getting word token\n");
            getWordToken(&scanner->token, scanner);
            break;

        case ccDigit:
            // printf("Getting number token\n");
            getNumberToken(&scanner->token, scanner);
            break;

        case ccQuote:
            // printf("Getting string token\n");
            getStringToken(&scanner->token, scanner);
            break;

        case ccSpecial:
            // printf("Getting special token\n");
            getSpecialToken(&scanner->token, scanner);
            break;

        case ccEndOfFile:
            // printf("Getting eof token\n");
            scanner->token.code = tcEndOfFile;
            break;
        
        default:
            // printf("currentChar = '%c' (%d)\n",
            //     getCurrentChar(scanner->pTinBuf),
            //     getCurrentChar(scanner->pTinBuf));
            // printf("Getting ??? token\n");
            break;
    }

    return &scanner->token;
}

static void initCharCodeMap(void)
{
    int i;

    if (charCodeMap['a'] != ccError) {
        return;  // already initialized
    }

    for (i = 97; i <= 122; i++) charCodeMap[i] = ccLetter;
    for (i = 65; i <= 90; i++) charCodeMap[i] = ccLetter;
    for (i = 48; i <= 57; i++) charCodeMap[i] = ccDigit;
    charCodeMap['+' ] = charCodeMap['-' ] = ccSpecial;
    charCodeMap['*' ] = charCodeMap['/' ] = ccSpecial;
    charCodeMap['=' ] = charCodeMap['^' ] = ccSpecial;
    charCodeMap['.' ] = charCodeMap[',' ] = ccSpecial;
    charCodeMap['<' ] = charCodeMap['>' ] = ccSpecial;
    charCodeMap['(' ] = charCodeMap[')' ] = ccSpecial;
    charCodeMap['[' ] = charCodeMap[']' ] = ccSpecial;
    charCodeMap[':' ] = charCodeMap[';' ] = ccSpecial;
    charCodeMap[' ' ] = charCodeMap['\t'] = ccWhiteSpace;
    charCodeMap[13  ] = charCodeMap['\0'] = ccWhiteSpace;
    charCodeMap[10  ] = ccWhiteSpace;  // tab (C64 doesn't have this)
    charCodeMap['\''] = ccQuote;
    charCodeMap[eofChar] = ccEndOfFile;
}

void printToken(TOKEN *token)
{
    switch (token->code) {
        case tcIdentifier:
            if (token->code == tcIdentifier) {
                printf("\t%-18s %-s\n", ">> identifier:", token->string);
            } else {
                printf("\t%-18s %-s\n", ">> reserved word:", token->string);
            }
            break;
        
        case tcNumber:
            printf("\t%-18s %ld\n", ">> integer:", token->value.integer);
            break;
        
        case tcString:
            printf("\t%-18s %-s\n", ">> string:", token->string);
            break;
        
        case tcEndOfFile:
            printf("\t%-18s\n", ">> end of file");
            break;

        default:
            printf("\t%-18s %-s\n", ">> other:", token->string);
            break;
    }
}

static void skipWhiteSpace(SCANNER *scanner)
{
    char ch;

    initCharCodeMap();

    ch = getCurrentChar(scanner->pTinBuf);
    while(1) {
        if (ch == '/') {
            ch = getChar(scanner->pTinBuf);
            if (ch == '/') {
                ch = getLine(scanner->pTinBuf);
            } else {
                putBackChar(scanner->pTinBuf);
                break;
            }
        } else if (ch == '(') {
            ch = getChar(scanner->pTinBuf);
            if (ch == '*') {
                while (1) {
                    ch = getChar(scanner->pTinBuf);
                    if (ch == '*') {
                        ch = getChar(scanner->pTinBuf);
                        if (ch == ')') {
                            break;
                        }
                    }
                }
            } else {
                putBackChar(scanner->pTinBuf);
                break;
            }
        } else if (charCodeMap[ch] != ccWhiteSpace) {
            break;
        }
        ch = getChar(scanner->pTinBuf);
    }
}
