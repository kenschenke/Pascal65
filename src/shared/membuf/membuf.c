/**
 * membuf.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <membuf.h>

MEMBUF cachedMemBufHdr;
CHUNKNUM cachedMemBufHdrChunkNum;

MEMBUF_CHUNK cachedMemBufData;
CHUNKNUM cachedMemBufDataChunkNum;

