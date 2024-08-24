# SFH Instruction

## Synopsis

```
SFH <file number> <input/output flag>
```

## Description

The **SFH** instruction sets the file number to be used by the **INP**
or **OUT** instructions.

### File Number Operand

The file number operand refers to one of the Pascal65 defined file
numbers or an assigned file number. Acceptable values 
are $80 (standard input/output), $81 (the string buffer),
or an assigned file number.

### Input/Output Flag Operand

This flag indicates whether the input or output file handle
is being set. 1 indicates input and 0 indicates output.

## See Also

[INP](/icode/mne/inp), [OUT](/icode/mne/out)
