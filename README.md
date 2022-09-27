# wordle-helper
A bash script to help you filter the remaining valid words in Wordle challenges, in English or also in Spanish.

Usage:

./wordle-helper.sh [OPTIONS]

Valid options are:

    -h         : display this help file.

    -sN        : show list of remaining words only if they are no more
                 than N (default value for N is 100).

    -bFILE     : batch mode: use FILE as input. Words in this file
                 can be in separate lines, or separated by spaces.
                 Commented lines (starting with '#') are ignored.
                 See an example input file at the end of this help.

    -e         : use the "Español" word list instead of the English one
                 (for Wordle challenges in Spanish.)

    -wFILE     : use contents of FILE as the starting Word List
                 (i.e. for Wordle challenges in other languages.)

When used without the -b option, this script will interatively
ask you to provide the guesses you made for a Wordle challenge,
as well as the clues you got for each of them. In each step it will
progressively narrow down the set of feasible words that remain.

The clues must be given to the script as a sequence of five characters
using '-' for grey/black, 'g' for green, and 'y' for yellow.
For example, if your first 5-letter word guess is HELLO, and you get
all of these letters in grey/black from the Wordle challenge, the
corresponding clues would be:

    -----

However, if you get let us say Yellow for the 'E' in HELLO, and Green
for the 'O', with grey/black for all other letters, then the
corresponding clues would be:

    -Y--G

The script will process this and then tell you the results, which in
this case already narrows down all possibilities to only 22 valid
remaining words (from almost 13000 !) The list of these 22 words is
shown, and then the script repeats the process asking you again what
your next guess and clues are, to further reduce this set of
remaining words.

If you always want to see the list of words, provide any value greater
than the size of the starting words list, e.g.:

    ./wordle-helper -s13000

If you only want to know how many words are left, but do not want to
see the list of those actual words, use the -s option with zero.

For the batch, non-interactive mode (-b option), an example input file
could be the following:

    # NYT Wordle challenge Sep/26/2022:
    aside
    -YG--
    slick
    Y-G-G
    # From starting with almost 13K words, only 3 words are left after
    # those two guesses: brisk, frisk, and whisk.
    # The Wordle solution this day was brisk.

Visit the following links to Play Wordle in English or Spanish:
- [Wordle (EN)](https://www.nytimes.com/games/wordle/index.html)
- [Wordle (ES)](https://wordle.danielfrg.com/)

Enjoy!
