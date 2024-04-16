# Strings

The **String** datatype contains a string of characters up to 255 long. Strings are
dynamically allocated and grow or shrink when changed. They will only consume as many
bytes as necessary.

When a string is assigned to the value of another string
the new string is a copy of the original string and can be modified independently.
Functions and Procedures that accept string parameters can be passed strings variables,
character literals, string literals, or character arrays.

## Accessing Characters

Brackets **[** and **]** can be used to access individual characters in a string,
much like an array. String indexes are 1-based so they start at 1. If a program
attempts to access a character with an index below 1 or beyond the string length,
a runtime error occurs.

### Examples

```
Var
   str : String;
   ch : Char;

Begin
   str := 'Hello World';
   ch := str[2];  (* ch becomes 'e' *)
   str[1] := 'J';  (* str becomes 'Jello World' *)
```

## Concatenating Strings

The **Plus** operator concatenates strings and literals.  For example:

```
str := 'hello' + ' ' + 'world';
```

The concatenation operater accepts string objects, string literals, character literals,
and arrays of characters.

**Note**: Strings cannot be used inside records or arrays. This will eventually be
supported in the future.

In memory, strings are stored with the first byte as the length of the string followed
by the characters in the string.

## String Routines

The runtime library has a few functions and procedures to handle strings.

|Function                               |Description                                   |
|---------------------------------------|----------------------------------------------|
|[BeginsWith](../funcref/beginswith.md) |Determines if a string begins with a substring|
|[Contains](../funcref/contains.md)     |Determines if a string contains a substring   |
|[EndsWith](../funcref/endswith.md)     |Determines if a string ends with a substring  |
|[Length](../funcref/length.md)         |Returns the string length                     |
|[LowerCase](../funcref/lowercase.md)   |Returns a lower-case string                   |
|[StringOfChar](../funcref/strofchar.md)|Returns a string filled with a character      |
|[StrPos](../funcref/strpos.md)         |Returns the position of a substring.          |
|[Trim](../funcref/trim.md)             |Removes leading and trailing spaces           |
|[UpCase](../funcref/upcase.md)         |Returns a lower-case string                   |
