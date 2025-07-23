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
#include <execinfo.h>
#include <string.h>

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

void printStackTrace(void)
{
    void *trace[16];
    char **messages = (char **)NULL;
    int i, trace_size = 0;
    char addr[16];

    trace_size = backtrace(trace, 16);
    messages = backtrace_symbols(trace, trace_size);
    printf("[bt] Execute path:\n");
    for (i = 1; i < trace_size; ++i) {
        printf("[bt] #%d %s\n", i, messages[i]);

        size_t q, p = 0;
        while(messages[i][p] != '(' && messages[i][p] != ' ' &&
            messages[i][p] != 0) {
                p++;
            }
        if (messages[i][p+1] == '+') {
            q = p + 2;
            while (messages[i][q] != ')' && messages[i][q] != 0)
                q++;
            strncpy(addr, &messages[i][p+2], q-p-2);
            addr[q-p-2] = 0;
        } else {
            sprintf(addr, "%p", trace[i]);
        }
        
        char syscom[256];
        sprintf(syscom, "addr2line %s -e %.*s", addr, p, messages[i]);
        system(syscom);
    }
}