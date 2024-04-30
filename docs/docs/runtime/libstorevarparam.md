# LibStoreVarParam

This routine stores a value back into a *Var* parameter
(passed by reference) from a Pascal program.

## Inputs

The zero-based parameter number is passed in Y. The low byte of the value
is passed in A. The next highest byte is passed in X. The two high bytes
are passed in *sreg*.

## Example

```
; Store $12345678 in the Var parameter
ldy #0              ; The first parameter
lda #$34
sta sreg
lda #$12
sta sreg+1
lda #$78
ldx #$56
jsr rtLibStoreVarParam
```

## See Also

[LibLoadParam](/runtime/libloadparam), [LibReturnValue](/runtime/libreturnvalue)
