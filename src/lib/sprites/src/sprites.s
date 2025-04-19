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
.import spriteMultiColorsCall, getSpritePosCall
.import spriteSizeCall, spriteData
.import registerCollisionCallback

.segment "JMPTBL"

jmp initSpriteLibrary
jmp cleanupSpriteLibrary
jmp getSpritePosCall
jmp spriteCall
jmp spriteMultiColorsCall
jmp spritePosCall
jmp spriteSizeCall
jmp spriteData
jmp registerCollisionCallback
