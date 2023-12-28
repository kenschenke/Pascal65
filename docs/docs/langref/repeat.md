# Repeat-Until Statement

The **Repeat-Until** statement evaluates a logic condition and executes one or more statements in a loop as long as the condition evaluates to false.  The condition is evaluated at the
end of each loop iteration.  If the condition is true at the end of an iteration,
the loop stops.  The statements inside the **Repeat** are guaranteed to execute at least once.  This is in contrast with the **While**
statement which evaluates the condition before each iteration and executes the statement(s) inside the loop only if the condition is true.

The condition must evaluate to a boolean.  For example, to test if an integer
is non-zero use *myInt &lt;&gt; 0*.

## Syntax

The statement(s) can be a single statement or a statement block.  Both are shown.

```
(* Executes <statement> in a loop as long as <condition> is false *)
Repeat
    <statement-1>;
    <statement-2>;
    ...
    <statement-n>;
Until <condition>;
```
