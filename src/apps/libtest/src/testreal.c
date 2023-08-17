#include <stdio.h>
#include <string.h>

static struct CompTest
{
    const char *Op1;
    const char *Op2;
    char ExpectedResult;
};

static struct MathTest
{
    const char *Op1;
    const char *Op2;
    const char *Expected;
};

static struct StrTest
{
    const char *Start;
    const char *Expected;
    unsigned char Precision;
};

static struct StrTest StrTests[] = {
    // Basic string parsing
    {"1.1",       "0.1100000e+01", -1},
    {"3.14159",   "0.3141589e+01", -1},
    {"-1.23",    "-0.1230000e+01", -1},
    {"0.001",     "0.999999e-03",  -1},
    {"0.00123",   "0.1229999e-02", -1},
    {"123.1e+15", "0.1231000e+18", -1},
    {"123.1e-16", "0.1230996e-13", -1},
    // Rounding
    {"1.1",       "1",              0},
    {"1.6",       "2",              0},
    {"-1.1",      "-1",             0},
    {"-1.6",      "-2",             0},
    {"1.124",     "1.12",           2},
    {"1.225",     "1.23",           2},
    {"1.226",     "1.23",           2},
    {"1.1",       "1.10",           2},
    {"-1.124",   "-1.12",           2},
    {"-1.125",   "-1.13",           2},
    {"-1.226",   "-1.23",           2},
    {"-1.1",     "-1.10",           2},
    {"0",        "0.00",            2},
    {"1",        "1.00",            2},
    {"-1",       "-1.00",           2},
    {"1.00",     "1",               0},
    {"0.4",      "0",               0},
    {"-0.4",     "0",               0},
};

static struct CompTest EqTests[] = {
    {"1.01",   "3.23",    0},
    {"1.01",   "-3.23",   0},
    {"-1.01",  "3.23",    0},
    {"-1.01",  "-3.23",   0},
    {"-3.23",  "-1.01",   0},
    {"3.23",   "1.01",    0},
    {"-1.01",  "0.5",     0},
    {"1",      "1",       1},
    {"0",      "0",       1},
    {"-1",     "-1",      1},
    {"1.01",   "0",       0},
    {"-1.01",  "0",       0},
    {"0",      "1.01",    0},
    {"0",      "-1.01",   0},
    {"1.23e5", "1.23e-5", 0},
    {"1.001",  "1.001",   1},
    {"-1.001", "-1.001",  1},
    {"1.23e5", "1.23e5",  1},
    {"1.2e-9", "1.2e-9",  1},
};

static struct CompTest GtTests[] = {
    {"1.01",   "3.23",    0},
    {"1.01",   "-3.23",   1},
    {"-1.01",  "3.23",    0},
    {"-1.01",  "-3.23",   1},
    {"-3.23",  "-1.01",   0},
    {"3.23",   "1.01",    1},
    {"-1.01",  "0.5",     0},
    {"1",      "1",       0},
    {"0",      "0",       0},
    {"-1",     "-1",      0},
    {"1.01",   "0",       1},
    {"-1.01",  "0",       0},
    {"0",      "1.01",    0},
    {"0",      "-1.01",   1},
    {"1.23e5", "1.23e-5", 1},
};

static struct CompTest GteTests[] = {
    {"1.01",   "3.23",    0},
    {"1.01",   "-3.23",   1},
    {"-1.01",  "3.23",    0},
    {"-1.01",  "-3.23",   1},
    {"-3.23",  "-1.01",   0},
    {"3.23",   "1.01",    1},
    {"-1.01",  "0.5",     0},
    {"1",      "1",       1},
    {"0",      "0",       1},
    {"-1",     "-1",      1},
    {"1.01",   "0",       1},
    {"-1.01",  "0",       0},
    {"0",      "1.01",    0},
    {"0",      "-1.01",   1},
    {"1.23e5", "1.23e-5", 1},
};

static struct CompTest LtTests[] = {
    {"1.01",   "3.23",    1},
    {"1.01",   "-3.23",   0},
    {"-1.01",  "3.23",    1},
    {"-1.01",  "-3.23",   0},
    {"-3.23",  "-1.01",   1},
    {"3.23",   "1.01",    0},
    {"-1.01",  "0.5",     1},
    {"1",      "1",       0},
    {"0",      "0",       0},
    {"-1",     "-1",      0},
    {"1.01",   "0",       0},
    {"-1.01",  "0",       1},
    {"0",      "1.01",    1},
    {"0",      "-1.01",   0},
    {"1.23e5", "1.23e-5", 0},
};

