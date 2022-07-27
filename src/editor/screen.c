#include "editor.h"

#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <stdlib.h>
#include <conio.h>

#ifdef __MEGA65__
#include <cbm.h>
#endif

#define KILO_VERSION "0.0.1"

#ifdef __C128__
void __fastcall__ clearScreen80(void);
void __fastcall__ initScreen80(void);
void __fastcall__ setScreenBg80(char bg);
void __fastcall__ drawRow80(char row, char len,
    char *buf, unsigned char *rev);

void __fastcall__ clearScreen40(void);
void __fastcall__ initScreen40(void);
void __fastcall__ setScreenBg40(char bg);
void __fastcall__ drawRow40(char row, char len,
    char *buf, unsigned char *rev);
#endif

static void editorDrawMessageBar(void);
static void editorDrawRows(void);
static void editorDrawStatusBar(void);
static void editorScroll(void);
static void freeWelcomePage(char **rows, int numRows);
static void prepWelcomePage(char ***rows, int *numRows);
static void setCursor(unsigned char value, unsigned char color);

#ifdef __MEGA65__
static void drawRow65(char row, char len, char *buf, unsigned char *rev);

char * SCREEN = (char*)0x0800;
char * COLORS = (char*)0xd800;
#endif

void clearScreen(void) {
#ifdef __MEGA65__
    clrscr();
#else
    if (E.screencols == 40)
        clearScreen40();
    else
        clearScreen80();
#endif
}

#ifdef __MEGA65__
static void drawRow65(char row, char len, char *buf, unsigned char *rev) {
    char i;
    int offset = row * E.screencols;
    for (i = 0; i < len; ++i) {
        SCREEN[offset++] = petsciitoscreencode(buf[i]) | (rev && rev[i] ? 128 : 0);
    }
    memset(SCREEN+offset, ' ', E.screencols-len);
}

void clearCursor(void) {
    unsigned char clear = E.cf->row[E.cf->cy].rev == NULL ||
        E.cf->row[E.cf->cy].rev[E.cf->cx] == 0;
    setCursor(clear, COLOUR_WHITE);
}

void renderCursor(void) {
    setCursor(0, COLOUR_GREEN);
}

static void setCursor(unsigned char clear, unsigned char color) {
    unsigned int offset;

    offset = (E.cf->cy - E.cf->rowoff) * E.screencols + E.cf->cx - E.cf->coloff;
    if (clear) {
        SCREEN[offset] &= 0x7f;
    } else {
        SCREEN[offset] |= 0x80;
    }
    COLORS[offset] = color;
}
#else
void clearCursor(void) {}
#endif

void drawRow(char row, char len, char *buf, unsigned char *rev) {
#ifdef __MEGA65__
    drawRow65(row, len, buf, rev);
#else
    if (E.screencols == 40)
        drawRow40(row, len, buf, rev);
    else
        drawRow80(row, len, buf, rev);
#endif
}

static void freeWelcomePage(char **rows, int numRows) {
    int i;

    for (i = 0; i < numRows; ++i) {
        free(rows[i]);
    }
    free(rows);
}

static void prepWelcomePage(char ***rows, int *numRows) {
    char **r;
    char *p = E.welcomePage, *n;
    int len, num;

    r = NULL;
    num = 0;

    while (1) {
        n = strchr(p, '\r');
        len = n == NULL ? strlen(p) : n - p;
        if (len > E.screencols) len = E.screencols;
        r = realloc(r, sizeof(char *) * (num+1));
        r[num] = malloc(len + 1);
        memcpy(r[num], p, len);
        r[num][len] = '\0';
        ++num;
        if (n == NULL) {
            break;
        }
        p = n + 1;
    }

    *rows = r;
    *numRows = num;
}

void initScreen(void) {
#ifdef __MEGA65__
    conioinit();
    clearScreen();
#else
    if (E.screencols == 40)
        initScreen40();
    else
        initScreen80();
#endif
}

#ifdef __C128__
void setScreenBg(char bg) {
    if (E.screencols == 40)
        setScreenBg40(bg);
    else
        setScreenBg80(bg);
}
#endif

