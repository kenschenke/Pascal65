# Variable Scope

Pascal programs can declare variables in a variety of places in the code. The
placement and names of these variables affects which parts of the code can
access them. This is referred to as variable scope.

## Global Scope

Variables declared in the **Var** section at the top of the main source file
are global variables and can be accessed from any function or procedure in
the code, including in units used in the program. Following is a short example
that demonstrates global scope.

```
Program GlobalScope;

Var MyVar : Integer;

Procedure UpdateMyVar;
Begin
    MyVar := 5;
End;

Procedure ShowMyVar;
Begin
    Writeln('MyVar = ', MyVar);
End;

// Main Procedure
Begin
    UpdateMyVar;
    ShowMyVar;
End.
```

## Procedure and Function Scope

Variables declared in the **Var** section for a function or procedure are accessible
only within that routine *and* in nested routines. First, an example of a procedure's
local variables.

```
Program LocalScope;

Var GlobalVar : Integer;

Procedure MyProcedure;
Var LocalVar : Integer;
Begin
    GlobalVar := 5;  // MyProcedure can still access global variables
    LocalVar := 10;
End;

// Main Procedure
Begin
    LocalVar := 15;  // Compiler error -- LocalVar cannot be accessed outside MyProcedure
End.
```

Here is an example of variable scope in embedded routines.

```
Program Embedded;

Var GlobalVar : Integer;

Procedure Outer;
Var OuterVar : Integer;

    Procedure Inner;
    Var InnerVar : Integer;
    Begin
        InnerVar := 5;  // Inner can access its local variable
        OuterVar := 10; // It can also access the parent scope's local variables
        GlobalVar := 3; // And it can access global variables
    End;

// Outer procedure's code
Begin
    OuterVar := 5;  // Outer can access its local variables
    GlobalVar := 3; // It can also access global variables
    InnerVar := 10; // Compiler error - Outer cannot access Inner's local variables
End;
```

## Variable Name Resolution

When a program accesses a variable the compiler will look for that variable from the
inside out. In other words, from the current scope, the parent scope, and so on until
it reaches the global scope. When the compiler finds a match it stops looking. This
means that if a local variable has the same name as a variable in a parent or the
global scope, the parent scope's variable is hidden and cannot be accessed.

The following example demonstrates this.

```
Program ScopeDemo;

Var
    Name : String;

Procedure AskForName;
Var
    Name : String;  // the global "Name" variable is hidden
Begin
    Write('Enter name: ');
    Readln(Name);  // Local variable is modified
End;

// Main procedure
Begin
    AskForName;
    Writeln('Hello ', Name);  // Name is an empty string!!
End.
```

This program declares *Name* as a global variable. It then calls the *AskForName*
procedure which also declares a local variable with the same name. It prompts the
user for their name and reads it into the **local** variable. Back in the main
procedure, the program attempts to write the user's name to console but it is
an empty string since *AskForName* did not modify the global *Name* variable.
