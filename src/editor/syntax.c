#include "editor.h"

#ifdef SYNTAX_HIGHLIGHT
/*** syntax highlighting ***/

int is_separator(int c) {
    return isspace(c) || c == '\0' || strchr(",.()+-/*=~%<>[];", c) != NULL;
}

void editorUpdateSyntax(erow *row) {
    char **keywords;
    char *scs, *mcs, *mce;
    int scs_len, mcs_len, mce_len;
    int prev_sep, in_string, in_comment, i, changed;

    row->hl = realloc(row->hl, row->size);
    memset(row->hl, HL_NORMAL, row->size);

    if (E.syntax == NULL) return;

    keywords = E.syntax->keywords;

    scs = E.syntax->singleline_comment_start;
    mcs = E.syntax->multiline_comment_start;
    mce = E.syntax->multiline_comment_end;

    scs_len = scs ? strlen(scs) : 0;
    mcs_len = mcs ? strlen(mcs) : 0;
    mce_len = mce ? strlen(mce) : 0;

    prev_sep = 1;
    in_string = 0;
    in_comment = (row->idx > 0 && E.cf->row[row->idx - 1].hl_open_comment);

    i = 0;
    while (i < row->size) {
        char c = row->chars[i];
        unsigned char prev_hl = (i > 0) ? row->hl[i - 1] : HL_NORMAL;

        if (scs_len && !in_string && !in_comment) {
            if (!strncmp(&row->chars[i], scs, scs_len)) {
                memset(&row->hl[i], HL_COMMENT, row->size - i);
                break;
            }
        }

        if (mcs_len && mce_len && !in_string) {
            if (in_comment) {
                row->hl[i] = HL_MLCOMMENT;
                if (!strncmp(&row->chars[i], mce, mce_len)) {
                    memset(&row->hl[i], HL_MLCOMMENT, mce_len);
                    i += mce_len;
                    in_comment = 0;
                    prev_sep = 1;
                    continue;
                } else {
                    ++i;
                    continue;
                }
            } else if (!strncmp(&row->chars[i], mcs, mcs_len)) {
                memset(&row->hl[i], HL_MLCOMMENT, mcs_len);
                i += mcs_len;
                in_comment = 1;
                continue;
            }
        }

        if (E.syntax->flags & HL_HIGHLIGHT_STRINGS) {
            if (in_string) {
                row->hl[i] = HL_STRING;
                if (c == '\\' && i + 1 < row->size) {
                    row->hl[i + 1] = HL_STRING;
                    i += 2;
                    continue;
                }
                if (c == in_string) in_string = 0;
                ++i;
                prev_sep = 1;
                continue;
            } else {
                if (c == '"' || c == '\'') {
                    in_string = c;
                    row->hl[i] = HL_STRING;
                    ++i;
                    continue;
                }
            }
        }

        if (E.syntax->flags & HL_HIGHLIGHT_NUMBERS) {
            if ((isdigit(c) && (prev_sep || prev_hl == HL_NUMBER)) ||
                (c == '.' && prev_hl == HL_NUMBER)) {
                row->hl[i] = HL_NUMBER;
                ++i;
                prev_sep = 0;
                continue;
            }
        }

        if (prev_sep) {
            int j;
            for (j = 0; keywords[j]; ++j) {
                int klen = strlen(keywords[j]);
                int kw2 = keywords[j][klen - 1] == '|';
                if (kw2) klen--;

                if (!strncmp(&row->chars[i], keywords[j], klen) &&
                    is_separator(row->chars[i + klen])) {
                        memset(&row->hl[i], kw2 ? HL_KEYWORD2 : HL_KEYWORD1, klen);
                        i += klen;
                        break;
                    }
            }
            if (keywords[j] != NULL) {
                prev_sep = 0;
                continue;
            }
        }

        prev_sep = is_separator(c);
        ++i;
    }

    changed = (row->hl_open_comment != in_comment);
    row->hl_open_comment = in_comment;
    if (changed && row->idx + 1 < E.cf->numrows)
        editorUpdateSyntax(&E.cf->row[row->idx + 1]);
}

int editorSyntaxToColor(int hl) {
    switch (hl) {
        case HL_COMMENT:
        case HL_MLCOMMENT: return 36;
        case HL_KEYWORD1: return 33;
        case HL_KEYWORD2: return 32;
        case HL_STRING: return 35;
        case HL_NUMBER: return 31;
        case HL_MATCH: return 34;
        default: return 37;
    }
}

void editorSelectSyntaxHighlight() {
    char *ext;
    unsigned int j;
    int filerow;

    E.syntax = NULL;
    if (E.cf->filename == NULL) return;

    ext = strrchr(E.cf->filename, '.');

    for (j = 0; j < HLDB_ENTRIES; ++j) {
        struct editorSyntax *s = &HLDB[j];
        unsigned int i = 0;
        while (s->filematch[i]) {
            int is_ext = (s->filematch[i][0] == '.');
            if ((is_ext && ext && !strcmp(ext, s->filematch[i])) ||
                (!is_ext && strstr(E.cf->filename, s->filematch[i]))) {
                    E.syntax = s;

                    for (filerow = 0; filerow < E.cf->numrows; ++filerow) {
                        editorUpdateSyntax(&E.cf->row[filerow]);
                    }

                    return;
                }
            ++i;
        }
    }
}
#endif // end of SYNTAX_HIGHLIGHT
