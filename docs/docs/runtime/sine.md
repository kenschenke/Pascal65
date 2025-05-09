# Sine

This routine calculates the sine of the angle, in radians.

## Usage

The **rtSine** routine is defined in **/src/asmimc/runtime.inc** in the GitHub repo.

```
jsr rtSine
```

## Real Numbers

Pascal 65 supports 32-bit real numbers, what most programming
languages refer to as single-precision. The numbers are specified
by a 24-bit mantissa and an 8-bit exponent.

The [strToFloat](./strtofloat.md) routine can be used to convert a
NULL-terminated string to a float if needed.

## Input

The input is the angle in radians, specified as a 32-bit real number.
The mantissa is stored from least-significant to most-significant byte
order in A, X, and sreg. The exponent is stored in sreg+1.

## Output

The calculated sine value for the angle is returned in the same format
in the A, X, and sreg registers.

## Example

```
    ; Convert "1.5" to a real number

    lda #<rad
    ldx #>rad
    jsr rtStrToFloat

    ; The real number is already in A, X, and sreg
    jsr rtSine

    ; Store the real number in var
    sta var
    stx var+1
    lda sreg
    sta var+2
    lda sreg+1
    sta var+3

    rad: .asciiz "1.5"
    var: .dword 0
```

## See Also

[cosine](./cosine.md), [tangent](./tangent.md), [strToFloat](./strtofloat.md)
