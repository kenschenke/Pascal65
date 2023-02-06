# If Then Else

The **If** statement tests a logic condition and executes a statement or block
if the condition is true.  If an **Else** clause is present and the condition is false,
the statement or block following *Else* is executed instead.

The condition must evaluate to a boolean.  For example, to test if an integer
is non-zero use *myInt &lt;&gt; 0*.

## Syntax

The *If Then* statement can be used with or without an *Else* clause.

### If Then

The *If Then* form evaluates the condition and executes the
&lt;statement-if-true&gt; statement if condition evaluates to true.
Execution continues with the next statement regardless of the value
of the condition.  The *If Then* form looks like this:

```
(* Executes <statement-if-true> if <condition> evalulates to true *)
If <condition> Then
    <statement-if-true>
```

### If Then Else

The *If Then Else* form evaluates the condition and executes the
&lt;statement-if-true&gt; statement if condition evaluates to true.
Otherwise the &lt;statement-if-false&gt; statement executes.
Execution continues with the statement following the
&lt;statement-if-false&gt; regardless of the value
of the condition.  The *If Then Else* form looks like this:

```
(*
    Executes <statement-if-true> if <condition> evaluates to true or
    <statement-if-false> is <condition> is false.
*)
If <condition> Then
    <statement-if-true>
Else
    <statement-if-false>
```

**Important**: a common beginner mistake in Pascal is to place a semicolon at the
end of the &lt;statement-if-true&gt; statement when using an *Else*.  Pascal considers
the entire *If-Else* block to be one statement so no semicolon should appear until the
end of the *If-Else* block.  For example:

```
If myInt <> 0 Then
    writeln('The number is non-zero')
Else
    writeln('The number is zero');
```

### Compound Statements

If more than one statement needs to execute, multiple statements can be enclosed inside
**Begin** and **End**.  For example:

```
If userAge < 90 Then
    writeln('You are not yet 90 years old')
Else Begin
    writeln('You qualify for a special price');
    price := price - 5
End;
```

Notice the semicolon after the *End* statement.
