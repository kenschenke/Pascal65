Program TooLarge;

// The compiler must refuse this program. Its runtime stack is so large that
// the program, its heap and its stack don't fit below $C000, so code
// generation reports errCodeSegmentOverflow. compiletests.s compiles it on
// its own, expects exactly that error and doesn't run it.

(* $StackSize 40000 *)

Begin
    Writeln('This program should not compile');
End.
