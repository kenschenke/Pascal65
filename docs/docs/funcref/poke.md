# Poke

Stores a value in a memory location.

## Declaration

    Procedure Poke(address : Cardinal; value : Byte);
    Procedure PokeW(address : Cardinal; value : Word);
    Procedure PokeL(address : Cardinal; value : Cardinal);

## Description

*Poke* stores a byte value in a supplied memory location. The memory location can be
specified as a 16-bit or 24-bit address.

*PokeW* stores a word value in a supplied memory location.

*PokeL* stores a cardinal value in a supplied memory location.

## Example ##

```
PROGRAM example;

BEGIN
    (* Set the border color to white *)
    poke($d020, 1);
END.
```
