# Notes

*PlayNote* and *NoteFreq* take a note number from 0 to 95. The number is
the octave times 12 plus the note's place in the octave, which the
library's constants give (*NoteC* is 0, *NoteB* 11).

|Octave|C |C#|D |D#|E |F |F#|G |G#|A |A#|B |
|------|--|--|--|--|--|--|--|--|--|--|--|--|
|0     |0 |1 |2 |3 |4 |5 |6 |7 |8 |9 |10|11|
|1     |12|13|14|15|16|17|18|19|20|21|22|23|
|2     |24|25|26|27|28|29|30|31|32|33|34|35|
|3     |36|37|38|39|40|41|42|43|44|45|46|47|
|4     |48|49|50|51|52|53|54|55|56|57|58|59|
|5     |60|61|62|63|64|65|66|67|68|69|70|71|
|6     |72|73|74|75|76|77|78|79|80|81|82|83|
|7     |84|85|86|87|88|89|90|91|92|93|94|95|

Middle C (C4) is 48 and A4, tuned to 440 Hz, is 57.

## Frequencies

A SID frequency value is the note's frequency in hertz times
16,777,216 divided by the SID's clock. The MEGA65's SIDs run from the
video clock, 985,248 Hz on PAL and 1,022,727 Hz on NTSC, so a note's value
depends on the video mode. *NoteFreq* checks the mode each time it's
called.

|Note|Hz     |PAL  |NTSC |
|----|-------|-----|-----|
|C0  |16.35  |278  |268  |
|C4  |261.63 |4455 |4292 |
|A4  |440.00 |7493 |7218 |
|C7  |2093.00|35640|34334|
|B7  |3951.07|65535|64814|

B7 is above the highest frequency a SID can play on PAL (3,848 Hz), so
*NoteFreq* returns 65,535 for it there, which is a little flat.
