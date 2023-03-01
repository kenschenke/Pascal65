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

#define ICODETEST_LINE     'L'
#define ICODETEST_MARKER   'M'    // marker to jump to
#define ICODETEST_BRANCHTBL 'B'     // marker for case branch table location
#define ICODETEST_CASEBRANCH 'S'    // case item marker
#define ICODETEST_GO       'G'
#define ICODETEST_POS      'P'    // stored position
#define ICODETEST_NAME     'N'
#define ICODETEST_TOKEN    'T'
#define ICODETEST_INT      'I'
#define ICODETEST_FLOAT    'F'
#define ICODETEST_CHAR     'C'
#define ICODETEST_DONE     99

/**
 * The marker tag indicates that the current position in the Icode is a
 * marker that points to another position in the Icode.  These markers are
 * written at known positions in the Icode to assist the interpreter and
 * compiler in code branching.  The marker tag is followed by a number
 * which corresponds to a position tag.
 * 
 * The position tag indicates a position pointed to by a marker.  The tag
 * includes a number which is referred to by a marker tag.
 * 
 * The case branch table marker points to the location of the branch table.
 * When the test runner sees this tag it jumps to that location in the icode
 * and reads the branch table then jumps back to the current location to
 * process the case expression and each branch.
 * 
 * The case branch tag is indicates an expected case item.  These are used
 * to mark the code position for a case branch.  The tag is supplied with
 * a label value and the branch table is checked for this value to match
 * the current icode location.  If more than more label applies to this
 * branch, a case branch tag appears for each label.
 * 
 * The "go" tag instructs the test runner to jump to a location marker.
 * This is used when testing CASE statements and is needed to jump past
 * the branch table at the end of the last case branch.  This tag expects
 * a marker number.
 */

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
