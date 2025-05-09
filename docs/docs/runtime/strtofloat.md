# StrToFloat

This routine converts a NULL-terminated string into a 32-bit real number.

## Usage

The **rtStrToFloat** routine is defined in **/src/asmimc/runtime.inc** in the GitHub repo.

```
jsr rtStrToFloat
```

## Real Numbers

Pascal 65 supports 32-bit real numbers, what most programming
languages refer to as single-precision. The numbers are specified
by a 24-bit mantissa and an 8-bit exponent.

## Input

A pointer to the NULL-terminated string is passed in A (low byte)
and X (high byte).

The string can be in standard or scientific notation.

## Output

The real number is returned in A, X, and sreg.

## Example

```
    ; Convert "123.45" to a real number

    lda #<str
    ldx #>str
    jsr rtStrToFloat

    ; Store the real number in var
    sta var
    stx var+1
    lda sreg
    sta var+2
    lda sreg+1
    sta var+3

    str: .asciiz "123.45"
    var: .dword 0
```
