#ifndef PARSERTEST_H
#define PARSERTEST_H

#include <misc.h>
#include <membuf.h>
#include <symtab.h>
#include <scanner.h>

#define BOOLEAN_TYPE 1
#define REAL_TYPE 2
#define INTEGER_TYPE 3
#define CHAR_TYPE 4
#define EN_TYPE 5   // "en" enum type
#define NONE_TYPE 6

extern CHUNKNUM testIcode;
extern TOKEN testToken;
extern SYMBNODE testNode;

typedef void (*testRunner)(CHUNKNUM);

#define assertTokenCode(expected) assertTokenCodeX(expected, __FILE__, testName, __LINE__)
#define assertNodeName(chunk, name) assertNodeNameX(chunk, name, __FILE__, testName, __LINE__)

#define ICODETEST_LINE  'L'
#define ICODETEST_NAME  'N'
#define ICODETEST_TOKEN 'T'
#define ICODETEST_INT   'I'
#define ICODETEST_FLOAT 'F'
#define ICODETEST_CHAR  'C'
#define ICODETEST_DONE  99

struct ArrayTestCase {
    char elemType;  // elemType is NULL in last test case
    char indexBaseType;
    int minIndex;
    int maxIndex;
    int elemCount;
    struct ArrayTestCase *subArray;
};

struct IcodeTestCase {
    char test;  // one of ICODETEST_*
    unsigned long value;
    const char *string;
};

struct VarTestCase {
    const char *name;   // name is NULL in last test case
    char type;
    char baseType;
};

void assertNodeNameX(CHUNKNUM chunk, const char *name,
    const char *file, const char *test, int line);
void assertTokenCodeX(TTokenCode expected,
    const char *file, const char *test, int line);

void getNextTestToken(void);
CHUNKNUM getTypeFromDefine(char type);
void readLocnMarker(MEMBUF_LOCN *locn);
void runArrayTests(CHUNKNUM variableIds, struct ArrayTestCase *tests, const char *testName);
void runIcodeTests(const char *testFile, int firstLine, const char *testName);
void runVarTests(CHUNKNUM variableIds, struct VarTestCase *tests, int level, const char *testName);

#endif // end of PARSERTEST_H
