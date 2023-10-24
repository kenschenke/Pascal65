# While Statement

The **While** statement evaluates a logic condition and executes a statement or statement block in a loop as long as the condition evaluates to true.  The condition is evaluated at the
beginning of each loop iteration.  If the condition is false at the start of the first iteration,
the statement or statement block is never executed.  This is in contrast with the **Repeat-Until**
statement which executes the statement(s) inside the loop at least once.

The condition must evaluate to a boolean.  For example, to test if an integer
is non-zero use *myInt &lt;&gt; 0*.

## Syntax

The statement(s) can be a single statement or a statement block.  Both are shown.

```
(* Executes <statement> in a loop as long as <condition> is true *)
While <condition> Do
    <statement>;

While <condition> Do Begin
    <statement-1>;
    <statement-2>;
    ...
    <statement-n>
End;
```
