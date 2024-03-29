# wordle-helper
Bash and python twin scripts to help you filter the remaining valid words in
Wordle challenges, both in English or Spanish. Both scripts behave identically:
have the same options, expect same inputs, and produce same outputs. The python
script is just quite a bit faster.

Usage:

Bash script:

    ./wordle-helper.sh [OPTIONS]

Python script:

    python3 wordle-helper.py [OPTIONS]

Valid options are:

    -h         : display this help file.

    -s         : use the Spanish word list instead of the English one
                 (for Wordle challenges in Spanish.)

    -nN        : show list of remaining words only if they are no more
                 than N (default value for N is 100).

    -bFILE     : batch mode: use FILE as input. See an example input file
                 near the end of this help.

    -wFILE     : use contents of FILE as the starting Word List
                 (i.e. for Wordle challenges in other languages.)

When used without the -b option, this script will interactively ask you to
provide the guesses you made for a Wordle challenge, as well as the clues
you got for each of them. In each step it will progressively narrow down
the set of words that remain valid.

The clues must be given to the script as a sequence of five characters
using '-' for grey/black, 'g' for green, and 'y' for yellow. For example,
if your first 5-letter word guess is HELLO, and you get all of these
letters in grey/black from the Wordle challenge, the corresponding clues
would be:

    -----

However, if you get let us say Yellow for the 'E' in HELLO, and Green
for the 'O', with grey/black for all other letters, then the
corresponding clues would be:

    -Y--G

The script will then process this information and tell you the results,
which in this case already narrow down all possibilities to only 22 valid
remaining words (from almost 13000 !) The list of these 22 words is shown,
and then the script repeats the process asking you again what your next
guess and clues are, to further reduce this set of possibilities.

The sources of the starting five-letter word lists are the following,
but likely they will get updated here and/or there over time:
- [English (12972 words)](https://github.com/coolbutuseless/wordle/blob/main/R/words.R)
- [Spanish (10835 words)](https://www.listasdepalabras.es/palabras5letras.htm)

If you always want to see the list of remaining words, use the -n option 
with a large enough value, e.g.:

    ./wordle-helper.sh -n13000

If you only want to know how many words are left, but you do not want to
see the actual words, use the -n option with zero.

For the non-interactive/batch mode (-b option), words in the input
file can be in separate lines, or separated by spaces. Commented
lines (starting with '#') are ignored. An example input file could be
the following:

    # NYT Wordle challenge Sep/26/2022:
    aside
    -YG--
    slick
    Y-G-G
    # From starting with almost 13K words, only 3 words are left after
    # those two guesses: brisk, frisk, and whisk.
    # The Wordle solution this day was brisk.

To Play Wordle in English or Spanish:
- [Wordle (EN)](https://www.nytimes.com/games/wordle/index.html)
- [Wordle (ES)](https://wordle.danielfrg.com/)

Enjoy!
