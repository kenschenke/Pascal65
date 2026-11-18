# EOM Instruction

## Synopsis

```
EOM <features>
```

## Description

The **EOM** instruction ends the module. It is the last instruction in
the file, after the data segments ([DAT](../dat)), and it generates no
code.

### Features Operand

The operand is an unsigned byte with a bit for each optional part of the
runtime the module needs: dynamic arrays (1), files (2) and trig (4). A
static program links only those parts. The features are known only once
the module's code is written, so they come at the end of the file rather
than in its header (see [Intermediate Code](../../intro)).
