#include <buffer.h>
#include <parser.h>
#include <common.h>
#include <symtab.h>
#include <string.h>

/**
 * 
 * Structure of source tree
 * 
 * /include
 * /src/common          symbol table, error handling
 * /src/parser          input buffer, scanner, parser, tokenizer
 * /src/icode           intermediate code
 * /src/executor        run-time interpreter
 * /src/compiler        machine code generation
 * /src/editor
 * /tests
 * 
 */

static int div(int n1, int n2)
{
    int n = 0;
    int neg = 0;

    if (n2 == 0) {
        // TODO: runtime error
        return 0;
    }

    if (n1 < 0 && n2 < 0) {
        n1 = -n1;
        n2 = -n2;
    } else if (n1 < 0) {
        n1 = -n1;
        neg = 1;
    } else if (n2 < 0) {
        n2 = -n2;
        neg = 1;
    }

    while (n1 > n2) {
        n1 -= n2;
        n++;
    }

    return neg ? -n : n;
}

static int mult(int n1, int n2)
{
    int i;
    int neg = 0;
    int total = 0;

    if (n1 == 0 || n2 == 0) {
        return 0;
    }

    if (n1 < 0 && n2 < 0) {
        n1 = -n1;
        n2 = -n2;
    } else if (n1 < 0) {
        n1 = -n1;
        neg = 1;
    } else if (n2 < 0) {
        n2 = -n2;
        neg = 1;
    }

    for (i = 0; i < n2; i++) {
        total += n1;
    }

    return neg ? -total : total;
}

static void testDiv(int n1, int n2)
{
    printf("%d / %d = %d\n", n1, n2, div(n1, n2));
}

static void testMult(int n1, int n2)
{
    printf("%d x %d = %d\n", n1, n2, mult(n1, n2));
}

void main()
{
#if 0
    char str[5];
    int i;
    TINBUF *tinBuf;
    SCANNER scanner;

    initCommon();

    tinBuf = openTextInBuffer("hello.pas,s", abortSourceFileOpenFailed);
    scanner.pTinBuf = tinBuf;
    parse(&scanner);

    closeTextInBuffer(tinBuf);

    printSymtab(pGlobalSymtab);
#endif

    int a, b, r;
    a = 8;
    b = 9;
    r = a * b;
    printf("%d x %d = %d\n", a, b, r);

#if 0
    testMult(3, 5);
    testMult(81, 72);
    testMult(6, -5);
    testMult(10, 0);
    testMult(-8, -7);

    testDiv(16, 3);
    testDiv(20, 6);
    testDiv(5, 8);
    testDiv(21, -6);
    testDiv(-21, -6);
    testDiv(81, 14);
    testDiv(23423, 345);

    printf("15 %% 4 = %d\n", 15 % 4);
#endif
}