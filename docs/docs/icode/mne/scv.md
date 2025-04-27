# SCV Instruction

## Synopsis

```
SCV <data type>
```

## Description

The **SCV** instruction converts the value at the top of the runtime stack to
a string object. It removes the value from the stack and replaces it with the
newly allocated string object.

### Data Type Operand

The data type operand refers to one of the Pascal65 defined types. See the
[data types](../../types) topic for more information.

This instruction can convert a string literal, a character literal, or an
array of characters. If a string object or string variable is passed in,
the instruction makes a copy of the string.
