# Runtime Library

Pascal65 provides a runtime library that is included in programs produced
by the compiler. It includes a wide variety of utility routines and helpers.
Many of them will be helpful to those wishing to write additional libraries.

It is not necessary to understand anything about the runtime library in order
to write Pascal code. The runtime library is automatically referenced by the
compiler.

## Location of Runtime Library Code

The runtime library code is placed by the linker at a fixed address. This
allows users of the runtime library to call into routines at a predictable
address.

## Runtime Header

Libraries wishing to use the runtime library will need to include the
*runtime.inc* header file, located in the source code repository in the
src/asminc directory. Each runtime library entry point is defined.

## Runtime Stack

The runtime library makes heavy use of the runtime stack. Several runtime
library routines require inputs to be placed on the runtime stack and
will place results on the runtime stack for consumption. Please take a
moment to read the [this page](../libraries/stack.md) for a complete
discussion of the stack.

### Stack Routines

The runtime library provides a handful of routines that manipulate the
stack.

|Routine                      |Description        |
|-----------------------------|-------------------|
|[PushEax](../pusheax)  |Push a 32-bit value|
|[PopEax](../popeax)    |Pop a 32-bit value |

