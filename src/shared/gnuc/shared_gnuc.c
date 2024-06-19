/**
 * shared_gnuc.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdio.h>
#include <stdlib.h>
#include <libcommon.h>
#include <int16.h>
#include <unistd.h>
#include <ctype.h>

const char *formatInt16(short num)
{
    static char buf[20];

    sprintf(buf, "%d", num);

    return buf;
}

void setIntBuf(char *)
{
}

void removeFile(char *filename)
{
    unlink(filename);
}

long parseInt32(char *buffer)
{
    return (long) atoll(buffer);
}

void printz(const char *str)
{
    printf("%s", str);
}

void printlnz(const char *str)
{
    printf("%s\n", str);
}

void strlwr(char *str)
{
    for (char *p=str; *p; p++) {
        *p = tolower(*p);
    }
}
