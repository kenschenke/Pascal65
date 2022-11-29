#include <stdio.h>

struct TestList
{
    int num1;
    int num2;
    int result;
};

struct TestList geTests[] = {
    {  1024,   2048, 0},
    { -2048,  -1024, 0},
    {     0,   1024, 0},
    {-32768,      0, 0},
    {     0,  32767, 0},
    {-32768,  32767, 0},
    { 32767,  32767, 1},
    {  1024,   1024, 1},
    { -2048,  -2048, 1},
    {-32768, -32768, 1},
    {     0,      0, 1},
    {  2048,   1024, 1},
    {  1024,  -2048, 1},
    { -1024,  -2048, 1},
    {     0,  -1024, 1},
    {  1024,      0, 1},
    { 32767,      0, 1},
    { 32767, -32768, 1},
    {     0, -32768, 1},
};

struct TestList gtTests[] = {
    {  1024,   2048, 0},
    { -2048,  -1024, 0},
    {     0,   1024, 0},
    {-32768,      0, 0},
    {     0,  32767, 0},
    {-32768,  32767, 0},
    { 32767,  32767, 0},
    {  1024,   1024, 0},
    { -2048,  -2048, 0},
    {-32768, -32768, 0},
    {  2048,   1024, 1},
    {  1024,  -2048, 1},
    { -1024,  -2048, 1},
    {     0,  -1024, 1},
    {  1024,      0, 1},
    { 32767,      0, 1},
    { 32767, -32768, 1},
    {     0, -32768, 1},
};

struct TestList leTests[] = {
    { -1024,  -2048, 0},
    {  2048,  -1024, 0},
    {  2048,   1024, 0},
    {  2048,   2048, 1},
    { -1024,  -1024, 1},
    {  1024,      0, 0},
    {     0,  -1024, 0},
    { 32767, -32768, 0},
    {     0,      0, 1},
    {-32768, -32768, 1},
    { 32767,  32767, 1},
    {  1024,   2048, 1},
    { -2048,  -1024, 1},
    { -2048,   4096, 1},
    {     0,   1024, 1},
    { -1024,      0, 1},
    {-32768,  32767, 1},
};

struct TestList ltTests[] = {
    { -1024,  -2048, 0},
    {  2048,  -1024, 0},
    {  2048,   1024, 0},
    {  2048,   2048, 0},
    { -1024,  -1024, 0},
    {  1024,      0, 0},
    {     0,  -1024, 0},
    { 32767, -32768, 0},
    {     0,      0, 0},
    {-32768, -32768, 0},
    { 32767,  32767, 0},
    {  1024,   2048, 1},
    { -2048,  -1024, 1},
    { -2048,   4096, 1},
    {     0,   1024, 1},
    { -1024,      0, 1},
    {-32768,  32767, 1},
};

struct TestList eqTests[] = {
    {     5,     10, 0},
    {    -5,     10, 0},
    {     5,    -10, 0},
    {    -5,    -10, 0},
    {-32768,  32767, 0},
    { 32767, -32768, 0},
    {  1234,   1234, 1},
    { -1234,  -1234, 1},
    {-32768, -32768, 1},
    { 32767,  32767, 1},
};

struct TestList addTests[] = {
    {  1111,   2222,   3333},
    { -1111,   1111,      0},
    { -1111,  -2222,  -3333},
    {     0,   1111,   1111},
    {  1111,      0,   1111},
};

struct TestList subTests[] = {
    {  3333,   2222,   1111},
    {  1111,   2222,  -1111},
    {     0,  -1111,   1111},
    {  1111,      0,   1111},
    {  1111,  -2222,   3333},
};

struct TestList multTests[] = {
    {    12,      5,     60},
    {  1234,     -1,  -1234},
    {    -1,   1234,  -1234},
    {     2,  -1234,  -2468},
    {  1111,      3,   3333},
    {  1111,      0,      0},
    {     0,   1111,      0},
    {  1111,     -3,  -3333},
    {    -3,   1111,  -3333},
    { -1111,     -3,   3333},
};

struct TestList divTests[] = {
    {    10,      5,      2},
    {    44,     11,      4},
    {    44,     10,      4},
    {  1234,      0,      0},
    {    12,    123,      0},
    {     0,   1234,      0},
    {   -44,     11,     -4},
    {  1234,      1,   1234},
    {  1234,     -1,  -1234},
    { -1234,      1,  -1234},
    {-32767,      1, -32767},
    {-32768,      1, -32768},
    {-32768,    123,   -266},
    {-32768,   -456,     71},
    {-32767,     -1,  32767},
    { 32767,   1234,     26},
    {  5101,    322,     15},
};

struct TestList modTests[] = {
    {    32,      5,      2},
    {     3,      2,      1},
    {    13,      2,      1},
    {    12,      2,      0},
    {   -32,      5,     -2},
    { 32767,     75,     67},
    {-32768,   5283,  -1070},
    {     0,   1234,      0},
    {     1,   1234,      1},
    {    12,     12,      0},
    {    12,     11,      1},
};

typedef int (*tester)(int, int);

int testEq(int num1, int num2);
int testGe(int num1, int num2);
int testGt(int num1, int num2);
int testLe(int num1, int num2);
int testLt(int num1, int num2);

int testAddInt16(int num1, int num2);
int testDivInt16(int num1, int num2);
int testSubInt16(int num1, int num2);
int testModInt16(int num1, int num2);
int testMultInt16(int num1, int num2);

void testWriteBool(char value, char width);
void testWriteChar(char value, char width);

void testFunc(tester testFn, struct TestList *tests, unsigned nTests)
{
    int ret;
    unsigned i;

    for (i = 0; i < nTests; ++i) {
        ret = testFn(tests[i].num1, tests[i].num2);
        if (ret != tests[i].result) {
            printf("Test %d : expected %d got %d\n", i + 1, tests[i].result, ret);
        }
    }
}

void main()
{
    printf("Testing greater than\n");
    testFunc(testGt, gtTests, sizeof(gtTests)/sizeof(gtTests[0]));

    printf("Testing greater than or equal to\n");
    testFunc(testGe, geTests, sizeof(geTests)/sizeof(geTests[0]));

    printf("Testing less than\n");
    testFunc(testLt, ltTests, sizeof(ltTests)/sizeof(ltTests[0]));

    printf("Testing less than or equal to\n");
    testFunc(testLe, leTests, sizeof(leTests)/sizeof(leTests[0]));

    printf("Testing equality\n");
    testFunc(testEq, eqTests, sizeof(eqTests)/sizeof(eqTests[0]));

    printf("Testing addition\n");
    testFunc(testAddInt16, addTests, sizeof(addTests)/sizeof(addTests[0]));

    printf("Testing subtraction\n");
    testFunc(testSubInt16, subTests, sizeof(subTests)/sizeof(subTests[0]));

    printf("Testing multiplication\n");
    testFunc(testMultInt16, multTests, sizeof(multTests)/sizeof(multTests[0]));

    printf("Testing division\n");
    testFunc(testDivInt16, divTests, sizeof(divTests)/sizeof(divTests[0]));

    printf("Testing mod\n");
    testFunc(testModInt16, modTests, sizeof(modTests)/sizeof(modTests[0]));

    printf("True:  ");
    testWriteBool(1, 5);
    printf("\n");
    printf("False: ");
    testWriteBool(0, 5);
    printf("\n");

    printf("Test Char: ");
    testWriteChar('K', 3);
    printf("\n");

    printf("\nDone running tests\n");

}
