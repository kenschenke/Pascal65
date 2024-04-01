# Building Pascal65

If you wish to experiment with Pascal65 or make changes, this document
describes the build process. You do not need any of this if you simply
want to use Pascal65.

Pascal65 is built with the CC65 compiler and assembler. The compiler
must be in your path. The build process is designed to work on a *nix
system. The author uses the Windows Subsystem for Linux but the process
should work fine on any Linux or MacOS system as well.

Disk images are created using the c1541 program that comes with VICE.
This command must be in your path as well.

To build Pascal65 run this command from the root of the repo.

```
make
```

A D81 disk image will be created in the bin/mega65 directory.

To run Pascal65 in the Xemu emulator, run:

```
make run
```

The xmega65 command must be in your path.
