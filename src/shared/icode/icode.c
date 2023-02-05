/**
 * icode.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Functions for intermediate code.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <string.h>
#include <icode.h>
#include <error.h>
#include <scanner.h>

// 24882 bytes code size
// 13325 heap
// $97B code

const int codeSegmentSize = 1024;

const char *symbolStrings[] = {
    NULL,
    NULL, NULL, NULL, NULL, NULL,

    "^", "*", "(", ")", "-", "+",
    "=", "[", "]", ":", ";", "<",
    ">", ",", ".", "/", ":=", "<=", ">=",
    "<>", "..",

    "and", "array", "begin", "case", "const", "div",
    "do", "downto", "else", "end", "file", "for", "function",
    "goto", "if", "in", "label", "mod", "nil", "not", "of", "or",
    "packed", "procedure", "program", "record", "repeat", "set",
    "then", "to", "type", "until", "var", "while", "with",
};

const TTokenCode mcLineMarker = ((TTokenCode) 127);
const TTokenCode mcLocationMarker = ((TTokenCode) 126);
