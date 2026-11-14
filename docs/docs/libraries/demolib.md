# Demo Library

The source code repository includes a demo library, located in /src/lib/demolib.
This library demonstrates the core concepts in writing a library. The library
includes the following examples.

  * Functions and procedures that accept parameters by reference and by value
  * Modifying parameters passed by reference
  * How to return values from functions
  * Accessing arrays, records and strings passed by parameter.
  * Reading and modifying public variables declared in the library's interface.
  * Arrays, records, and strings declared in the library's interface.
  * Calling Pascal routines from a library (callback)
  
## DemoLib2

The same directory builds a twin, DemoLib2 (`demolib2.pas`), in the
[version 2 object file format](objfile.md#version-2). It has its own jump
table (`src2/demolib2.s`) and every DemoLib routine, plus two that test
the format: `PageBytes` reads a table of bytes in the library's own page
range, which a version 1 library couldn't hold, and `BssCounter` uses
variables in the `BSS` segment, which the compiler zeroes. The Makefile
links it with `mkreloc.py`.
