# Divide

This routine divides two real numbers, *operand-1* by *operand-2*.
The inputs can be a mix of compatible data types.

This routine performs only floating point division. All inputs
will be converted to floating point prior to division.

This routine does not check for overflow. If *operand-2* is zero,
a runtime error is thrown and the code exits immediately.

## Supported Data Types

Constant definitions for the supported data types can be found in the
/src/asminc/types.inc file in the source code repository.

|Constant|Define       |Type                   |
|--------|-------------|-----------------------|
|1       |TYPE_BYTE    |Unsigned 8-bit integer |
|2       |TYPE_SHORTINT|Signed 8-bit integer   |
|3       |TYPE_WORD    |Unsigned 16-bit integer|
|4       |TYPE_INTEGER |Signed 16-bit integer  |
|5       |TYPE_CARDINAL|Unsigned 32-bit integer|
|6       |TYPE_LONGINT |Signed 32-bit integer  |
|7       |TYPE_REAL    |Floating point number  |

## Inputs

The routine divides *operand-1* by *operand-2*.
Both operands are pushed onto the runtime stack with [PushEax](/runtime/pusheax),
with *operand-1* pushed first, followed by *operand-2*.

|Register|Description             |
|--------|------------------------|
|A       |Data type of *operand-1*|
|X       |Data type of *operand-2*|

## Result

On return, the result is left at the top of the runtime stack and is accessed by
a call to [PopEax](/runtime/popeax).

## Example

```
; Divide $1234 by $05
lda #$00
sta sreg
sta sreg+1
lda #$34
ldx #$12
jsr rtPushEax       ; Push operand-1 onto the stack
ldx #$00
stx sreg
stx sreg+1
lda #$05
jsr rtPushEax       ; Push operand-2
lda #TYPE_INTEGER
ldx #TYPE_SHORTINT
jsr rtDivide
jsr rtPopEax        ; loads result into A/X/sreg
```

## See Also

[PopEax](/runtime/popeax), [PushEax](/runtime/pusheax),
[Add](/runtime/add), [Subtract](/runtime/subtract),
[Multiply](/runtime/multiply), [DivInt](/runtime/divint)
