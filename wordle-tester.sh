#!/bin/bash
# Tests that some corner cases for the wordle-helper do work.
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
#
# By Raul Saavedra, 2022-10-09

function failed() {
    echo "Test $1 FAILED"
    exit 1
}

function good() {
    echo "Test $1 succeeded"
}

# Check corner case found after wordle #477: remaining words from
# input set here cannot contain words like hoody, e.g. with an O in
# third position
LASTWORDSET=`./wordle-helper.sh -binput_test_en_01.txt | grep "Actual words" | tail -n 1`
NWC=`echo $LASTWORDSET | wc -w`
LSETSIZE=$(( NWC - 3 ))
HASHOODY=`echo $LASTWORDSET | grep 'hoody'`
if [[ "$LSETSIZE" == "0" || "$HASHOODY" != "" ]]; then
    failed "01"
fi
good "01"

# Check that it reaches a set of remaining words with oomph in it
LASTWORDSET=`./wordle-helper.sh -binput_test_en_02.txt | grep "Actual words" | tail -n 1`
MCOUNT=`echo $LASTWORDSET | grep 'oomph' | wc -l`
if [[ "$MCOUNT" != "1" ]]; then
    failed "02"
fi
good "02"

# Check that using this input file which is for spanish, but not using the -s option,
# so using the default English word list, the actual solution (word 'droga') will
# not be among the remaining words
LASTWORDSET=`./wordle-helper.sh -binput_test_es_01.txt | grep "Actual words" | tail -n 1`
MCOUNT=`echo $LASTWORDSET | grep 'droga' | wc -l`
if [[ "$MCOUNT" != "0" ]]; then
    failed "03"
fi
good "03"

# Similar to the previous test but now using the -s option, so the last word set
# should have only one word: 'droga'
LASTWORDSET=`./wordle-helper.sh -s -binput_test_es_01.txt | grep "Actual words" | tail -n 1`
NWC=`echo $LASTWORDSET | wc -w`
LSETSIZE=$(( NWC - 3 ))
MCOUNT=`echo $LASTWORDSET | grep 'droga' | wc -l`
if [[ "$LSETSIZE" != "1" || "$MCOUNT" != "1" ]]; then
    failed "04"
fi
good "04"

exit 0
