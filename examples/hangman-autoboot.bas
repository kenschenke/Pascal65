10 poke 53280,0:poke 53281,0
20 print chr$(27);"8";
30 print "{clr}";chr$(14)
40 print "{cyn}                                W E L C O M E"
50 print "{grn}                                     T O"
60 print "{yel}                                H A N G M A N"
100 print "{grn}"
110 print "       Guess the secret word one letter at a time. Press a letter key"
120 print "       to guess it, and every place it appears in the word is filled in."
130 print
140 print "       Each wrong guess adds a part to the hanged man: the head, the body,"
150 print "       two arms and two legs. Six wrong guesses lose the round. Guessing"
160 print "       a letter a second time costs nothing."
170 print
180 print "       After each round, press Y to play again or N to quit. The score"
190 print "       is kept until you quit, and no word comes up twice."
200 print
210 print "       Press 1 at any time to turn the music on or off."
220 print
230 print "       Hangman is written using the {pur}Pascal65{grn} compiler. For more"
240 print "       information about Pascal65 or to see the Pascal source for"
250 print "       Hangman, please see https://github.com/kenschenke/pascal65"
300 print "{wht}"
310 print "                            Press a key to continue"
320 getkey a$
330 print "{wht}";chr$(142)
340 dload"hangman"
