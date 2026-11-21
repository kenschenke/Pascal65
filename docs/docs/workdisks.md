# Work Disks

Pascal65 can keep your work on a disk of its own, apart from the Pascal65 disk. The
Pascal65 disk is then the **system disk**: the IDE, the compiler, the libraries, the
examples and the help file. The other disk is a **work disk**: your source files and
everything the compiler makes from them.

When a new version of Pascal65 comes out, you replace the system disk and keep your
work disks as they are. A work disk per project keeps each project's files together.

Without a work disk, Pascal65 works the way it always has: everything is read from and
written to the one disk. This is **single-disk mode**.

## Making a Work Disk

Pascal65 doesn't format disks. Format a blank disk yourself first, for example a disk
in unit 9:

```
HEADER "MYWORK",IWD,U9
```

Then choose **3** in the work disk dialog (below) to make it a work disk. Pascal65
only does this to a disk with no files on it. It writes three files:

|File        |Contents                                                   |
|------------|-----------------------------------------------------------|
|`p65work`   |The marker that tells Pascal65 the disk is a work disk     |
|`runtimeN`  |The runtime that compiled programs load (N is its version) |
|`themes.dat`|A copy of the system disk's syntax highlighting colors     |

Don't delete `p65work`. Without it, Pascal65 no longer treats the disk as a work disk.

## Starting the IDE

When the IDE starts, it looks for a work disk on units 9, 10 and 11:

  - If it finds exactly one work disk, it uses it without asking.
  - If no drive answers on those units, it starts in single-disk mode.
  - Otherwise (two work disks, or a disk that isn't a work disk) it shows the work disk
    dialog.

The dialog waits until you choose one of these:

|Key|Choice                                                                |
|---|----------------------------------------------------------------------|
|1  |Single disk: work on the system disk                                  |
|2  |Use the work disk on the device shown                                 |
|3  |Make the blank disk on the device shown a work disk                   |
|D  |Change the device: type 8 to 30 and press Return                      |

The dialog starts on device 9. If the device can't be used, the dialog shows why and
waits for another choice:

|Message                              |Meaning                                        |
|-------------------------------------|-----------------------------------------------|
|`nothing answers`                    |No drive answers on that device                |
|`no disk in the drive`               |The drive answers but has no disk in it        |
|`not a work disk`                    |The disk has files but no `p65work` (choice 2) |
|`not blank`                          |The disk already has files on it (choice 3)    |
|`bad work disk marker`               |`p65work` is damaged                           |
|`the system disk`                    |That is the system disk's device               |
|`disk error (full/protected?)`       |A file couldn't be written                     |
|`The system disk has no runtime file`|`runtimeN` is missing from the system disk     |
|`Devices are 8 to 30`                |The device number typed is out of range        |

Any drive can hold the work disk, including a 1581 or an SD2IEC on unit 10 or higher.

Each time Pascal65 starts with a work disk, and when you choose one in the dialog, it
copies `runtimeN` to the work disk if the work disk doesn't have it. A new version of
Pascal65 with a new runtime puts its own `runtimeN` on your work disk. The old one is
left alone.

## Changing the Work Disk

Press **W** in the file screen (the back arrow key) or in the directory screen (**F1**)
to show the work disk dialog again. First the IDE saves every open file that has a
name. If a file without a name has changes, it asks before throwing them away. Then
it closes every file, since they belong to the old disk.

## Opening Files

The directory screen (**F1**) lists the work disk. Press **D** to list the system disk
instead, and **D** again to go back. The screen's prompt and its file count say which
disk is listed. In single-disk mode, **D** does nothing.

A file opened from the system disk is read-only, so you can look at the examples and
the library sources without changing them. **R** (rename) and **S** (scratch) do
nothing while the system disk is listed.

With a work disk, the status bar shows **Work** or **System** for the current file, and
**R/O** for a read-only file.

To change a file from the system disk, use **Save As** (**A** in the file screen). It
saves the file on the work disk, and the editor then has the work disk's copy, which
you can change. Building a file from the system disk (**F5**, **F7** or **F8**) does
the same first: it saves the file on the work disk under the same name, replacing
any file of that name there, and then builds the copy.

## Where Pascal65 Looks for Files

Your sources, compiled units (`.tpu`), object files, compiled programs and the
compiler's temporary files are on the work disk.

A unit's source (`.pas`), its pre-compiled header (`.hdr`) or compiled unit (`.tpu`),
a library's code (`.lib`) and the default colors (`themes.def`) are looked for on the
work disk first, then on the system disk. A unit of your own on the work disk is used
in place of one of the same name on the system disk. The libraries that come with
Pascal65 are found on the system disk.

Each kind of file is looked for on its own. A library whose `.hdr` is on the system
disk is used from there, even if the work disk has a `.pas` of the same name.

## Syntax Highlighting Colors

Each work disk has its own colors in its own `themes.dat`, which starts as a copy of the
system disk's. **F4** changes the work disk's colors. **F8** in the colors screen reads
the defaults from the system disk's `themes.def`.

## Running Programs

**F5** runs a program from the work disk, so the program finds `runtimeN` there. A
program reads and writes its own files on the disk it was loaded from, which is the
work disk. When the program ends, the IDE comes back with the same work disk and the
same files open.

A program you run yourself, outside the IDE, needs `runtimeN` on the disk it is loaded
from, unless it says `(* $StaticRuntime *)` (see
[Compiler Directives](langref/compiler.md)).

## The Command-Line Compiler

The compiler runs in single-disk mode, unless the source file name starts with a device
number and a colon:

```
Source file (9:name for a work disk on unit 9): 9:hello.pas
```

The device must hold a work disk, and the compiler copies `runtimeN` to it if it is
missing, as the IDE does. If the device can't be used, the compiler prints the same
message as the dialog and stops. A prefix naming the system disk's own device is
single-disk mode.

## Moving Existing Work

Pascal65 doesn't move files from the system disk to a work disk. Copy your files to the
work disk yourself, then make the system disk a fresh copy of the Pascal65 disk.

## Write Protection

With a work disk, Pascal65 never writes to the system disk. Don't write-protect the
system disk yet, though. Pascal65 checks whether a file is on a disk by asking the
drive to rename it, and a write-protected disk answers as if every file were there.
