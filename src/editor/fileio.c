#include "editor.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

char *editorRowsToString(int *buflen) {
    int totlen = 0;
    int j;
    char *buf, *p;

    for (j = 0; j < E.numrows; ++j) {
        totlen += E.row[j].size + 1;
    }
    *buflen = totlen;

    buf = malloc(totlen);
    p = buf;
    for (j = 0; j < E.numrows; ++j) {
        memcpy(p, E.row[j].chars, E.row[j].size);
        p += E.row[j].size;
        *p = '\n';
        p++;
    }

    return buf;
}

void editorOpen(const char *filename) {
    FILE *fp;
    char *buf, *line, *eol;
    erow *row = NULL;
    int buflen = 120;

    free(E.filename);
    E.filename = strdup(filename);

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
                    if (row) {
                        editorRowAppendString(row, line, strlen(line));
                    } else {
                        editorInsertRow(E.numrows, line, strlen(line));
                    }
                    row = &E.row[E.numrows - 1];
                }
                break;
            } else {
                *eol = '\0';
                if (line != NULL) {
                    if (row) {
                        editorRowAppendString(row, line, strlen(line));
                    } else {
                        editorInsertRow(E.numrows, line, strlen(line));
                    }
                    row = NULL;
                }
                line = eol + 1;
            }
        }
    }

    free(buf);
    fclose(fp);
    E.dirty = 0;
}

# if 0
void editorSave() {
    if (E.filename == NULL) {
        E.filename = editorPrompt("Save as: %s", NULL);
        if (E.filename == NULL) {
            editorSetStatusMessage("Save aborted");
            return;
        }
        editorSelectSyntaxHighlight();
    }

    int len;
    char *buf = editorRowsToString(&len);

    int fd = open(E.filename, O_RDWR | O_CREAT, 0644);
    if (fd != -1) {
        if (ftruncate(fd, len) != -1) {
            if (write(fd, buf, len) == len) {
                close(fd);
                free(buf);
                E.dirty = 0;
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

