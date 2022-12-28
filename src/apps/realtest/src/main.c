#include <stdio.h>
#include <conio.h>
#include <stdlib.h>

unsigned char firstNum[4];

#if 0
static void dump(void);
static void floatAddRunner(void);
static void fixedToFloatRunner(void);
static void floatToFixedRunner(void);
#endif
static void addTwoNumbers(void);
static void multiplyTwoNumbers(void);
static void divideTwoNumbers(void);
static void subtractTwoNumbers(void);
static void showBinary(unsigned long num);
static void handleOpt(char ch);
static void prompt(void);
static void complement(void);
static void normalize(void);
static void rotateLeft(void);
static void rotateRight(void);
static void showHelp(void);
static void testInputOutput(void);

void addNumbers(unsigned char *buffer);
void subtractNumbers(unsigned char *buffer);
void multNumbers(unsigned char *buffer);
void divNumbers(unsigned char *buffer);
void complm(void);
void fpinp(void);
void fpout(void);
void fpnorm(unsigned char lsb, unsigned char nsb, unsigned char msb, unsigned char exp);
void getFirstNumber(unsigned char *buffer);
void rotAtl(void);
void rotAtr(void);

#if 0
void floatAdd(void);
void fixedToFloat(int num);
int floatToFixed(unsigned char x1, unsigned char m1, unsigned char m2, unsigned char m3);

static void dump(void)
{
    extern unsigned char M11, M12, M13, M21, M22, M23, X1, X2, E1, E2, E3, E4;

    printf("X1 %02x   M1 %02x %02x %02x\n", X1, M11, M12, M13);
    printf("X2 %02x   M2 %02x %02x %02x\n", X2, M21, M22, M23);
    printf("E %02x %02x %02x %02x\n", E1, E2, E3, E4);
}
#endif

static void addTwoNumbers(void)
{
    printf("Enter first number: ");
    getFirstNumber(firstNum);
    printf("\nEnter second number: ");
    fpinp();
    addNumbers(firstNum);
    printf("\nSum is: ");
    fpout();
    printf("\n\n");
}

static void subtractTwoNumbers(void)
{
    printf("Enter first number: ");
    getFirstNumber(firstNum);
    printf("\nEnter second number: ");
    fpinp();
    subtractNumbers(firstNum);
    printf("\nDifference is: ");
    fpout();
    printf("\n\n");
}

static void multiplyTwoNumbers(void)
{
    printf("Enter first number: ");
    getFirstNumber(firstNum);
    printf("\nEnter second number: ");
    fpinp();
    multNumbers(firstNum);
    printf("\nProduct is: ");
    fpout();
    printf("\n\n");
}

static void divideTwoNumbers(void)
{
    printf("Enter first number: ");
    getFirstNumber(firstNum);
    printf("\nEnter second number: ");
    fpinp();
    divNumbers(firstNum);
    printf("\nResult is: ");
    fpout();
    printf("\n\n");
}

static void handleOpt(char ch) {
    switch (ch) {
        case 'a':
        case 'A':
            addTwoNumbers();
            break;

        case 'c':
        case 'C':
            complement();
            break;

        case 'd':
        case 'D':
            divideTwoNumbers();
            break;
            
        case 'f':
        case 'F':
            // fixedToFloatRunner();
            break;

        case 'i':
        case 'I':
            testInputOutput();
            break;

        case 'l':
        case 'L':
            rotateLeft();
            break;

        case 'm':
        case 'M':
            multiplyTwoNumbers();
            break;
            
        case 'n':
        case 'N':
            normalize();
            break;

        case 'r':
        case 'R':
            rotateRight();
            break;

        case 'p':
        case 'P':
            // floatToFixedRunner();
            break;

        case 's':
        case 'S':
            subtractTwoNumbers();
            break;

        case 'x':
        case 'X':
            exit(0);
            break;

        default:
            printf("\nUnrecognized option\n");
            break;
    }
}

static void prompt(void) {
    showHelp();

    printf("\nSelect an option:\n");
    handleOpt(cgetc());
}

static void complement(void) {
    extern unsigned long num;

    num = 1234567;
    // showBinary(num);
    complm();
    printf("num %ld\n", num);
}

static void normalize(void) {
    extern unsigned char lsb, nsb, msb, exp;

    fpnorm(0x1a, 0xc6, 0x0d, 0x00);
    printf("%02x %02x %02x %02x\n", lsb, nsb, msb, exp);
    printf("d0 30 6e fd (should be)\n");
    // fpnorm(0x00, 0xc0, 0xff, 0x0a);
    // printf("%02x %02x %02x %02x\n", lsb, nsb, msb, exp);
}

static void rotateLeft(void) {
    extern unsigned long num;

    num = 0x0df64126;
    showBinary(num);
    rotAtl();
    showBinary(num);
}

static void rotateRight(void) {
    extern unsigned long num;

    num = 0x0df64126;
    showBinary(num);
    rotAtr();
    showBinary(num);
}

static void showBinary(unsigned long num) {
    int i, j;
    unsigned long mask = 0x80000000;

    for (i = 0; i < 4; i++) {
        for (j = 0; j < 8; j++) {
            printf("%c", (num & mask) == mask ? '1' : '0');
            mask >>= 1;
        }
        printf(" ");
    }
    printf("\n");
}

static void showHelp(void) {
    printf("\nFloating Point Demonstration Program\n\n");
    printf("A - Add two numbers\n");
    printf("F - Fixed to floating point\n");
    printf("C - Two's complement\n");
    printf("D - Divide two numbers\n");
    printf("I - Test input / output\n");
    printf("L - Rotate left\n");
    printf("M - Multiply two numbers\n");
    printf("N - Normalize\n");
    printf("R - Rotate right\n");
    printf("P - Floating to fixed point\n");
    printf("S - Subtract two numbers\n");
    printf("? - This help screen\n");

    printf("X - Exit\n");
}

static void testInputOutput(void)
{
    printf("Enter a number: ");
    fpinp();

    printf("\n\nYou entered: ");
    fpout();
    printf("\n");
}

void main()
{
    clrscr();

    while (1) {
        prompt();
    }
}
