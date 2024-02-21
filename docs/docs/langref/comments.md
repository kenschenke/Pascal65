# Comments

Comments in Pascal are started with an open parenthesis followed by an
asterisk and closed with an asterisk followed by a closing parenthesis.
This is how a comment would look:

```
   i := i + 1;  (* add one to i *)
```

Comments can span multiple lines like this:

```
   (*
    * This is a multi-line comment.
    *
    * This is more line of the comment.
    *)
```

## Single-line Comments

Pascal65 also recognizes a double-slash as a comment, like C++ and Java.
Any characters from the double-slash to the end of the line are ignored.

```
   i := i + 1;  // add one to i
```

## Nested Comments

Pascal65 does not recognize nested multi-line comments. The following would generate an error.

```
   (*
    i := i + 1;  (* add one to i *)
    *)
```

However, the following would be fine.

```
   (*
   i := i + 1;  // add one to i
    *)
```

This is also fine:

```
   // i := i + 1;  (* add one to i *)
```
