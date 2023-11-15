/**
 * terminal.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Keyboard input.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include "editor.h"

#include <conio.h>
#include <stdio.h>
#include <stdlib.h>

#ifdef __MEGA65__
#include <cbm.h>

char fixAlphaCase(char);
#endif

int editorReadKey(void) {
    int c = cgetc();
#ifdef __MEGA65__
    c = fixAlphaCase(c);
#endif

    if (c == CH_ESC) {
        E.last_key_esc = 1;
        return c;
    }

    if (E.last_key_esc) {
        E.last_key_esc = 0;
        switch (c) {
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

            case CH_CURS_UP:
                return PAGE_UP;
            
            case CH_CURS_DOWN:
                return PAGE_DOWN;
        }
    }

    return c;
}

