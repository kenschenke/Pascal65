(*
    Error Test 11 - expect errMissingIdentifier on line 9
    Two commas in an enumeration
*)

Program Test;

Type
    MyEnum = (one, two, , four);

Begin
    Writeln('hello');
End.
