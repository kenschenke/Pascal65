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

In memory, strings are stored with the first byte as the length of the string followed
by the characters in the string.

## Comparing Strings

The comparison operators **=**, **<>**, **<**, **<=**, **>** and **>=** compare
strings. For example:

```
If answer = 'yes' Then ...

If CompareStr(a, b) < 0 Then ...   (* the same as: If a < b Then ... *)
If a < b Then ...
```

Either side can be a string variable, a string literal, the result of a
concatenation or of a function that returns a string, a character, or an
array of characters. A character compares as a string one character long,
and an array of characters as a string as long as the array. Comparing a
string with anything else, such as a number, is an error.

Two characters compare as characters, by their character codes, as always.

Strings compare character by character. The first character that differs
decides the order. If one string runs out first, it is the shorter string
and comes first, so `'abc' < 'abcd'` and the empty string `''` comes before
every other string. The result is the same as comparing the result of
[CompareStr](../funcref/comparestr.md) with 0.

### PETSCII Order

The comparisons are case-sensitive and use the PETSCII character codes, not
ASCII. In the MEGA65's lower and upper case character set, lower case
letters are codes 65 to 90 and upper case letters are codes 193 to 218, so
every lower case letter comes before every upper case letter:

```
'a' < 'A'          (* True *)
'Zebra' > 'apple'  (* True *)
```

This is the reverse of ASCII. To compare without regard to case, convert
both strings first with [UpCase](../funcref/upcase.md) or
[LowerCase](../funcref/lowercase.md).

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
|[UpCase](../funcref/upcase.md)         |Returns an upper-case string                  |
