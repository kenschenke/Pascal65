# LibLoadParam

This routine loads a parameter from the runtime stack into processor
registers. It is a helper routine for library routines that are
passed parameters from Pascal programs.

## Inputs

The zero-based parameter number is passed in A.

## Outputs

The low byte of the parameter is returned in A. The next highest byte
is returned in X. The two high bytes are returned in *sreg*.

## Example

```
lda #0              ; Load the first parameter
jsr rtLibLoadParam
```

## See Also

[LibStoreVarParam](../libstorevarparam), [LibReturnValue](../libreturnvalue)
