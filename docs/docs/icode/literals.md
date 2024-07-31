# Intermediate Code Literals

When an operand is a literal value, the type is indicated from the table below.

|Hex Value|Type  |Description            |
|---------|------|-----------------------|
|11       |IC_CHR|Character              |
|12       |IC_IBU|Unsigned 8-bit integer |
|13       |IC_IBS|Signed 8-bit integer   |
|14       |IC_BOO|Boolean value (0 or 1) |
|15       |IC_IWU|Unsigned 16-bit integer|
|16       |IC_IWS|Signed 16-bit integer  |
|17       |IC_ILU|Unsigned 32-bit integer|
|18       |IC_ILS|Signed 32-bit integer  |
|19       |IC_FLT|Real number            |
|1a       |IC_STR|Null-terminated string |

## Representation in Intermediate Code Stream

Literals are stored in the intermediate code stream by the hex value from the
above table followed by the value itself. A character literal, 8-bit integers,
and boolean values are stored in 1 byte, 16-bit integers in two bytes, and 32-bit
integers in 4 bytes.

### Real Numbers

Real numbers are stored in their string representation, as a null-terminated string.

### String Literals

String literals are stored as a null-terminated string.
