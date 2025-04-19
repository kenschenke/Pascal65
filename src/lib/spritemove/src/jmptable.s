;
; anim.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Anim library jump table
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.import initAnimLibrary, spriteMoveCall

.segment "JMPTBL"

jmp initAnimLibrary
rts                         ; no cleanup routine
nop
nop
jmp spriteMoveCall
