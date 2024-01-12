# Records

Pascal records are a data type that contains one or more values.  They are like structs in C or classes without methods.

## Syntax

Records are defined in the **Type** section of a program like this:

```
Type
    <Record-Type-Name> = Record
        <Field-1> : <Type-1>;
        <Field-2> : <Type-2>;
        <Field-n> : <Type-n>;
    End;
```

## Anonymous Records

Variables can be declared to be of an anonymous record type, like this:

```
Var
    Student : Record
        Age : Integer;
        Grade : ShortInt;
    End;
```

The disadvantage is that the Student variable cannot be passed to a function or procedure because it is not a named type.

## Nested Records

Record definitions can be nested, even anonymously.

```
Type
    OuterRecord = Record
        Field1 : Integer;
        Field2 : Integer;
        InnerRecord : Record
            InnerField1 : Integer;
            InnerField2 : Integer;
        End;
    End;
```

## Accessing Record Fields

Record fields are accessed using the dot operator, like this:

```
Type
    Student = Record
        Age : Integer;
        Grade : ShortInt;
    End;

Var
    s : Student;

Begin
    s.age := 12;
    s.grade := 6;

    Writeln('Student is in grade ', s.grade);
End;
```

## Record Storage

This section describes how Pascal65 stores records in computer memory.  It is not
necessary to know this information to write Pascal programs.  This is here
primarily for developers writing libraries and for those curious.

Records fields are stored directly in a block of memory with no padding or
packing.  For example, a record defined as follows:

```
Record
    month, day, year : Integer;
End;
```

and declared as:

```
    date.month := 10;
    date.day := 15;
    date.year := 1970;
```

would be stored in memory as:

```
$0a $00 $0f $00 $b2 $07
```

If a record contains an array the array is stored directly within the record's
memory.
