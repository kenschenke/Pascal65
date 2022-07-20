#include "editor.h"

#include <conio.h>
#include <stdio.h>
#include <stdlib.h>

static void die(const char *s);

static void die(const char *s) {
    clrscr();
    gotoxy(0, 0);

    printf("%s\n", s);
    exit(1);
}

int editorReadKey(void) {
    char c = cgetc();

    if (c == CH_ESC) {
        E.last_key_esc = 1;
        return c;
    }

    if (E.last_key_esc) {
        E.last_key_esc = 0;
        switch (c) {
            case '4':
                return COL40_KEY;

            case '8':
                return COL80_KEY;

            case 'a':
            case 'A':
                return SELECT_ALL_KEY;

            case 'j':
            case 'J':
                return HOME_KEY;
            
            case 'k':
            case 'K':
                return END_KEY;

            case 'p':
            case 'P':
                return DEL_SOL_KEY;

            case 'q':
            case 'Q':
                return DEL_EOL_KEY;
            
            case 'd':
            case 'D':
                return DEL_LINE_KEY;

            case 'i':
            case 'I':
                return INS_LINE_KEY;

            case 'v':
            case 'V':
                return SCROLL_UP_KEY;

            case 'w':
            case 'W':
                return SCROLL_DOWN_KEY;

            case 'b':
            case 'B':
                return SCROLL_TOP_KEY;

            case 'e':
            case 'E':
                return SCROLL_BOTTOM_KEY;

            case 'y':
            case 'Y':
                return MARK_KEY;

            case 'o':
            case 'O':
                return PASTE_KEY;
            
            case CH_CURS_UP:
                return PAGE_UP;
            
            case CH_CURS_DOWN:
                return PAGE_DOWN;
        }
    }

    return c;
}

