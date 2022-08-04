#include "editor.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#if 0
static char *editorRowsToString(int *buflen);

static char *editorRowsToString(int *buflen) {
    int totlen = 0;
    int j;
    char *buf, *p;

    for (j = 0; j < E.cf->numrows; ++j) {
        totlen += E.cf->row[j].size + 1;
    }
    *buflen = totlen;

    buf = malloc(totlen);
    p = buf;
    for (j = 0; j < E.cf->numrows; ++j) {
        memcpy(p, E.cf->row[j].chars, E.cf->row[j].size);
        p += E.cf->row[j].size;
        *p = '\n';
        p++;
    }

    return buf;
}
#endif

void editorOpen(const char *filename) {
    FILE *fp;
    erow row;
    char *buf, *line, *eol;
    int buflen = 120, lastRow = -1;

    if (E.cf == NULL) {
        E.cf = malloc(sizeof(struct editorFile));
        initFile(E.cf);
    }
    free(E.cf->filename);
    E.cf->filename = strdup(filename);

#ifdef SYNTAX_HIGHLIGHT
    editorSelectSyntaxHighlight();
#endif

    fp = fopen(filename, "r");
    if (!fp) {
        editorSetStatusMessage("Cannot open file");
        return;
    }

    buf = malloc(buflen);

    while (!feof(fp)) {
        if (!fgets(buf, buflen, fp)) {
            fclose(fp);
            free(buf);
            editorSetStatusMessage("Cannot read file");
        }

        line = buf;
        while (1) {
            eol = strchr(line, '\r');
            if (eol == NULL) {
                if (line != NULL) {
                    if (lastRow >= 0) {
                        editorRowAt(lastRow, &row);
                        editorRowAppendString(&row, line, strlen(line));
                    } else {
                        editorInsertRow(E.cf->numrows, line, strlen(line));
                    }
                    lastRow = E.cf->numrows - 1;
                }
                break;
            } else {
                *eol = '\0';
                if (line != NULL) {
                    if (lastRow >= 0) {
                        editorRowAt(lastRow, &row);
                        editorRowAppendString(&row, line, strlen(line));
                    } else {
                        editorInsertRow(E.cf->numrows, line, strlen(line));
                    }
                    lastRow = -1;
                }
                line = eol + 1;
            }
        }
    }

    free(buf);
    fclose(fp);
    E.cf->dirty = 0;
}

# if 0
void editorSave() {
    if (E.cf->filename == NULL) {
        E.cf->filename = editorPrompt("Save as: %s", NULL);
        if (E.cf->filename == NULL) {
            editorSetStatusMessage("Save aborted");
            return;
        }
        editorSelectSyntaxHighlight();
    }

    int len;
    char *buf = editorRowsToString(&len);

    int fd = open(E.cf->filename, O_RDWR | O_CREAT, 0644);
    if (fd != -1) {
        if (ftruncate(fd, len) != -1) {
            if (write(fd, buf, len) == len) {
                close(fd);
                free(buf);
                E.cf->dirty = 0;
                editorSetStatusMessage("%d bytes written to disk", len);
                return;
            }
        }
        close(fd);
    }

    free(buf);
    editorSetStatusMessage("Can't save! I/O error %s", strerror(errno));
}
#endif

