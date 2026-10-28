# Notable Differences

Pascal65 is not a complete implementation of the Pascal standard.  The following are
notable differences.

* Sets are not implemented
* Explicit [type casting](langref/datatypes.md#type-casting) of scalar/ordinal types, e.g.
  `Byte(someWord)`, is supported as an extension to standard Pascal

## Code Comments ##

Pascal65 supports single-line comments preceded by a double-slash, similar to many
C-like languages.  Multi-line comments begin with a open parenthesis and asterisk
and end with an asterisk followed by a close parenthesis.  *Pascal65 does not support
comments using curly braces since PETSCII does not contain the curly
brace characters.*
