#include "parsertest.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <chunks.h>
#include <tests.h>
#include <icode.h>
#include <ctype.h>
#include <membuf.h> 
#include <common.h>

#define MAX_MARKERS 8

CHUNKNUM testIcode;
TOKEN testToken;
SYMBNODE testNode;

static void checkArray(struct ArrayTestCase *arrayCase, TTYPE *arrayType,
    const char *testName, int testNumber);
static void checkEnumType(TTYPE *pType, int max,
    const char *testName, int testNumber);
static void checkIndexType(CHUNKNUM typeChunk, char indexBaseType, int min, int max,
    const char *testName, int testNumber);
static void checkSubrangeType(TTYPE *pType, char indexBaseType, int min, int max,
    const char *testName, int testNumber);
static void checkTypeName(CHUNKNUM typeChunk, char expected,
    const char *testName, int testNumber);
static void errorHeader(const char *test, int number);

static void checkArray(struct ArrayTestCase *arrayCase, TTYPE *arrayType,
    const char *testName, int testNumber) {

    checkIndexType(arrayType->array.indexType, arrayCase->indexBaseType,
        arrayCase->minIndex, arrayCase->maxIndex, testName, testNumber);

    if (arrayCase->subArray == NULL) {
        checkTypeName(arrayType->array.elemType, arrayCase->elemType, testName, testNumber);
    }

    if (arrayCase->minIndex != arrayType->array.minIndex) {
        errorHeader(testName, testNumber);
        printf("   Expected min index %d -- got %d\n",
            arrayCase->minIndex, arrayType->array.minIndex);
        exit(5);
    }

    if (arrayCase->maxIndex != arrayType->array.maxIndex) {
        errorHeader(testName, testNumber);
        printf("   Expected max index %d -- got %d\n",
            arrayCase->maxIndex, arrayType->array.maxIndex);
        exit(5);
    }

    if (arrayCase->elemCount != arrayType->array.elemCount) {
        errorHeader(testName, testNumber);
        printf("   Expected element count %d -- got %d\n",
            arrayCase->elemCount, arrayType->array.elemCount);
        exit(5);
    }

    if (arrayCase->subArray) {
        TTYPE subType;

        retrieveChunk(arrayType->array.elemType, (unsigned char *)&subType);
        checkArray(arrayCase->subArray, &subType, testName, testNumber);
    }
}

static void checkEnumType(TTYPE *pType, int max,
    const char *testName, int testNumber) {

    if (pType->enumeration.max != max) {
        errorHeader(testName, testNumber);
        printf("   Expected enum max %d -- got %d\n",
            max, pType->enumeration.max);
        exit(5);
    }
}

static void checkIndexType(CHUNKNUM typeChunk, char indexBaseType, int min, int max,
    const char *testName, int testNumber) {
    TTYPE type;

    retrieveChunk(typeChunk, (unsigned char *)&type);
    if (type.form == fcEnum) {
        checkEnumType(&type, max, testName, testNumber);
    } else if (type.form == fcSubrange) {
        checkSubrangeType(&type, indexBaseType, min, max, testName, testNumber);
    } else {
        errorHeader(testName, testNumber);
        printf("   Unexpected index type\n");
        exit(5);
    }
}

static void checkSubrangeType(TTYPE *pType, char indexBaseType, int min, int max,
    const char *testName, int testNumber) {
    
    if (pType->subrange.min != min) {
        errorHeader(testName, testNumber);
        printf("   Expected subrange min %d -- got %d\n",
            min, pType->subrange.min);
        exit(5);
    }
    if (pType->subrange.max != max) {
        errorHeader(testName, testNumber);
        printf("   Expected subrange max %d -- got %d\n",
            max, pType->subrange.max);
        exit(5);
    }
    checkTypeName(pType->subrange.baseType, indexBaseType, testName, testNumber);
}

static void checkTypeName(CHUNKNUM typeChunk, char expected,
    const char *testName, int testNumber) {

    if (expected == EN_TYPE) {
        char name[CHUNK_LEN];
        SYMTABNODE node;
        TTYPE type;

        retrieveChunk(typeChunk, (unsigned char *)&type);
        retrieveChunk(type.typeId, (unsigned char *)&node);
        retrieveChunk(node.nameChunkNum, (unsigned char *)name);
        if (strncmp(name, "en", CHUNK_LEN)) {
            printf("Expected en name\n");
            exit(5);
        }

        return;
    }

    if (getTypeFromDefine(expected) != typeChunk) {
        errorHeader(testName, testNumber);
        printf("Unexpected type name\n");
        exit(5);
    }
}

