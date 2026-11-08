Program RtDynCmp;

// rtdyna and rtdynb are the same program, except that rtdyna asks for the
// dynamic runtime with the directive and rtdynb gets it by default. They
// are compiled but not run, and the test target checks their PRGs are the
// same. rtdynb is also run with a missing, a bad and a small runtime1 by
// loadertest.sh.

Var
    i : Integer;

Begin
    For i := 1 To 3 Do Writeln('rtdyn ', i);
End.
