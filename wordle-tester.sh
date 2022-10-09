#!/bin/bash
# Tests that some corner cases for the wordle-helper do work.
# Created after the english wordle #477 from 2022-10-09,
# in which the helper I realized was still not ruling out
# some repeated O's which could be eliminated.
# After the following sequence of guesses and clues:
# aside	---g-
# young	yg---
# moody	-g-gg
# The helper showed 14 remaining words including the following five:
# boody, doody, foody, hoody, and woody.
# But all of these with two O's could be discarded given the last clue,
# so the correct number of remaining words should be 9, or in any case
# (depening on whether the word list changes) no remaining word
# should have an O in the third position.
#
# By Raul Saavedra, 2022-10-09

function failed() {
    echo "Test $1 FAILED"
    exit 1
}

function good() {
    echo "Test $1 succeeded"
}

LASTWORDSET=`./wordle-helper.sh -binput_test_en_01.txt | grep "Actual words" | tail -n 1`
NWC=`echo $LASTWORDSET | wc -w`
LSETSIZE=$(( NWC - 3 ))
HASHOODY=`echo $LASTWORDSET | grep 'hoody'`
if [[ "$LSETSIZE" == "0" || "$HASHOODY" != "" ]]; then
    failed "01"
fi
good "01"

LASTWORDSET=`./wordle-helper.sh -binput_test_en_02.txt | grep "Actual words" | tail -n 1`
MCOUNT=`echo $LASTWORDSET | grep 'oomph' | wc -l`
if [[ "$MCOUNT" != "1" ]]; then
    failed "02"
fi
good "02"

LASTWORDSET=`./wordle-helper.sh -binput_test_es_01.txt | grep "Actual words" | tail -n 1`
MCOUNT=`echo $LASTWORDSET | grep 'droga' | wc -l`
if [[ "$MCOUNT" != "0" ]]; then
    failed "03"
fi
good "03"

LASTWORDSET=`./wordle-helper.sh -s -binput_test_es_01.txt | grep "Actual words" | tail -n 1`
NWC=`echo $LASTWORDSET | wc -w`
LSETSIZE=$(( NWC - 3 ))
MCOUNT=`echo $LASTWORDSET | grep 'droga' | wc -l`
if [[ "$LSETSIZE" != "1" || "$MCOUNT" != "1" ]]; then
    failed "04"
fi
good "04"

exit 0