static void errorHeader(const char *test, int number) {
	printf("\n*** Assertion Error ***\n");
	printf("   TEST: %s\n", test);
	printf(" NUMBER: %d\n", number);
}

void getNextTestToken(void) {
    getNextTokenFromIcode(testIcode, &testToken, &testNode);
}

CHUNKNUM getTypeFromDefine(char type) {
    switch (type) {
        case BOOLEAN_TYPE: return booleanType;
        case INTEGER_TYPE: return integerType;
        case REAL_TYPE: return realType;
        case CHAR_TYPE: return charType;
    }

    return 0;
}

void runArrayTests(CHUNKNUM variableIds, struct ArrayTestCase *tests, const char *testName) {
    int i = 0;
    SYMBNODE node;
    
    while (tests[i].elemType) {
        loadSymbNode(variableIds, &node);

        if (node.type.form == fcArray) {
            checkArray(tests + i, &node.type, testName, i + 1);
            ++i;
        }

        variableIds = node.node.nextNode;
    }
}

void runIcodeTests(const char *testFile, int firstLine, const char *testRunName) {
    FILE *fh;
    char buf[40];
    int caseValues[MAX_MARKERS];
    MEMBUF_LOCN markers[MAX_MARKERS];
    int i = 0, j;

    DECLARE_TEST(testRunName);

    markers[0].chunkNum = 0;

    fh = fopen(testFile, "r");
    if (fh == NULL) {
        printf("Unable to open %s\n", testFile);
        exit(5);
    }

    getNextTestToken();

    while (!feof(fh)) {
        fgets(buf, sizeof(buf), fh);

        j = 0;
        while (buf[j]) {
            if (buf[j] == '#') {
                buf[j] = 0;
                break;
            }
            ++j;
        }

        while (isspace(buf[strlen(buf)-1])) {
            buf[strlen(buf)-1] = 0;
        }

        if (buf[0] == 0) {
            continue;  // empty line
        }

        switch (buf[0]) {
            case ICODETEST_CHAR:
                assertEqualByte(buf[2], testNode.defn.constant.value.character);
                break;

            case ICODETEST_FLOAT:
                if (strToFloat(buf + 2) != testNode.defn.constant.value.real) {
                    char buf2[16];
                    errorHeader(testName, i + 1);
                    floatToStr(testNode.defn.constant.value.real, buf2, 2);
                    printf("  Expected %s -- got %s\n", buf + 2, buf2);
                    exit(5);
                }
                break;
            
            case ICODETEST_INT:
                assertEqualInt(atoi(buf + 2), testNode.defn.constant.value.integer);
                break;
            
            case ICODETEST_LINE:
                assertEqualInt(firstLine, currentLineNumber);
                ++firstLine;
                break;
            
            case ICODETEST_NAME: {
                char actual[CHUNK_LEN];
                
                retrieveChunk(testNode.node.nameChunkNum, (unsigned char *)actual);
                if (strncmp(actual, buf + 2, CHUNK_LEN)) {
                    errorHeader(testName, i + 1);
                    printf("  Expected %s -- got %.22s\n", buf + 2, actual);
                    exit(5);
                }
                break;
            }
            
            case ICODETEST_TOKEN:
                assertEqualInt(atoi(buf + 2), testToken.code);
                break;

            case ICODETEST_MARKER: {
                int num = atoi(buf + 2);
                assertNonZero(num >= 1 && num <= MAX_MARKERS);
                getLocationMarker(testIcode, markers + num - 1);
                break;
            }

            case ICODETEST_POS: {
                int num = atoi(buf + 2);
                MEMBUF_LOCN thisLocn;
                assertNonZero(num >= 1 && num <= MAX_MARKERS);
                getMemBufLocn(testIcode, &thisLocn);
                assertEqualChunkNum(markers[num-1].chunkNum, thisLocn.chunkNum);
                assertEqualInt(markers[num-1].posChunk, thisLocn.posChunk);
                break;
            }

            case ICODETEST_BRANCHTBL: {
                int x = 0;
                MEMBUF_LOCN branchTable, thisLocn;

                getLocationMarker(testIcode, &branchTable);
                getMemBufLocn(testIcode, &thisLocn);
                setMemBufLocn(testIcode, &branchTable);
                while (1) {
                    assertNonZero(x < MAX_MARKERS);
                    getCaseItem(testIcode, caseValues + x, markers + x);
                    if (caseValues[x] == 0 && markers[x].chunkNum == 0) {
                        break;
                    }
                    ++x;
                }
                setMemBufLocn(testIcode, &thisLocn);
                break;
            }

            case ICODETEST_CASEBRANCH: {
                int x = 0, value = atoi(buf + 2);
                MEMBUF_LOCN thisLocn;
                getMemBufLocn(testIcode, &thisLocn);
                while (1) {
                    if (caseValues[x] == value) {
                        setMemBufLocn(testIcode, markers + x);
                        setMemBufPos(testIcode, getMemBufPos(testIcode)-1);
                        break;
                    }
                    assertNonZero(x < MAX_MARKERS);
                    ++x;
                }
                break;
            }

            case ICODETEST_GO: {
                int num = atoi(buf + 2);
                assertNonZero(num >= 1 && num <= MAX_MARKERS);
                setMemBufLocn(testIcode, markers + num - 1);
                break;
            }
        }

        if (buf[0] != ICODETEST_LINE && buf[0] != ICODETEST_POS) {
            getNextTestToken();
        }

        ++i;
    }

    fclose(fh);
}

