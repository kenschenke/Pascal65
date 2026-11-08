# Compiler Directives

The Pascal65 compiler can read special directives from the program source file that change
settings in the compiled code or configure the compiler.

Directives are enclosed inside a comment block and are preceded by a dollar sign. The comment
block must be the multi-line format that begins with a left parentheis and asterisk and ends
with an asterisk and right parenthesis. See the [comments page](comments.md) for more information.

## Output Directives

### Stack Size

Compiled Pascal programs use a stack to store all information in the program.
That information includes:

* Global variables
* Local variables in each routine
* Parameters passed to routines
* Return values from functions

The stack consumes memory in the computer. The default size of 512 bytes should
be sufficient for most programs. If a larger stack size is required, this
directive can be used.

```
(* $StackSize xxxx *)
```

The stack size can be specified in base-10 or hexidecimal.

#### Example

```
Program Test;

// Stack size of 1024 bytes
(* $StackSize 1024 *)

Begin
    Writeln('Hello world');
End.
```

!!! warning

    Compiled programs do not check for stack overflow during execution.
    A stack overflow occurs when the contents of the stack exceeds the
    allocated size. A stack overflow can cause strange and inconsistent
    behavior and cause the program to crash or behave in unexpected ways.
    If a program exhibits this kind of behavior, increasing the stack size
    might fix it.

### Runtime Mode

Every compiled program needs the Pascal65 runtime library. A program can get
it in one of two ways:

* **Dynamic** (the default): the program loads the runtime from a file named
  `runtime1` when it starts. The program file is much smaller, and compiling
  is faster.
* **Static**: the runtime is linked into the program file. The program
  carries only the parts of the runtime it uses, and needs no other file.

```
(* $StaticRuntime *)
(* $DynamicRuntime *)
```

`$StaticRuntime` links the runtime into the program. `$DynamicRuntime` asks
for the default explicitly. The directives can only be used in a program,
not in a unit or a library, and a program can't use both.

#### Example

```
Program Test;

// Link the runtime into the program
(* $StaticRuntime *)

Begin
    Writeln('Hello world');
End.
```

!!! warning

    A program compiled with the dynamic runtime (the default) won't run
    without the `runtime1` file on the disk it was loaded from. If it's
    missing, the program prints `runtime file runtime1 not found` and
    returns to BASIC. To give a program to someone else, give them
    `runtime1` with it, or compile it with `$StaticRuntime`.

!!! note

    The dynamic runtime is the whole runtime library, and it stays in
    memory below $C000 while the program runs. A dynamic program therefore
    has less room for its code, heap and stack than a static one. If a
    program is too large, the compiler reports a code segment overflow
    and suggests `$StaticRuntime`, which may make it fit.

    The number in the file name is the runtime's version. A program loads
    the runtime version it was compiled for, so a newer compiler's runtime
    on the same disk doesn't break older programs.

### Expect Warning and Expect Error

These directives are used for compiler development and testing. They
indicate a particular line of code is expected to generate a warning
or error. The directive is used by providing the expected warning or
error number, like this:

```
int := 123456; (* $ExpectWarn 66 *)
num := 'Hello World'; (* $ExpectError 38 *)
```

The above lines of code will generate a warning about loss of precision,
since integers can only contain numbers up to 32767. Warning number 66
is the loss of precision warning. The second line of code will generate
an incompatible assignment error number 38.

!!! warning

    These directives are not intended for production code and only work
    in compiler tests written for the specific use of testing. If these
    directives are used in the production compiler they will generate
    an unexpected token error.
