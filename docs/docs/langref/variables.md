# Variables

Variables in Pascal are declared in the **Var** section. This could be the
Var section of the global scope or the Var section of a procedure or function
scope. Please see the [variable scope](/langref/scope) section for more information.

## Declarations

A variable is declared (defined) by specifying the variable name followed by a
colon and then the variable type. For example, to declare an integer named *i*,
it would look like this:

```
i : Integer;
```

## Multiple Declarations

The program can declare multiple variables of the same type by separating them
with colons, like this:

```
i, j, k : Integer;
```

## Initial Value

If no initial value is specified, a variable's initial value is defined by its
type. Integers are zero, boolean is false, characters are zero, and strings are
an empty string. To specify a different value, use an equal sign followed by the
value. For example:

```
ch : Char = 'a';
flag : Boolean = true;
i : Integer = 5;
name : String = 'John Smith';
```

The initial value must be a literal value or a constant. The following are errors.

```
i : Integer = 5;      // This one is okay.
j : Integer = i;      // Initial value must be a literal
ch : Char = Chr(65);  // Initial value cannot be a function
```
