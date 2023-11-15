/**
 * screen.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Render screen.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include "editor.h"

#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <stdlib.h>
#include <conio.h>
#include <chunks.h>
#include <ctype.h>
#include <int16.h>
#include <membuf.h>
#include <cbm.h>

#define KILO_VERSION "0.0.1"

#define STATUSCOL_RO 18
#define STATUSCOL_MEM 23
#define STATUSCOL_X 31
#define STATUSCOL_X_LABEL 29
#define STATUSCOL_Y 37
#define STATUSCOL_Y_LABEL 35

static void setCursor(unsigned char value, unsigned char color);

static void drawRow65(char row, char col, char len, char *buf, char isReversed);

char * SCREEN = (char*)0x0800;

void clearScreen(void) {
    clrscr();
}

 void clearRow(char row, char startingCol) {
    int offset = row * 80 + startingCol;
    memset(SCREEN+offset, ' ', 80-startingCol);
}

static void drawRow65(char row, char col, char len, char *buf, char isReversed) {
    char i;
    int offset = row * 80 + col;
    for (i = 0; i < len; ++i) {
        SCREEN[offset++] = petsciitoscreencode(buf[i]) | (isReversed ? 128 : 0);
    }
}

void clearCursor(void) {
    setCursor(1, COLOUR_WHITE);
}

static void setCursor(unsigned char clear, unsigned char color) {
    unsigned int offset;

    offset = (E.cf.cy - E.cf.rowoff) * 80 + E.cf.cx - E.cf.coloff;
    if (clear) {
        SCREEN[offset] &= 0x7f;
    } else {
        SCREEN[offset] |= 0x80;
    }
    cellcolor(E.cf.cx - E.cf.coloff, E.cf.cy - E.cf.rowoff, color);
}

void drawRow(char row, char col, char len, const char *buf, char isReversed) {
    drawRow65(row, col, len, buf, isReversed);
}

void initScreen(void) {
    conioinit();
    clearScreen();
}

void renderCursor(char x, char y)
{
    setCursor(0, COLOUR_ORANGE);
}

void setRowColor(char, char)
{

}
