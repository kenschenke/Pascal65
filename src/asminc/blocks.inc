;;;
 ; blocks.inc
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; Blocks Allocation
 ; 
 ; Copyright (c) 2024
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

BLOCK_LEN = 256
BANKS = 2
BLOCKS_PER_BANK = 256
TOTAL_BLOCKS = BANKS * BLOCKS_PER_BANK
MAX_BLOCKS = 4096
