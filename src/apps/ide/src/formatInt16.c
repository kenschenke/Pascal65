/**
 * formatInt16.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Convert int to PETSCII.
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdlib.h>
#include <int16.h>

const char *formatInt16(int num)
{
    static char buffer[7];

    itoa(num, buffer, 10);

    return buffer;
}
