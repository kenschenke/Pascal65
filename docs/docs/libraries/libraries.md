# Libraries

Developers can create a library to be used by Pascal65 programs. A library
consists of two files that are used by the compiler, and an optional third
file that can speed up compilation. The first is an interface file which
describes the publicly accessible parts of the library such as
functions, procedures, declarations, and types. The implementation code for a
library is in an object file. The object file must be in a specific format and
will typically be written in assembly language. The third file, which is optional,
is a pre-compiled version of the interface file. The output of tokenizing and parsing the
interface file are saved in a pre-compiled header file. This results is a small
speed-up during the compilation phase.
