# Libraries

A library is a way to put object code into a program during the compile and
linking process.  Libraries are compiled or assembled into object code
ahead of time and can greatly speed up compilation time.

Libraries are typically developed in another language such as assembly
language. Please see the *Libraries* section for more information.

## Using a Library

Libraries are referenced just like a unit with the **Uses** statement.

```
Uses Screen;
```

This statement lets the compiler know that the program will be using the
screen library.

## System Library

Pascal65 provides a system library which implements most of the functions
and procedures available to all programs such as **Chr** and **GetKey**.
The system library is automatically added to all programs.
