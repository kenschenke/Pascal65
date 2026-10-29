# Pre-compiled Header

A pre-compiled header file contains the serialized output of the tokenization
and parser phase of the compiler. If present, the compiler will read the
pre-compiled header file instead of tokenizing and parsing the interface file.
If the header file is not present, the compiler will tokenize and parse the
interface file.

## Naming Convention

The header file is named *library*.hdr. For example, the header file for the
screen library is named *screen.hdr*.

## Making a Header File

A program is included on the Pascal65 disk called *mkhdr*. It
prompts for the interface filename and writes out the pre-compiled header file.