static struct CompTest LteTests[] = {
    {"1.01",   "3.23",    1},
    {"1.01",   "-3.23",   0},
    {"-1.01",  "3.23",    1},
    {"-1.01",  "-3.23",   0},
    {"-3.23",  "-1.01",   1},
    {"3.23",   "1.01",    0},
    {"-1.01",  "0.5",     1},
    {"1",      "1",       1},
    {"0",      "0",       1},
    {"-1",     "-1",      1},
    {"1.01",   "0",       0},
    {"-1.01",  "0",       1},
    {"0",      "1.01",    1},
    {"0",      "-1.01",   0},
    {"1.23e5", "1.23e-5", 0},
};

static struct MathTest AddTests[] = {
    {"1.01",  "3.23",  "4.24"},
    {"0",     "3.23",  "3.23"},
    {"1.01",  "-3.23", "-2.22"},
    {"-3.23", "1.01", "-2.22"},
    {"3.23",  "0",    "3.23"},
};

static struct MathTest SubTests[] = {
    {"1.01",  "3.23",  "-2.22"},
    {"-3.23", "-1.01", "-2.22"},
    {"3.23",  "1.01",  "2.22"},
    {"-1.01", "0",     "-1.01"},
    {"0",     "1.01",  "-1.01"},
    {"0",     "-1.01", "1.01"},
    {"0",     "0",     "0.00"},
};

static struct MathTest MultTests[] = {
    {"12.23", "4.336", "53.03"},
    {"35", "0.5", "17.50"},
    {"22.546", "-13.244", "-298.60"},
    {"2245.44", "-1", "-2245.44"},
    {"1234", "0", "0.00"},
    {"0", "1234", "0.00"},
};

static struct MathTest DivTests[] = {
    {"123.45",  "4.32356",  "28.55"},
    {"45.32",   "125.109",  "0.36"},
    {"55.652",  "-2.34543", "-23.73"},
    {"-12.604", "18.344",   "-0.69"},
    {"0",       "1234",     "0.00"},
};

static void doAddTests(void);
static void doDivTests(void);
static void doEqTests(void);
static void doGtTests(void);
static void doGteTests(void);
static void doLtTests(void);
static void doLteTests(void);
static void doMultTests(void);
static void doStrTests(void);
static void doSubTests(void);

void floatAdd(const char *buffer);
void floatDiv(const char *buffer);
char floatEq(void);
char floatGt(void);
char floatGte(void);
char floatLt(void);
char floatLte(void);
void floatMult(const char *buffer);
void floatStrTest(const char *input, char *buffer, unsigned char precision);
void floatSub(const char *buffer);
void saveOps(const char *Op1, const char *Op2);

static void doAddTests(void) {
    unsigned i;
    char buf[15];

    for (i = 0; i < sizeof(AddTests)/sizeof(AddTests[0]); ++i) {
        saveOps(AddTests[i].Op1, AddTests[i].Op2);
        floatAdd(buf);
        if (strcmp(buf, AddTests[i].Expected)) {
            printf("*** ERROR FLOAT SUB TEST ***\n");
            printf("       Test %s + %s\n", AddTests[i].Op1, AddTests[i].Op2);
            printf("   Expected \"%s\"\n", AddTests[i].Expected);
            printf("        Got \"%s\"\n", buf);
        }
    }
}

static void doDivTests(void) {
    unsigned i;
    char buf[15];

    for (i = 0; i < sizeof(DivTests)/sizeof(DivTests[0]); ++i) {
        saveOps(DivTests[i].Op1, DivTests[i].Op2);
        floatDiv(buf);
        if (strcmp(buf, DivTests[i].Expected)) {
            printf("*** ERROR FLOAT SUB TEST ***\n");
            printf("       Test %s / %s\n", DivTests[i].Op1, DivTests[i].Op2);
            printf("   Expected \"%s\"\n", DivTests[i].Expected);
            printf("        Got \"%s\"\n", buf);
        }
    }
}

static void doEqTests(void) {
    char actualResult;
    unsigned i;

    for (i = 0; i < sizeof(EqTests)/sizeof(EqTests[0]); ++i) {
        saveOps(EqTests[i].Op1, EqTests[i].Op2);
        actualResult = floatEq();
        if (actualResult != EqTests[i].ExpectedResult) {
            printf("*** ERROR FLOAT TEST ***\n");
            printf("       Test %s == %s\n", EqTests[i].Op1, EqTests[i].Op2);
            printf("   Expected %d\n", EqTests[i].ExpectedResult);
            printf("        Got %d\n", actualResult);
        }
    }
}

