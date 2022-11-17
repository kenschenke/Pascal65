# Welcome to Pascal65

**Pascal65** is a [Pascal](https://en.wikipedia.org/wiki/Pascal_(programming_language) "Pascal")
compiler, interpreter and IDE for 6502-based Commodore
machines.  The Commodore 64, Commodore 128, and [Mega65](https://mega65.org "Mega65") are supported.  Please
see System Requirements for more information.

For full documentation visit [mkdocs.org](https://www.mkdocs.org).

## Major Components of Pascal65

### Compiler

First, and foremost, Pascal65 is a Pascal compiler.  It compiles Pascal source into
fully self-contained PRG files that can be distributed and run independently of Pascal65.

### Interpreter

A Pascal interpreter is also included.  The interpeter runs Pascal source files directly
without having to compile them into PRG files.  As you can guess, the interpreter runs slower
than a compiled PRG file.  For a lot of code, the speed difference is not important.

### IDE

Pascal65 also includes an integrated development environment.  The editor can edit multiple
open files, compile code, and even run the interpreter without leaving the IDE.

* `mkdocs new [dir-name]` - Create a new project.
* `mkdocs serve` - Start the live-reloading docs server.
* `mkdocs build` - Build the documentation site.
* `mkdocs -h` - Print help message and exit.

## Project layout

    mkdocs.yml    # The configuration file.
    docs/
        index.md  # The documentation homepage.
        ...       # Other markdown pages, images and other files.
