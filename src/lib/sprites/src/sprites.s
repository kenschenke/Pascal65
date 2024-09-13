;
; sprites.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Sprites library jump table
; 
; Copyright (c) 2024
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

; Jump table for sprite library

.import initSpriteLibrary, cleanupSpriteLibrary, spriteCall, spritePosCall
.import spriteMoveCall, spriteMoveRelCall, spriteColorCall

.segment "JMPTBL"

jmp initSpriteLibrary
jmp cleanupSpriteLibrary
jmp spriteCall
jmp spriteColorCall
jmp $0000           ; SpriteMultiColor
jmp spritePosCall
jmp $0000           ; SpriteSize
jmp spriteMoveCall
jmp $0000           ; SpriteMoveAngle
jmp spriteMoveRelCall
