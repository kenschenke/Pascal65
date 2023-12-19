#ifndef INT16_H
#define INT16_H

#define INTBUFLEN 14

const char *formatInt16(int num);
const char *formatUint16(unsigned int num);
int parseInt16(char *buffer);
void printInt16(int num);
void setIntBuf(char *buffer);   // buffer must be at least 14 bytes

#endif // end of INT16_H
