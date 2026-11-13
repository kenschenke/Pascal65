(* Test 32 - Array bounds and element types
NEW IWS b
DIA LBL xxxxx
NEW IWS 14
DIA LBL xxxxx
NEW IWS 9
DIA LBL xxxxx
NEW IWS c
DIA LBL xxxxx
NEW IWS e
DIA LBL xxxxx
NEW IWS e
DIA LBL xxxxx
NEW IWS a
DIA LBL xxxxx
NEW IWS e
DIA LBL xxxxx
NEW IWS c
DIA LBL xxxxx
NEW IWS 132
DIA LBL xxxxx
NEW IWS 106
DIA LBL xxxxx
PSH IWU 0
BRA LBL xxxxx
LOC LBL xxxxx
PSH IWS 12c
PSH VDW 4 1 b
SET IBS 4 IBS 4
PSH IBS 1
PSH VDR b 1 0
PSH CHR b
AIX IBS 9
SET IBS 1 IBS 2
PSH VDR 4 1 b
PSH VDR b 1 1
PSH IBS fe
AIX IBS 2
SET IBS 4 IBS 4
PSH VDR 4 1 b
PSH VDR b 1 3
PSH IWU 1
AIX IBS 13
SET IBS 4 IBS 4
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 65
   high bound: 69
   elem size: 1
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: -3
   high bound: 3
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: -300
   high bound: -298
   elem size: 1
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 0
   high bound: 2
   elem size: 2
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 2
   elem size: 4
   elem type: 4
   elem label: 
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 2
   elem size: 4
   elem type: 4
   elem label: 
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 2
   elem size: 2
   elem type: 3
   elem label: 
   literals: 
   num literals: 0
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 2
   elem size: 4
   elem type: 1
   elem label: 
   literals: 
   num literals: 0
DAT IBU 3 LBL xxxxx
   a
   bc
   d
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 3
   elem size: 2
   elem type: 3
   elem label: 
   literals: xxxxx
   num literals: 3
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 1
   high bound: 300
   elem size: 1
   elem type: 0
   elem label: 
   literals: 
   num literals: 0
DAT IBU 0 LBL xxxxx
   00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 10 11 12 13 
   14 15 16 17 18 19 1a 1b 1c 1d 1e 1f 20 21 22 23 24 25 26 27 
   28 29 2a 2b 2c 2d 2e 2f 30 31 32 33 34 35 36 37 38 39 3a 3b 
   3c 3d 3e 3f 40 41 42 43 44 45 46 47 48 49 4a 4b 4c 4d 4e 4f 
   50 51 52 53 54 55 56 57 58 59 5a 5b 5c 5d 5e 5f 60 61 62 63 
   64 65 66 67 68 69 6a 6b 6c 6d 6e 6f 70 71 72 73 74 75 76 77 
   78 79 7a 7b 7c 7d 7e 7f 80 81 82 83 84 85 86 87 88 89 8a 8b 
   8c 8d 8e 8f 90 91 92 93 94 95 96 97 98 99 9a 9b 9c 9d 9e 9f 
   a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 aa ab ac ad ae af b0 b1 b2 b3 
   b4 b5 b6 b7 b8 b9 ba bb bc bd be bf c0 c1 c2 c3 c4 c5 c6 c7 
   c8 c9 ca cb cc cd ce cf d0 d1 d2 d3 d4 d5 d6 d7 d8 d9 da db 
   dc dd de df e0 e1 e2 e3 e4 e5 e6 e7 e8 e9 ea eb ec ed ee ef 
   f0 f1 f2 f3 f4 f5 f6 f7 f8 f9 fa fb fc fd fe ff 
DAT IBU 5 LBL xxxxx
   heap offset: 0
   low bound: 0
   high bound: 255
   elem size: 1
   elem type: 0
   elem label: 
   literals: xxxxx
   num literals: 256
*)

// Character, negative and enumeration bounds, arrays of files, strings
// and reals with no literals, string literals of one character, an array
// with more than 255 literals and the Length of one with more than 255
// elements.

Program Test;

Type
  Colors = (Red, Green, Blue);

Var
  letters : Array['a'..'e'] Of Byte;
  neg : Array[-3..3] Of Integer;
  wneg : Array[-300..-298] Of Byte;
  byColor : Array[Red..Blue] Of Integer;
  texts : Array[1..2] Of Text;
  files : Array[1..2] Of File Of Integer;
  names : Array[1..2] Of String;
  reals : Array[1..2] Of Real;
  words : Array[1..3] Of String = ('a', 'bc', 'd');
  big : Array[1..300] Of Byte;
  lits : Array[0..255] Of Byte = (
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
    16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
    32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47,
    48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63,
    64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79,
    80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95,
    96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109,
    110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122,
    123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135,
    136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148,
    149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161,
    162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174,
    175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187,
    188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200,
    201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213,
    214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226,
    227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239,
    240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252,
    253, 254, 255);
  i : Integer;

Begin
  i := Length(big);
  letters['b'] := 1;
  neg[-2] := i;
  byColor[Green] := i;
End.