void runVarTests(CHUNKNUM variableIds, struct VarTestCase *tests, int level, const char *testSuiteName) {
    int i = 0;
    char name[CHUNK_LEN];
    SYMBNODE node;

    DECLARE_TEST(testSuiteName);
    
    while (tests[i].name) {
        loadSymbNode(variableIds, &node);

        retrieveChunk(node.node.nameChunkNum, (unsigned char *)name);
        if (strncmp(tests[i].name, name, CHUNK_LEN)) {
            errorHeader(testName, i + 1);
            printf("  Expected %s -- got %.22s\n", tests[i].name, name);
            exit(5);
        }

        if (level != node.node.level) {
            errorHeader(testName, i + 1);
            printf("   Expected level %d -- got %d\n", level, node.node.level);
            exit(5);
        }

        if (i != node.defn.data.offset) {
            errorHeader(testName, i + 1);
            printf("   Expected offset %d -- got %d\n", i, node.defn.data.offset);
            exit(5);
        }


        if (isTypeScalar(&node.type)) {
            char name[CHUNK_LEN];
            SYMTABNODE typeNode;

            if (tests[i].type == EN_TYPE) {
                retrieveChunk(node.type.typeId, (unsigned char *)&typeNode);
                retrieveChunk(typeNode.nameChunkNum, (unsigned char *)name);
                if (strncmp(name, "en", CHUNK_LEN)) {
                    errorHeader(testName, i + 1);
                    printf("Expected en type\n");
                    exit(5);
                }
            }
            if (tests[i].baseType == EN_TYPE) {
                retrieveChunk(getBaseType(&node.type), (unsigned char *)&typeNode);
                retrieveChunk(typeNode.nameChunkNum, (unsigned char *)name);
                if (strncmp(name, "en", CHUNK_LEN)) {
                    errorHeader(testName, i + 1);
                    printf("Expected en type\n");
                    exit(5);
                }
            }
            if (tests[i].type != EN_TYPE || tests[i].baseType != EN_TYPE) {
                assertEqualChunkNum(getTypeFromDefine(tests[i].type), node.node.typeChunk);
                assertEqualChunkNum(getTypeFromDefine(tests[i].baseType), getBaseType(&node.type));
            }
        }

        variableIds = node.node.nextNode;
        ++i;
    }
}

void runIcodeTest(CHUNKNUM icode, const char *testFile, int firstLine, const char *testRunName) {
    testIcode = icode;
    setMemBufPos(testIcode, 0);
    runIcodeTests(testFile, firstLine, testRunName);
}