# OUT Instruction

## Synopsis

```
OUT <data type>
```

## Description

The **OUT** instruction outputs the value at the top of the runtime stack
to the current output file. The value is popped off the runtime stack.
The current output file defaults to the screen but can be changed with
the [SFH](../sfh) instruction.

### Data Type Operand

The data type operand refers to one of the Pascal65 defined types. See the
[data types](../../types) topic for more information.

## See Also

[ONL](../onl), [SFH](../sfh), [INP](../inp)
