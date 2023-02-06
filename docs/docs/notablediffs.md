# Notable Differences

Pascal65 is not a complete implementation of the Pascal standard.  The following are
notable differences.

* Sets are not implemented
* Pointers are missing
* There is no data type for strings.  String literals are implemented as arrays of characters.

## Code Comments ##

Pascal65 supports single-line comments preceded by a double-slash, similar to many
C-like languages.  Multi-line comments begin with a open parenthesis and asterisk
and end with an asterisk followed by a close parenthesis.  *Pascal65 does not support
comments using curly braces since PETSCII does not contain the curly
brace characters.*

## Future Wishes

Support for some of these features is planned for future releases.  Of note:

* Pointers
* Add a data type for strings
