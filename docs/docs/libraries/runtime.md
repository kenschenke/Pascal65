# Runtime Library

The Pascal65 runtime library is linked into all object files and is available
to any library. The runtime library is always placed at a fixed address in the
object code. This means that all routines in the runtime library are at known
addresses, much like the Kernal.

The runtime library entry points are documented in the *Runtime Library*  section.

## Header File

Everything in the runtime library is defined in **runtime.inc**, located in
src/asminc in the source code repo.

### Zero Page Variables

The runtime defines several reserved locations in page zero. Most of them
are for internal use only, but several are of importance to libraries.

|Variable Name|Description                                     |
|-------------|------------------------------------------------|
|sreg         |3rd and 4th bytes of a 32-bit value             |
|ptr1-ptr4    |Temporary pointers (2 bytes each)               |
|tmp1-tmp4    |Temporary variables (1 byte each)               |
|stackP       |Pointer to base of stack frame (current routine)|

**Note**: ptr1, ptr2, ptr3, ptr4, and tmp1, tmp2, tmp3, tmp4 are considered
volatile and their contents are frequently modified by the runtime library.
Always assume their contents will be modified by calls made into the
runtime library.
