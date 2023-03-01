 Program TestVars(input, output);

 Type
   en = (alpha, beta, gamma);
   sr = alpha..gamma;
   months = 1..12;
 
 Var
   ab : array[1..6] of boolean;
   ac : array[0..10] of char;
   ai : array[-5..5] of integer;
   ar : array[0..3] of real;
   b : boolean;
   c : char;
   i, j, k : integer;
   r, s, t : real;
   e : en;
   ae : array[sr] of integer;
   ae2 : array[1..10] of en;
   birthMonth : months;
 
 Begin
   ab[1] := true;
   ab[6] := false;
   ac[0] := 'c';
   ai[-2] := 12345;
   ar[1] := 3.14159;
   ar[2] := -123.456;
   b := true;
   c := 'k';
   i := 123;
   r := 1.01;
   e := gamma;
   ae[beta] := 123;
   birthMonth := 3;
 End.
