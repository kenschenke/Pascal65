# Data Types

Pascal has two main classes of data types: standard data types and declared data types.

## Standard Data Types

Pascal65 defines the following standard data types.

| Data Types | Description                                                   |
| ---------- | ------------------------------------------------------------- |
| ShortInt   | Signed 8-bit integer in the range -128 to +127                |
| Byte       | Unsigned 8-bit integer in the range 0 to 255                  |
| Integer    | Signed 16-bit integer in the range -32768 to +32767           |
| Word       | Unsigned 16-bit integer in the range 0 to 65535               |
| LongInt    | Signed 32-bit integer in the range -2147483648 to +2147483647 |
| Cardinal   | Unsigned 32-bit integer in the range 0 to 4294967295          |
| Boolean    | True or False                                                 |
| Char       | PETSCII character                                             |
| Real       | Signed 24-bit floating point value (see below)                |
| String     | A string of PETSCII characters (see below)                    |

The compiler will generate an error if the program attempts to assign an integer variable
to another variable that cannot accomodate the entire range.  This includes attempts to
assign a signed variable to an unsigned variable of any size.  There is no error if an
unsigned variable is assigned to a signed variable of larger size.

### Real Data Type

The **Real** data type is a signed 24-bit floating point value with an signed 8-bit exponent.
Real values can be expressed in standard format such as *1.234* or scientific notation such as
*1.2e+8*.

## String Data Type

The **String** data type is a string consisting of up to 255 PETSCII characters.
Strings can be assigned to other strings, character literals, string literals,
and arrays of characters. Please see the [strings](strings.md) topic for more information.

## Character Data Type

The **Char** data type contains a single PETSCII character in the range of 0..255.
Character literals appear inside single quotes or can be specified by the numeric PETSCII
value following a hash character. If a dollar sign follows the hash character, the value is
a hexidecimal. All of the following are valid character literals.

```
   ch := 'a';
   ch := #65;  // Same as letter 'a'
   ch := #$41; // Same as letter 'a' (41 is 65 in hex)
```

## Pointer Data Type

A pointer is a variable that *points* to another variable. In this case, *points* means
that the pointer variable is linked to the other variable. Updates to the pointer actually
update the variable pointed to by the pointer. Please see the [pointers](pointers.md) topic
for more information.

## Declared Data Types

Examples of declared data types are arrays and records, discussed in separate topics.

## Type Declarations

A type declaration defines a new data type, but can be thought of as an alias for an existing
type.  These are declared in the **Type Declaration** section in the program.  An example one
might look like this:

```
Type
   Age, Height = Integer;
   Yes, No = Boolean;
   Length = Real;
```

## Type Casting

An expression can be explicitly converted to a different data type by preceding it with
the target type's name, in parenthesis, the same way a function is called.  This is useful
for converting between integer types of different sizes or signedness. Without a type cast,
assignments between incompatible integer types display warning of loss of precision.

```
Var
   b : Byte;
   w : Word;
   i : Integer;

Begin
   w := 40000;
   b := Byte(w);        // truncates to the low 8 bits of w
   i := Integer(b);      // widens b into a 16-bit signed integer
End.
```

Type casting works between any combination of **ShortInt**, **Byte**, **Integer**, **Word**,
**LongInt**, **Cardinal**, **Char**, **Boolean**, and declared types.  Casting to a smaller
type truncates the value and casting to a larger type widens it (sign-extending signed types
and zero-extending unsigned types).  No warning is raised if a value doesn't fit in the target
type -- the value is simply truncated.

**Real** cannot be used in a type cast.  Use the [Round](../funcref/round.md) or
[Trunc](../funcref/trunc.md) standard routines instead to convert a **Real** value to an
integer type.

## Data Types of Expressions

The compiler makes decisions about an expression's implied data type using the following rules.

  1. If either operand is a real variable, constant, or literal, the result of the expression is
  a real number.

  2. If both operands are constants or literals, the result is the next size up from the largest
  of the two operands.

  3. If one operand is a variable and the other operand is a constant or literal, the result of
  the expression will be the same type as the variable. If the variable is smaller than the
  literal then the result of the expression is made big enough to accommodate the literal.

  4. If both operands are variables, the result of the expression will be the data type of the
  largest-sized variable. If both of the variables are unsigned, the result is unsigned.
  Otherwise the result is signed.

## Constants

Constants are delcared in the **Constants** section in the program.  An example section might
look like this:

```
Const
   Pi = 3.14159;
   MaxLength = 99.99;
```

Integer constants are mapped to one of the integer data types based on the range.

| Range                     | Mapped to Data Type |
| ------------------------- | ------------------- |
| -128..127                 | ShortInt            |
| 128..255                  | Byte                |
| -32768..32767             | Integer             |
| 32768..65535              | Word                |
| -2147483648 to 2147483647 | LongInt             |
| 2147483648 to 4294967295  | Cardinal            |

The compiler will generate an error if the program attempts to assign an integer constant
to a variable that cannot accomodate it.  For example, the compiler will not let you assign
the constant 32768 to an Integer.  The same applies for integer literals.

## Hexadecimal Literals

Hexadecimal literals can be declared with a dollar sign followed by the digits, such as:

```
   a := $d020;
```

## Binary Literals

Binary literals can be declared with a percent sign followed by the digits, such as:

```
   a := %11010001;
```

## Enumerated Types

Enumerated types define a new data type with a list of acceptable values.  They are declared
in the **Type Declaration** section like this:

```
Type
   Months = (Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec);
```

## Subrange Types

Subrange types define a range of integers or characters.  Subranges are most commenly used in
array declarations.  Subranges can be used as a declared type or directly in the 
**Variable Declarations** section.  Examples are:

```
Type
   AgeRange = 1..99;

Var
   MiddleInitial : 'a'..'z';
```
