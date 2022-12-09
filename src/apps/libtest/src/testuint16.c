#include <stdio.h>

struct TestList
{
    unsigned num1;
    unsigned num2;
    int result;
};

struct TestList geUintTests[] = {
    {  1024,   2048, 0},
    {     0,   1024, 0},
    {     0,  65535, 0},
    { 65535,  65535, 1},
    {  1024,   1024, 1},
    {     0,      0, 1},
    {  2048,   1024, 1},
    {  1024,      0, 1},
    { 65535,      0, 1},
};

struct TestList gtUintTests[] = {
    {  1024,   2048, 0},
    {     0,   1024, 0},
    {     0,  65535, 0},
    { 65535,  65535, 0},
    {  1024,   1024, 0},
    {  2048,   1024, 1},
    {  1024,      0, 1},
    { 65535,      0, 1},
};

struct TestList leUintTests[] = {
    {  2048,   1024, 0},
    {  2048,   2048, 1},
    {  1024,      0, 0},
    {     0,      0, 1},
    { 65535,  65535, 1},
    {  1024,   2048, 1},
    {     0,   1024, 1},
};

struct TestList ltUintTests[] = {
    {  2048,   1024, 0},
    {  2048,   2048, 0},
    {  1024,      0, 0},
    {     0,      0, 0},
    { 65535,  65535, 0},
    { 65535,      0, 0},
    { 65535,  65534, 0},
    {  1024,   2048, 1},
    {     0,   1024, 1},
    { 0x1111, 0x1112, 1},
    { 0,      65535, 1},
    { 65534,  65535, 1},
};

#if 0
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
#endif

int testUintEq(unsigned num1, unsigned num2);
int testUintGe(unsigned num1, unsigned num2);
int testUintGt(unsigned num1, unsigned num2);
int testUintLe(unsigned num1, unsigned num2);
int testUintLt(unsigned num1, unsigned num2);

#if 0
int testAddInt16(int num1, int num2);
int testDivInt16(int num1, int num2);
int testSubInt16(int num1, int num2);
int testModInt16(int num1, int num2);
int testMultInt16(int num1, int num2);

void testWriteInt16(int num, char width);
#endif

typedef int (*tester)(unsigned, unsigned);

// int testReadInt16(char *p);

void testFuncUint16(tester testFn, struct TestList *tests, unsigned nTests)
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

#if 0
void testReads()
{
    unsigned i;
    int ret;

    for (i = 0; i < sizeof(readTests)/sizeof(readTests[0]); ++i) {
        ret = testReadInt16(readTests[i].str);
        if (ret != readTests[i].num) {
            printf("Test %d : expected %d got %d\n", i + 1, readTests[i].num, ret);
        }
    }
}
#endif

void testUint16(void)
{
    printf("Testing uint16 greater than\n");
    testFuncUint16(testUintGt, gtUintTests, sizeof(gtUintTests)/sizeof(gtUintTests[0]));

    printf("Testing uint16 greater than or equal to\n");
    testFuncUint16(testUintGe, geUintTests, sizeof(geUintTests)/sizeof(geUintTests[0]));

    printf("Testing uint16 less than\n");
    testFuncUint16(testUintLt, ltUintTests, sizeof(ltUintTests)/sizeof(ltUintTests[0]));

    printf("Testing uint16 less than or equal to\n");
    testFuncUint16(testUintLe, leUintTests, sizeof(leUintTests)/sizeof(leUintTests[0]));

#if 0
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
#endif

#if 0
    testWriteInt16(-32768, 10);
    printf("\n");
    testWriteInt16(32767, 10);
    printf("\n");
    testWriteInt16(-1234, 10);
    printf("\n");
    testWriteInt16(12, 10);
    printf("\n");

    testReads();
#endif
}

