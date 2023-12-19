# Poke

Stores a byte value in a memory location.

## Declaration

    PROCEDURE Poke(address : word; value : byte);

## Description

*Poke* stores a byte value in a supplied memory location.

## Example ##

```
PROGRAM example;

BEGIN
    (* Set the border color to white *)
    poke($d020, 1);
END.
```
