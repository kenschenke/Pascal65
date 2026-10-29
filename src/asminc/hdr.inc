;
; hdr.inc
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Pre-compiled header (.hdr) file format definitions.
;
; File layout:
;    'P', 'H', HDR_VERSION          magic and format version
;    record count (2 bytes, lo/hi)
;    <count> records, numbered 1..count. Record 1 is the unit's module decl.
;
; A record is one heap object of the library unit's AST:
;    HDR_REC_NAME:   kind byte, length byte (strlen+1), then length bytes
;                    (including the terminating zero)
;    all others:     kind byte, then the raw structure bytes (the size of
;                    the structure, see hdrRecSize). Every 4-byte pointer
;                    field holds the 1-based index of the record it points
;                    to (lo, hi, 0, 0), or zero for a null pointer.
;
; Pointer fields the parser never fills in (symbol, symbol table, and
; evaluated-type pointers) are written as zero.

HDR_VERSION = 1

HDR_REC_DECL  = 1
HDR_REC_TYPE  = 2
HDR_REC_EXPR  = 3
HDR_REC_PARAM = 4
HDR_REC_NAME  = 5
HDR_REC_STMT  = 6
HDR_REC_COUNT = 6

; Field descriptor target codes (hdrFieldNext). Codes 1..HDR_REC_COUNT
; are the HDR_REC_* kind of the record the field points to.
HDR_TK_RAW  = 0         ; field is a plain value. Copy as-is.
HDR_TK_ZERO = $80       ; field is not stored. Written as zero.

; Maximum number of records in one header (index table is 5 bytes each)
HDR_MAX_RECORDS = 3000
HDR_ENTRY_SIZE = 5
