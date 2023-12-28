# Procedures And Functions

Pascal functions and procedures are reusable blocks of code that can be called and reused throughout the program.  Procedures are nearly identical to functions.  The only difference is that procedures do not return a value, while functions do.

## Procedure Syntax

```
(* Writes out multiples of input *)
Procedure WriteMultiples(num : Integer);
Var
    i : Integer;
Begin
    For i := 0 To 10 Do Write(num, ' * ', i, ' = ', num * i);
End;
```

## Function Syntax

Functions return a value by assigning the value to the name of the function.  The return type of the function is specified by a colon at the end of the declaration.

```
(* Returns square of input *)
Function Square(num : Integer) : LongInt;
Begin
    Square := num * num;
End;
```

## Parameters

Procedures and functions can be passed parameters, though none are required.  Parameters can be passed by value or by reference.  If an array or record is passed by value, a copy is made for the routine and discarded when the routine exits.

Parameters of different types are separated by a semicolon.  Consecutive parameters of the same type can be grouped by comma.

```
    Procedure ExampleProc(a, b, c : Integer; i, j, k : Real);
```

### By Value

Parameters passed by value are provided to the procedure or function for its own private use.  A copy is made and can be modified without affecting the caller's data.  For records and arrays, a local copy is made and discarded on exit.


### By Reference

Parameters passed by reference, called **Var** parameters, are references to the caller's copy of the data.  Any changes made to the parameter are made to the caller's value.  This includes arrays and records.

```
Procedure Double(Var num : Integer);
Begin
    num := num * 2;
End;
```

Only parameters preceded by the **Var** keyword are passed by reference.  In the following example, the first parameter is a reference to the caller's copy of the value.  The second parameter is a copy for the procedure's own use.

```
Procedure DoubleFirst(Var first : Integer; second : Integer);
Begin
    first := first * 2;
    second := second * 2;
End;
```

## Local Variables

Local variables are declared within a **Var** clause following the declaration.

```
    Procedure Example(age : Integer);
    Var
        i : Integer;
    Begin
        i := age * 2;
    End;
```

## Forward Declarations

A procedure or function must be declared before it can be referenced in code.  A forward declaration allows the programmer to place the definition anywhere in the code and still be able to reference it.

The **Forward** keyword specifies a forward declaration.

```
    Procedure ToBeDetermined(i, j : Integer); Forward;
```

## Nested Routines

Procedures and functions can be nested within one another.  This allows the programmer to group related routines and hide nested routines.

The local variables of a routine are accessible by nested routines.  The topic on variable scope goes into depth on this.

The programmer can define multiple nested routines and can nest routines at multiple levels.

In the below example, two procedures are defined.  Inner is nested within Outer.  Notice that Inner's declaration appears before Outer's statement block is defined.

The Inner procedure is not visible or accessible outside of Outer.

```
    Procedure Outer();

        Procedure Inner();
        Begin
            ...
        End;

    Begin (* Beginning of Outer body *)
        Inner();
    End;
```

