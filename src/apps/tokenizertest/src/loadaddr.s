;
; loadaddr.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.export __LOADADDR__: absolute = 1

.segment "LOADADDR"

.addr *+2
