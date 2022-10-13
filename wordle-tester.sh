#!/bin/bash
# wordle-tester.sh
# author: Raul Saavedra F. (raul.saavedra@gmail.com)
# date  : 2022-10-09
#
# Usage: run simply with no parameters to test the wordle-helper.sh (bash) script:
#
#   ./wordle-tester.sh
#
# Or run with any parameter to test the python (wordle-helper.py) script:
#   ./wordle-tester.sh 1
#
#
# Tests that some corner cases for the wordle-helper do work.
#
# Created after the english wordle #477 from 2022-10-09,
# in which the helper I realized was still not ruling out
# some repeated O's which could be eliminated.
#
# After the following sequence of guesses and clues:
# aside	---g-
# young	yg---
# moody	-g-gg
#
# The helper showed 14 remaining words including the following five:
# boody, doody, foody, hoody, and woody.
# But all of these with an O in the third position could have been
# discarded given the last clue, and the helper was still keeping them.
# The correct number of remaining words should be 9 (not 14), or in any
# case, depending on whether the word list changes, a word like "hoody"
# cannot be among the remaining ones after those three attempts.


function failed() {
    echo "Test $1 FAILED"
    RESULT="1"
}

function good() {
    echo "Test $1 succeeded"
}

RESULT=""

RUNWH="./wordle-helper.sh"
if [[ "$1" != "" ]]; then
    # any parameter makes this tester test the python instead of bash script
    RUNWH="python3 wordle-helper.py"
fi


# Check corner case found after wordle #477: remaining words from
# input set here cannot contain words like 'hoody', e.g. with an
# 'o' in the third position
LASTWORDSET=`$RUNWH -binput_test_en_01.txt -n500 | grep "Actual words" | tail -n 1`
MATCHCOUNT=`echo $LASTWORDSET | grep 'howdy' | grep -v 'hoody' | wc -l`
if [[ "$MATCHCOUNT" != "1" ]]; then
    failed "01"
else
    good "01"
fi

# Check that letter repetitions with at least one in yellow are detected.
# From the given input file the letter o is detected as repeated
# appearing at least once in yellow. After this test the word 'oomph'
# should remain, but not the word 'vomit'.
LASTWORDSET=`$RUNWH -binput_test_en_02.txt -n500 | grep "Actual words" | tail -n 1`
MATCHCOUNT=`echo $LASTWORDSET | grep 'oomph' | grep -v 'vomit' | wc -l`
if [[ "$MATCHCOUNT" != "1" ]]; then
    failed "02"
else
    good "02"
fi

# Check that using the -s option and an input file for a spanish wordle,
# the solution 'droga' should be among the remaining words
LASTWORDSET=`$RUNWH -s -binput_test_es_01.txt | grep "Actual words" | tail -n 1`
MATCHCOUNT=`echo $LASTWORDSET | grep "droga" | wc -l`
if [[ "$MATCHCOUNT" != "1" ]]; then
    failed "03"
else
    good "03"
fi

# Check that the 'ñ' letter is processed normally when using the -s
# option and an input file for a spanish wordle with only 'señor' as
# guess, and '--yy-' as clues. The word 'acuño' end up among
# remaining words, but not 'apiña', 'añade', or 'pañal'
LASTWORDSET=`$RUNWH -s -binput_test_es_02.txt | grep "Actual words" | tail -n 1`
MATCHCOUNT=`echo $LASTWORDSET | grep "acuño" | grep -v "apiña" | grep -v "añade" | grep -v "pañal" | wc -l`
if [[ "$MATCHCOUNT" != "1" ]]; then
    failed "04"
else
    good "04"
fi

# Check usage of option -w with a given word list and a given test file
LASTWORDSET=`$RUNWH -wtest_wordlist.txt -binput_test_en_03.txt | grep "Actual words" | tail -n 1`
MATCHCOUNT=`echo $LASTWORDSET | grep "zzzzz" | wc -l`
if [[ "$MATCHCOUNT" != "1" ]]; then
    failed "05"
else
    good "05"
fi

# Test case created on 13.10.2022, after the Spanish wordle that day:
# If a letter in green (or yellow) also appears now in black,
# then any word with one or more too many repetitions of that
# letter can already be discarded. Examples:
# Guess 'impio' resulted in ---gg as clues, so any words that has
# the letter i repeated (e.g. tibio) could and should be discarded.
# After that, tried folio, an 'o' was still green but the
# additional 'o' was black. Same thing here then: any words
# with a repeated 'o' (e.g. gofio, obvio) should and could also be
# discarded after these last clues.
# (Final solution was junio)
LASTWORDSET=`$RUNWH -s -binput_test_es_03.txt | grep "Actual words" | tail -n 1`
MATCHCOUNT=`echo $LASTWORDSET | grep -v "litio" | grep -v "obvio" | grep "junio" | wc -l`
if [[ "$MATCHCOUNT" != "1" ]]; then
    failed "06"
else
    good "06"
fi

# Additional test case, to check simple removal of black letters
# After guess/clues aside/y---y, faker/-y-y-, final list cannot
# contain words like zebra (because r was black)
LASTWORDSET=`$RUNWH -binput_test_en_04.txt -n500 | grep "Actual words" | tail -n 1`
MATCHCOUNT=`echo $LASTWORDSET | grep -v "zebra" | grep "equal" | wc -l`
if [[ "$MATCHCOUNT" != "1" ]]; then
    failed "07"
else
    good "07"
fi

exit $RESULT
