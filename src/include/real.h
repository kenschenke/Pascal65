#ifndef REAL_H
#define REAL_H

typedef unsigned long FLOAT;

// Sum of num1 and num2 returned
FLOAT floatAdd(FLOAT num1, FLOAT num2);

// Result of num2 subtracted from num1
FLOAT floatSub(FLOAT num1, FLOAT num2);

// Product of num1 and num2 returned
FLOAT floatMult(FLOAT num1, FLOAT num2);

// Result of num1 divided by num2
FLOAT floatDiv(FLOAT num1, FLOAT num2);

// Returns negative of num
FLOAT floatNeg(FLOAT num);

// Returns non-zero if num1 == num2
char floatEq(FLOAT num1, FLOAT num2);

// Returns non-zero if num1 > num2
char floatGt(FLOAT num1, FLOAT num2);

// Returns non-zero if num1 >= num2
char floatGte(FLOAT num1, FLOAT num2);

// Returns non-zero if num1 < num2
char floatLt(FLOAT num1, FLOAT num2);

// Returns non-zero if num1 <= num2
char floatLte(FLOAT num1, FLOAT num2);

// num1 is printed to screen.
// If precision is < 0 then scientific notation is used.
// The number is right-aligned in the supplied width.
void floatPrint(FLOAT num, char precision, char width);

// The NULL-terminated string is parsed and returned as
// a float.  Scientific notation and standard formats are supported.
FLOAT strToFloat(const char *str);

// The float is converted to a string in the supplied buffer.  The
// string is NULL-terminated.  If the precision is < 0 then
// scientific notation is used.
void floatToStr(FLOAT num, char *buffer, char precision);

int floatToInt16(FLOAT num);
FLOAT int16ToFloat(int num);

FLOAT readFloatFromInput(void);

#endif // end of REAL_H
