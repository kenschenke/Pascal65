#include <cbm.h>
#include <conio.h>
#include <stdio.h>
#include <ctype.h>

// Minimum buffer length of 2
// 1 returned if user hit STOP key, 0 otherwise
char strInput(char *buffer, int buflen)
{
    char i = 0;
    char ch;

    cursor(1);
    while (1)
    {
        ch = cgetc();

        if (ch == CH_STOP) {
            return 1;
        }

        if (ch == CH_DEL && i > 0) {
            --i;
            putc(CH_DEL, stdout);
        }

        if (ch == CH_ENTER) {
            buffer[i] = 0;
            putc(ch, stdout);
            cursor(0);
            return 0;
        }
        
        if (i+1 < buflen && isprint(ch)) {
            buffer[i++] = ch;
            putc(ch, stdout);
        }
    }
}
