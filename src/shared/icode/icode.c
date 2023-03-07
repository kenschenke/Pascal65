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

const TTokenCode mcLineMarker = ((TTokenCode) 127);
const TTokenCode mcLocationMarker = ((TTokenCode) 126);
