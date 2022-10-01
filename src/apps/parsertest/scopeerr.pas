PROGRAM scope;

(************************************************)
(*  TO DO                                       *)
(*     Record field assignments                 *)
(************************************************)

CONST
	six = 6;

TYPE
	fruit = (apple, banana, lemon);
	veggie = (carrot, corn, potato);

	person = RECORD
		age : integer;
		gender : char;
		height : integer;
	END;

VAR
	i, z : integer;
	snack : fruit;
	side : veggie;
	man : person;
	name : array[1..11] of char;
	lotto : array[1..10] of integer;
	fruits : array[1..10] of fruit;
	fruitQty : array[apple..lemon] of integer;
	twoDim : array[1..5, 1..10] of integer;

PROCEDURE sayHello(ken, j, k : integer; ch : char);
BEGIN
	writeln('Hello!', j, ken, k)
END;

FUNCTION doubleIt(num : integer) : integer;
BEGIN
	doubleIt := num * 2
END;

BEGIN
	i := 1;
	IF i > 0 THEN BEGIN
		writeln('Greater than 0!');
		writeln('this line too')
	END
	ELSE BEGIN
		writeln('Less than 1!');
		writeln('this line too')
	END;
	writeln('Hello, world!');

	CASE z OF
		1: writeln('one');
		2: writeln('two');
		4, 5, six: writeln('four 5, 6');
	END;

	snack := apple;
	side := corn;

	sayHello(1, 2, 3, 'a');

	man.age := i;
	man.gender := 'm';
	man.height := 100;

	name := 'Ken Schenke';
	name[0] := 'w';

	lotto[9] := 15;

	fruits[0] := apple;

	fruitQty[apple] := 1;
	fruitQty[lemon] := 13;

	twoDim[2][3] := 14;

	i := ord(apple);

	z := i * 5 + doubleIt(i);

	FOR i := 1 TO 10 DO BEGIN
		writeln('for loop!');
		writeln('this line too!')
	END;

	i := doubleIt(i);

	i := 1;
	REPEAT
		i := i + 1;
		writeln('this line!')
	UNTIL i >= 10;

	i := 1;
	WHILE i < 10 DO BEGIN
		i := i + 1;
		writeln('this line too')
	END;

	CASE i OF
		1: writeln('its one');
		2: writeln('its two');
		3: BEGIN
			writeln('it''s three');
			writeln('and more')
		END
	END
END.
