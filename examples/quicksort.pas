(* Found at https://sandbox.mc.edu/~bennet/cs404/doc/qsort_pas.html *)

Program Sort(input, output);

Const
	(* Max Array Size *)
	MaxElts = 50;

Type
	(* Type of the element array *)
	IntArrType = Array[1..50] Of Integer;

Var
	(* Indexes, exchange temp, array size *)
	i, j, size : Integer;

	(* Array of ints *)
	arr : IntArrType;

(* Use QuickSort to sort the array of integers. *)
Procedure QuickSort(size : Integer; Var arr : IntArrType);

	(* This does the actual work of the QuickSort. It takes the
	   parameters which define the range of the array to work on,
	   and references the array as a global. *)
	Procedure QuickSortRecur(start, stop : Integer);
	Var
		m : Integer;

		(* The location separating the high and low parts. *)
		SplitPt : Integer;

		(* The QuickSort split algorithm. Takes the range, and
		   returns the split point. *)
		Function Split(start, stop : Integer) : Integer;
		Var
			left, right : Integer;		(* Scan pointers. *)
			pivot : Integer;			(* Pivot value *)

			(* Interchange the parameters *)
			Procedure Swap(a, b : Integer);
			Var
				t : Integer;
			Begin
				t := arr[a];
				arr[a] := arr[b];
				arr[b] := t;
			End;
		
		Begin (* Split *)
			(* Set up the pointers for the hight and low sections,
			   and get the pivot value. *)
			pivot := arr[start];
			left := start + 1;
			right := stop;

			(* Look for pairs out of place and swap 'em *)
			While left <= right Do Begin
				While (left <= stop) And (arr[left] < pivot) Do
					left := left + 1;
				While (right > start) And (arr[right] >= pivot) Do
					right := right - 1;
				If Left < right Then
					swap(left, right);
			End;

			(* Put the pivot between the halves. *)
			swap(start, right);

			Split := right;
		End;
	
	Begin (* QuickSortRecur *)
		(* If there's anything to do... *)
		If start < stop Then Begin
			SplitPt := Split(start, stop);
			QuickSortRecur(start, SplitPt-1);
			QuickSortRecur(SplitPt+1, stop);
		End
	End;

Begin (* QuickSort *)
	QuickSortRecur(1, size);
End;

Begin
	arr[1] := 51;
	arr[2] := 26;
	arr[3] := 31;
	arr[4] := 78;
	arr[5] := 65;
	arr[6] := 99;
	arr[7] := 2;
	arr[8] := 16;
	arr[9] := 28;
	arr[10] := 79;

	QuickSort(10, arr);
	For i := 1 To 10 Do Writeln(arr[i]);
End.
