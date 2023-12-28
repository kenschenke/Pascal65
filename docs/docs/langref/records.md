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