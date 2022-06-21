#include <scanner.h>
#include <limits.h>

void getNumberToken(TOKEN *token, SCANNER *scanner)
{
    const int maxInteger = SHRT_MAX;
    char ch, *ps;
    int digitCount = 0;
    int countErrorFlag = 0;
    const int maxDigitCount = 20;
    int value = 0;

    ch = getCurrentChar(scanner->pTinBuf);
    if (charCodeMap[ch] != ccDigit) {
        Error(errInvalidNumber);
        return;  // failure
    }

    // Acculumate the value as long as the total allowable
    // number of digits has not been exceeded.
    ps = token->string;
    do {
        *ps++ = ch;

        if (++digitCount <= maxDigitCount) {
            value = 10 * value + (ch - '0');
        } else {
            countErrorFlag = 1;
        }

        ch = getChar(scanner->pTinBuf);
    } while (charCodeMap[ch] == ccDigit);

    *ps = 0;
    token->value.integer = value;
    token->code = countErrorFlag ? tcError : tcNumber;
}
