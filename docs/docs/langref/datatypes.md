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