static void doGtTests(void) {
    char actualResult;
    unsigned i;

    for (i = 0; i < sizeof(GtTests)/sizeof(GtTests[0]); ++i) {
        saveOps(GtTests[i].Op1, GtTests[i].Op2);
        actualResult = floatGt();
        if (actualResult != GtTests[i].ExpectedResult) {
            printf("*** ERROR FLOAT TEST ***\n");
            printf("       Test %s > %s\n", GtTests[i].Op1, GtTests[i].Op2);
            printf("   Expected %d\n", GtTests[i].ExpectedResult);
            printf("        Got %d\n", actualResult);
        }
    }
}

static void doGteTests(void) {
    char actualResult;
    unsigned i;

    for (i = 0; i < sizeof(GteTests)/sizeof(GteTests[0]); ++i) {
        saveOps(GteTests[i].Op1, GteTests[i].Op2);
        actualResult = floatGte();
        if (actualResult != GteTests[i].ExpectedResult) {
            printf("*** ERROR FLOAT TEST ***\n");
            printf("       Test %s >= %s\n", GteTests[i].Op1, GteTests[i].Op2);
            printf("   Expected %d\n", GteTests[i].ExpectedResult);
            printf("        Got %d\n", actualResult);
        }
    }
}

static void doLtTests(void) {
    char actualResult;
    unsigned i;

    for (i = 0; i < sizeof(LtTests)/sizeof(LtTests[0]); ++i) {
        saveOps(LtTests[i].Op1, LtTests[i].Op2);
        actualResult = floatLt();
        if (actualResult != LtTests[i].ExpectedResult) {
            printf("*** ERROR FLOAT TEST ***\n");
            printf("       Test %s < %s\n", LtTests[i].Op1, LtTests[i].Op2);
            printf("   Expected %d\n", LtTests[i].ExpectedResult);
            printf("        Got %d\n", actualResult);
        }
    }
}

static void doLteTests(void) {
    char actualResult;
    unsigned i;

    for (i = 0; i < sizeof(LteTests)/sizeof(LteTests[0]); ++i) {
        saveOps(LteTests[i].Op1, LteTests[i].Op2);
        actualResult = floatLte();
        if (actualResult != LteTests[i].ExpectedResult) {
            printf("*** ERROR FLOAT TEST ***\n");
            printf("       Test %s <= %s\n", LteTests[i].Op1, LteTests[i].Op2);
            printf("   Expected %d\n", LteTests[i].ExpectedResult);
            printf("        Got %d\n", actualResult);
        }
    }
}

static void doMultTests(void) {
    unsigned i;
    char buf[15];

    for (i = 0; i < sizeof(MultTests)/sizeof(MultTests[0]); ++i) {
        saveOps(MultTests[i].Op1, MultTests[i].Op2);
        floatMult(buf);
        if (strcmp(buf, MultTests[i].Expected)) {
            printf("*** ERROR FLOAT SUB TEST ***\n");
            printf("       Test %s * %s\n", MultTests[i].Op1, MultTests[i].Op2);
            printf("   Expected \"%s\"\n", MultTests[i].Expected);
            printf("        Got \"%s\"\n", buf);
        }
    }
}

static void doStrTests(void) {
    unsigned i;
    char buf[15];

    for (i = 0; i < sizeof(StrTests)/sizeof(StrTests[0]); ++i) {
        floatStrTest(StrTests[i].Start, buf, StrTests[i].Precision);
        if (strcmp(buf, StrTests[i].Expected)) {
            printf("*** ERROR FLOAT STR TEST ***\n");
            printf("       Test %d\n", i + 1);
            printf("   Expected \"%s\"\n", StrTests[i].Expected);
            printf("        Got \"%s\"\n", buf);
        }
    }
}

static void doSubTests(void) {
    unsigned i;
    char buf[15];

    for (i = 0; i < sizeof(SubTests)/sizeof(SubTests[0]); ++i) {
        saveOps(SubTests[i].Op1, SubTests[i].Op2);
        floatSub(buf);
        if (strcmp(buf, SubTests[i].Expected)) {
            printf("*** ERROR FLOAT SUB TEST ***\n");
            printf("       Test %s - %s\n", SubTests[i].Op1, SubTests[i].Op2);
            printf("   Expected \"%s\"\n", SubTests[i].Expected);
            printf("        Got \"%s\"\n", buf);
        }
    }
}

void testReal(void)
{
    doStrTests();
    doLtTests();
    doLteTests();
    doGtTests();
    doGteTests();
    doEqTests();
    doAddTests();
    doSubTests();
    doMultTests();
    doDivTests();
}
