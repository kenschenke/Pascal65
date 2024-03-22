# CompareStr

Compares two strings.

## Declaration

    Function CompareStr(str1, str2 : String) : ShortInt;

## Description

*CompareStr* compares two strings and returns an integer indicating their sort order.

|Return Value|Meaning                                                      |
|------------|-------------------------------------------------------------|
|0           |The strings are equal                                        |
|> 0         |The first string falls after the second string in sort order |
|< 0         |The first string falls before the second string in sort order|

## Example ##

```
Program example;

Procedure DoCompare(s1, s2 : String);
Var i : ShortInt;
Begin
    i := CompareStr(s1, s2);
    If i < 0 Then Writeln(s1, ' comes before ', s2);
    If i > 0 Then Writeln(s1, ' comes after ', s2);
    If i = 0 Then Writeln(s1, ' equals ', s2);
End;

Begin
    DoCompare('Hello', 'World');
End.
```
