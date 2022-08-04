#ifndef TESTS_H
#define TESTS_H

#define assertEqualByte(e, a) assertEqualByteX(e, a, __FILE__, testName, __LINE__)
#define assertEqualPointer(e, a) assertEqualPointerX(e, a, __FILE__, testName, __LINE__)
#define assertNonZero(v) assertNonZeroX(v, __FILE__, testName, __LINE__)
#define assertNotNull(p) assertNotNullX(p, __FILE__, testName, __LINE__)
#define assertNull(p) assertNullX(p, __FILE__, testName, __LINE__)
#define assertZero(v) assertZeroX(v, __FILE__, testName, __LINE__)

#define DECLARE_TEST(t) const char *testName = t;

void assertEqualByteX(unsigned char expected, unsigned char actual,
    const char *file, const char *test, int line);
void assertEqualPointerX(unsigned char *expected, unsigned char *actual,
    const char *file, const char *test, int line);
void assertNonZeroX(unsigned char value,
    const char *file, const char *test, int line);
void assertNotNullX(unsigned char *p,
    const char *file, const char *test, int line);
void assertNullX(unsigned char *p,
    const char *file, const char *test, int line);
void assertZeroX(unsigned char value,
    const char *file, const char *test, int line);

#endif // end of TESTS_H