static void editorScroll(void) {
    int willScroll = 0;

    if (E.cf->cy < E.cf->rowoff) {
        E.cf->rowoff = E.cf->cy;
        willScroll = 1;
    }
    if (E.cf->cy >= E.cf->rowoff + E.screenrows) {
        E.cf->rowoff = E.cf->cy - E.screenrows + 1;
        willScroll = 1;
    }
    if (E.cf->cx < E.cf->coloff) {
        E.cf->coloff = E.cf->cx;
        willScroll = 1;
    }
    if (E.cf->cx >= E.cf->coloff + E.screencols) {
        E.cf->coloff = E.cf->cx - E.screencols + 1;
        willScroll = 1;
    }

    if (willScroll) {
        editorSetAllRowsDirty();
    }
}

static void editorDrawRows(void) {
    int y, padding;

    if (E.cf == NULL) {
        char **rows, *buffer;
        int i, numRows, x, y;

        prepWelcomePage(&rows, &numRows);
        y = (E.screenrows - numRows) / 2;
        for (i = 0; i < y; ++i) {
            drawRow(i, 0, "", NULL);
        }
        buffer = malloc(E.screencols + 1);
        for (i = 0; i < numRows; ++i, ++y) {
            x = (E.screencols - strlen(rows[i])) / 2;
            if (x < 0) x = 0;
            if (x > 0) memset(buffer, ' ', x);
            strcpy(buffer + x, rows[i]);
            drawRow(y, strlen(buffer), buffer, NULL);
        }

        free(buffer);
        freeWelcomePage(rows, numRows);

        return;
    }

    for (y = 0; y < E.screenrows; y++) {
        int filerow = y + E.cf->rowoff;
        if (E.cf->dirtyScreenRows[y]) {
            int len = E.cf->row[filerow].size - E.cf->coloff;
            if (len < 0) len = 0;
            if (len > E.screencols) len = E.screencols;
            drawRow(y, len, &E.cf->row[filerow].chars[E.cf->coloff],
                E.cf->row[filerow].rev ? &E.cf->row[filerow].rev[E.cf->coloff] : NULL);
            E.cf->dirtyScreenRows[y] = 0;
        }
    }
}

static void editorDrawStatusBar(void) {
    char status[80], rstatus[80];
    int len, rlen;

    memset(E.statusbar, ' ', E.screencols);

    if (E.cf == NULL) {
        strcpy(status, "Welcome");
        len = strlen(status);
        rlen = 0;
    } else {
        len = snprintf(status, sizeof(status), "%.20s - %d lines%s%s",
            E.cf->filename ? E.cf->filename : "[No Name]", E.cf->numrows,
            E.cf->dirty ? " (modified)" : "",
            E.cf->readOnly ? " (read only)" : "");
        rlen = snprintf(rstatus, sizeof(rstatus), "%d/%d", E.cf->cy + 1, E.cf->numrows);
        if (len > E.screencols) len = E.screencols;
    }
    memcpy(E.statusbar, status, len);
    memcpy(E.statusbar + E.screencols - rlen, rstatus, rlen);

    drawRow(E.screenrows, E.screencols, E.statusbar, E.statusbarrev);
}

static void editorDrawMessageBar(void) {
    int msglen = strlen(E.statusmsg);

    if (!E.statusmsg_dirty) return;

    if (msglen > E.screencols) msglen = E.screencols;
    if (msglen) {
        drawRow(E.screenrows+1, msglen, E.statusmsg, NULL);
    } else {
        memset(E.statusmsg, ' ', E.screencols);
        drawRow(E.screenrows+1, E.screencols, E.statusmsg, NULL);
    }
    
    E.statusmsg_dirty = 0;
}

void editorRefreshScreen(void) {
    if (E.cf)
        editorScroll();

    editorDrawRows();
    editorDrawStatusBar();
    editorDrawMessageBar();

    renderCursor();
}

void editorSetStatusMessage(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(E.statusmsg, sizeof(E.statusmsg), fmt, ap);
    va_end(ap);
    E.statusmsg_dirty = 1;
}

