# LibReturnValue

This routine returns a value back to a Pascal function. It is a helper
routine for libraries.

## Inputs

The low byte of the value is passed in A. The next highest byte is
passed in X. The two high bytes are passed in *sreg*.

## Example

```
; Return $12345678 to the Pascal function
lda #$34
sta sreg
lda #$12
sta sreg+1
lda #$78
ldx #$56
jsr rtLibReturnValue
```

## See Also

[LibLoadParam](../libloadparam), [LibStoreVarParam](../libstorevarparam)
