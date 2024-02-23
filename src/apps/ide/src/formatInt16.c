#include <stdlib.h>
#include <int16.h>

const char *formatInt16(int num)
{
    static char buffer[7];

    itoa(num, buffer, 10);

    return buffer;
}
