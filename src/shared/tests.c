/**
 * tests.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Unit test assertions.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdio.h>
#include <stdlib.h>
#include <real.h>
#include <tests.h>

#ifdef __TEST__
static void errorHeader(const char *file, const char *test, int line);

static void errorHeader(const char *file, const char *test, int line) {
	printf("\n*** Assertion Error ***\n");
	printf("   TEST: %s\n", test);
	printf("   FILE: %s\n", file);
	printf("   LINE: %d\n", line);
}

void assertEqualByteX(unsigned char expected, unsigned char actual,
	const char *file, const char *test, int line)
{
	if (expected != actual) {
		errorHeader(file, test, line);
		printf("Expected %d -- got %d\n", expected, actual);
		exit(5);
	}
}

void assertEqualChunkNumX(CHUNKNUM expected, CHUNKNUM actual,
	const char *file, const char *test, int line)
{
	if (expected != actual) {
		errorHeader(file, test, line);
		printf("Expected %d -- got %d\n", expected, actual);
		exit(5);
	}
}

void assertEqualFloatX(const char *expected, FLOAT actual,
    const char *file, const char *test, int line) {
	if (strToFloat(expected) != actual) {
		char buf[15];

		floatToStr(actual, buf, 2);
		errorHeader(file, test, line);
		printf("Expected %s -- got %s\n", expected, buf);
		exit(5);
	}
}

void assertNonZeroChunkNumX(CHUNKNUM actual,
	const char *file, const char *test, int line)
{
	if (actual == 0) {
		errorHeader(file, test, line);
		printf("Expected %04X to be non-zero\n", actual);
		exit(5);
	}
}

void assertEqualIntX(int expected, int actual,
	const char *file, const char *test, int line)
{
	if (expected != actual) {
		errorHeader(file, test, line);
		printf("Expected %d -- got %d\n", expected, actual);
		exit(5);
	}
}

void assertEqualPointerX(unsigned char *expected, unsigned char *actual,
	const char *file, const char *test, int line)
{
	if (expected != actual) {
		errorHeader(file, test, line);
		printf("Expected pointers to equal\n");
		exit(5);
	}
}

void assertNonZeroX(unsigned char value,
	const char *file, const char *test, int line)
{
	if (value == 0) {
		errorHeader(file, test, line);
		printf("Expected value to be non-zero\n");
		exit(5);
	}
}

void assertNotNullX(unsigned char *p,
	const char *file, const char *test, int line)
{
	if (p == NULL) {
		errorHeader(file, test, line);
		printf("Expected pointer to not be NULL\n");
		exit(5);
	}
}

void assertNullX(unsigned char *p,
	const char *file, const char *test, int line)
{
	if (p) {
		errorHeader(file, test, line);
		printf("Expected pointer to be NULL\n");
		exit(5);
	}
}

void assertZeroX(unsigned char value,
	const char *file, const char *test, int line)
{
	if (value) {
		errorHeader(file, test, line);
		printf("Expected value to be zero\n");
		exit(5);
	}
}
#endif  // end of __TEST__
