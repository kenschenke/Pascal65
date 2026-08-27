(* Test1.pas - test all tokens and literals *)

Program HelloWorld ;

123 12345 123456 -123
$1a $1abc $1abcd
%10101101 %1010111010010001 %10111101100111001110001110011111
'a' 'Hello, World' 'How''s it going?'
#65 #$42

(* Multi
line
comment
*)

Begin End // single line comment If
Boolean Byte Cardinal Char Integer LongInt Real String ShortInt Word
False True ^*()-+=[]:;><,./:=<=>=<>..!&>><<@
And Array Begin Case Const Div Do DownTo Else End File For Function Goto
If Implementation In Interface Label Mod Nil Not Of Or Xor Packed
Procedure Program Record Repeat Set Text Then To Type Unit Until Uses
Var While With
123.456 .789 -.123 -123.456
1.234e+06 2.345E-07 3.456e+123
123.456e+123+456 123.45+678
Begins
(* $StackSize 1024 *);
If (* Then Embedded Comment *) Else

