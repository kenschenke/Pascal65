/**
 * tests.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Definitions and declarations for unit tests.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef TESTS_H
#define TESTS_H

#include <chunks.h>

#define assertEqualByte(e, a) assertEqualByteX(e, a, testName, __LINE__)
#define assertEqualChunkNum(e, a) assertEqualChunkNumX(e, a, testName, __LINE__)
#define assertEqualFloat(e, a) assertEqualFloatX(e, a, testName, __LINE__)
#define assertNonZeroChunkNum(a) assertNonZeroChunkNumX(a, testName, __LINE__)
#define assertEqualInt(e, a) assertEqualIntX(e, a, testName, __LINE__)
#define assertEqualPointer(e, a) assertEqualPointerX(e, a, testName, __LINE__)
#define assertNonZero(v) assertNonZeroX(v, testName, __LINE__)
#define assertNotNull(p) assertNotNullX(p, testName, __LINE__)
#define assertNull(p) assertNullX(p, testName, __LINE__)
#define assertZero(v) assertZeroX(v, testName, __LINE__)

#define DECLARE_TEST(t) const char *testName = t;

void assertEqualByteX(unsigned char expected, unsigned char actual,
    const char *test, int line);
void assertEqualChunkNumX(CHUNKNUM expected, CHUNKNUM actual,
    const char *test, int line);
void assertEqualFloatX(const char *expected, FLOAT actual,
    const char *test, int line);
void assertNonZeroChunkNumX(CHUNKNUM actual,
    const char *test, int line);
void assertEqualIntX(int expected, int actual,
    const char *test, int line);
void assertEqualPointerX(unsigned char *expected, unsigned char *actual,
    const char *test, int line);
void assertNonZeroX(unsigned char value,
    const char *test, int line);
void assertNotNullX(unsigned char *p,
    const char *test, int line);
void assertNullX(unsigned char *p,
    const char *test, int line);
void assertZeroX(unsigned char value,
    const char *test, int line);

#endif // end of TESTS_H
