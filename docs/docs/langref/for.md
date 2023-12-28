# For Statement

The **For** statement executes a statement or statement block a pre-determined number of times.  A loop-counter variable is specified as well as a starting and ending value.  The loop counters are inclusive at both ends.

## Syntax

The statement(s) can be a single statement or a statement block.  Both are shown.

```
(* Executes <statement> in a loop a pre-determined number of times *)
For <loop-variable> := <start-number> <To/DownTo> <end-number> Do
    <statement>;

For <loop-variable> := <start-number> <To/DownTo> <end-number> Do Begin
    <statement-1>;
    <statement-2>;
    ...
    <statement-n>
End;
```

## Examples

```
(* Prints:
    i = 1
    i = 2
    i = 3
*)
For i := 1 To 3 Do
    Writeln('i = ', i);
```

```
(* Prints:
    3: 6
    2: 4
    1: 2
*)
For i := 3 DownTo 1 Begin
    j := i * 2;
    Writeln(i, ': ', j);
End;
```
