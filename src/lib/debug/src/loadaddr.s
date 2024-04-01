;
; loadaddr.s
; Ken Schenke (kenschenke@gmail.com)
; 
; LOADADDR segment for debug library
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.export __LOADADDR__: absolute = 1

.segment "LOADADDR"

.addr *+2
