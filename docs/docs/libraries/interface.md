# Library Interface

A library's interface file describes the publicly accessible portion of the library.
It describes the functions, procedures, constants, shared variables, and 
defined types.

The interface file is very similar to a **Unit** file and its filename is the same
as the library with a **.PAS** suffix. For example, a *Math* library's interface
file would be *Math.pas*.

The syntax for the interface file starts out just like a unit. The interface
section is identical but the implementation section is left blank except for the
addition of the **library** keyword. Following is how an interface file for a
math library might look.

```
Unit Math;

Interface

Function Cos(num : Real) : Real;
Function Sin(num : Real) : Real;

Implementation Library

End.
```
