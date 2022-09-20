;;;
 ; scanner.inc
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; Source file scanner and tokenizer
 ; 
 ; Copyright (c) 2022
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "buffer.inc"

TOKEN_STRING_LEN = MAX_LINE_LEN + 1

.struct TOKEN
    code  .byte
    type  .byte
    value .word
    .res 81 ; TOKEN_STRING_LEN
.endstruct
