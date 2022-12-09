#include <stdio.h>

int testUintGe(unsigned num1, unsigned num2);
int testUintGt(unsigned num1, unsigned num2);
int testUintLe(unsigned num1, unsigned num2);
int testUintLt(unsigned num1, unsigned num2);

void testGetLine(void);

void testWriteBool(char value, char width);
void testWriteChar(char value, char width);

void testInt16(void);
void testUint16(void);

void main()
{
    // testInt16();
    testUint16();

#if 0
    unsigned int ch;

    printf("True:  ");
    testWriteBool(1, 5);
    printf("\n");
    printf("False: ");
    testWriteBool(0, 5);
    printf("\n");

    printf("Test Char: ");
    testWriteChar('K', 3);
    printf("\n");

    for (ch = 32; ch <= 127; ++ch)
        printf("%c", ch);

    printf("\n\n");

    for (ch = 161; ch <= 255; ++ch)
        printf("%c", ch);

    extern char getlineBuf;
    extern unsigned char getlineUsed;
    printf("Enter your name: ");
    testGetLine();
    printf("You entered: \"%.*s\"\n", getlineUsed, &getlineBuf);
#endif

    printf("\nDone running tests\n");

}
