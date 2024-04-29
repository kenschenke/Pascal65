# PushEax

This routine pushes a 32-bit value onto the runtime stack.

## Inputs

The A register contains the lowest byte and the X register
contains the next highest byte. The high bytes are placed
in *sreg*.

## Examples

```
; Put $12345678 on the runtime stack

lda #$34
sta sreg
lda #$12
sta sreg + 1
ldx #$56
lda #$78
jsr rtPushEax
```

Here is an example of passing an 8-bit value in.

```
; Put $12 on the runtime stack

lda #$12
ldx #$00
stx sreg
stx sreg + 1
jsr rtPushEax
```

## See Also

[PopEax](/runtime/popeax)
