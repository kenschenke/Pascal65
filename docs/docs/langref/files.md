# Files

The Pascal language can read write and write to two different kinds of files: data files
and text files. Data files contain one type of Pascal data type, designated when the file
variable is declared.

A Pascal program can have up to nine files opened at a time. The Commodore Kernal limits the
number of open files to ten. Pascal reserves one of those ten for a command and error
channel to the drive.

## Data Files

Data files are declared with the **File** data type like this:

    Var fh : File Of Integer;

In this case, the file contains integers. A data file can contain any declared data type
except strings, but including records and arrays. For strings, use a text file instead.

### Creating and Writing a Data File

To create a data file and write to it, first declare the file variable. Then assign a filename
and open it for writing. Then write data to the file and finally close it. Following is an
example:

```
Program FileDemo;

Var fh : File Of Integer;

Begin
    Assign(fh, 'numbers');  // The filename is "numbers"
    Rewrite(fh);   // Open the file for writing
    Write(fh, 12345);
    Write(fh, -1001);
    Write(fh, 101, 102, -529);
    Close(fh);
End.
```

### Reading a Data File

Reading a data file is very similar to writing it. The program assigns the filename,
opens it, reads from it, and closes it.

```
Program FileDemo;

Var fh : File Of Integer;
    i : Integer;

Begin
    Assign(fh, 'numbers');  // The filename is "numbers"
    Reset(fh);  // Open the file for reading
    While Not Eof(fh) Do Begin
        Read(fh, i);
        Writeln('i is ', i);
    End;
    Close(fh);
End.
```

## Text Files

Text files contain plain text, separated by carriage returns. Programs read from and
write to text files in a similar way as reading from and writing to the console. The
process for opening and closing text files is a lot like data files.

### Creating and Writing a Text File

To create a text file and write to it, first declare the file variable. Then assign a filename
and open it for writing. Then write data to the file and finally close it. Following is an
example:

```
Program FileDemo;

Var fh : Text;

Begin
    Assign(fh, 'textfile.txt');  // The filename is "textfile.txt"
    Rewrite(fh);   // Open the file for writing
    Writeln(fh, 'This is the first line');
    Writeln(fh, 12345:10, -23456);  // Integers are written as strings
    Close(fh);
End.
```

### Reading a Text File

Reading a text file is very similar to writing it. The program assigns the filename,
opens it, reads from it, and closes it.

```
Program FileDemo;

Var fh : File Of Integer;
    i, j : Integer;
    s : String;

Begin
    Assign(fh, 'textfile.txt');  // The filename is "textfile.txt"
    Reset(fh);  // Open the file for reading
    Readln(fh, s);  // Read the entire first line into "s"
    Readln(fh, i, j); // Read numbers from the second line into "i" and "j"
    Close(fh);
End.
```
