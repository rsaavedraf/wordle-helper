#!/bin/bash
# wordle-tester.sh
# author: Raul Saavedra F. (raul.saavedra@gmail.com)
# date  : 2022-10-09
#
# Usage:
#   ./wordle-tester.sh
#
# Tests identified corner cases for the wordle-helper.
# It now runs both the bash and python scripts for each test,
# also making sure their outputs match.
#


RESULT=""

RUNWH_SH="./wordle-helper.sh"
RUNWH_PY="python3 wordle-helper.py"
OUTPUT=""
OUTPUT_SH=""
OUTPUT_PY=""

function check_test() {
    TESTNUM=$1
    MATCHCOUNT=$2
    STYPE=$3
    if [[ "$MATCHCOUNT" != "1" ]]; then
        echo "Test $TESTNUM: $STYPE script FAILED"
        RESULT="1"
    else
        echo "Test $TESTNUM: $STYPE script succeeded"
    fi
    if [[ "$STYPE" == "sh" ]]; then
        OUTPUT_SH=`echo -e "$OUTPUT" | grep -v "|"`
    else
        OUTPUT_PY=`echo -e "$OUTPUT" | grep -v "|"`
    fi
}

# Created after the english wordle #477 from 2022-10-09,
# in which the helper I realized was still not ruling out
# some repeated O's which could be eliminated.
#
# After the following sequence of guesses and clues:
#   aside	---g-
#   young	yg---
#   moody	-g-gg
#
# The helper originally showed 14 remaining words including
# the following five: boody, doody, foody, hoody, and woody.
# But none of these (i.e. with an O in the third position)
# should be among the remaining words
function test1() {
    OUTPUT=`$1 -binput_test_en_01.txt -n500`
    LASTWORDSET=`echo -e "$OUTPUT" | grep "Actual words" | tail -n 1`
    MATCHCOUNT=`echo $LASTWORDSET | grep 'howdy' | grep -v 'hoody' | wc -l`
    check_test "1" $MATCHCOUNT $2
}

# Check that letter repetitions with at least one in yellow are detected.
# From the given input file the letter o is detected as repeated
# appearing at least once in yellow. After this test the word 'oomph'
# should remain, but not the word 'vomit'.
function test2() {
    OUTPUT=`$1 -binput_test_en_02.txt -n500`
    LASTWORDSET=`echo -e "$OUTPUT" | grep "Actual words" | tail -n 1`
    MATCHCOUNT=`echo $LASTWORDSET | grep 'oomph' | grep -v 'vomit' | wc -l`
    check_test "2" $MATCHCOUNT $2
}

# Check that using the -s option and an input file for a spanish wordle,
# the solution 'droga' should be among the remaining words
function test3() {
    OUTPUT=`$1 -s -binput_test_es_01.txt`
    LASTWORDSET=`echo -e "$OUTPUT" | grep "Actual words" | tail -n 1`
    MATCHCOUNT=`echo $LASTWORDSET | grep "droga" | wc -l`
    check_test "3" $MATCHCOUNT $2
}

# Check that the 'ñ' letter is processed normally when using the -s
# option and an input file for a spanish wordle with only 'señor' as
# guess, and '--yy-' as clues. The word 'acuño' end up among
# remaining words, but not 'apiña', 'añade', or 'pañal'
function test4() {
    OUTPUT=`$1 -s -binput_test_es_02.txt`
    LASTWORDSET=`echo -e "$OUTPUT" | grep "Actual words" | tail -n 1`
    MATCHCOUNT=`echo $LASTWORDSET | grep "acuño" | grep -v "apiña" | grep -v "añade" | grep -v "pañal" | wc -l`
    check_test "4" $MATCHCOUNT $2
}

# Check usage of option -w with a given word list and a given test file
function test5() {
    OUTPUT=`$1 -wtest_wordlist.txt -binput_test_en_03.txt`
    LASTWORDSET=`echo -e "$OUTPUT" | grep "Actual words" | tail -n 1`
    MATCHCOUNT=`echo $LASTWORDSET | grep "zzzzz" | wc -l`
    check_test "5" $MATCHCOUNT $2
}

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
function test6() {
    OUTPUT=`$1 -s -binput_test_es_03.txt`
    LASTWORDSET=`echo -e "$OUTPUT" | grep "Actual words" | tail -n 1`
    MATCHCOUNT=`echo $LASTWORDSET | grep -v "litio" | grep -v "obvio" | grep "junio" | wc -l`
    check_test "6" $MATCHCOUNT $2
}

# Additional test case, to check simple removal of black letters
# After guess/clues aside/y---y, faker/-y-y-, final list cannot
# contain words like zebra (because r was black)
function test7() {
    OUTPUT=`$1 -binput_test_en_04.txt -n500`
    LASTWORDSET=`echo -e "$OUTPUT" | grep "Actual words" | tail -n 1`
    MATCHCOUNT=`echo $LASTWORDSET | grep -v "zebra" | grep "equal" | wc -l`
    check_test "7" $MATCHCOUNT $2
}

# Testing usage of the script for word lengths different from 5
# (options -w and the new one: -l)
function test8() {
    OUTPUT=`$1 -binput_test_en_05.txt -wwords_len7_en.txt -l7`
    LASTWORDSET=`echo -e "$OUTPUT" | grep "Actual words" | tail -n 1`
    MATCHCOUNT=`echo $LASTWORDSET | grep "illegal" | wc -l`
    check_test "8" $MATCHCOUNT $2
}


# Do all tests for both scripts
echo "Testing wordle-helper scripts (.sh and .py):"
for (( i=1; i<=8; i++)); do
    TEST="test$i"
    OUTPUT_SH=""
    OUTPUT_PY=""
    $TEST "$RUNWH_SH" "sh"
    $TEST "$RUNWH_PY" "py"
    # And check if there was any difference between the bash and python script outputs
    VDIFF=`diff <(echo -e "$OUTPUT_SH") <(echo -e "$OUTPUT_PY")`
    if [[ "$VDIFF" != "" ]]; then
        echo -e "Warning: output differences detected between .sh/.py scripts for $TEST:\n#$VDIFF\n"
    else
        echo "Their outputs match"
    fi
done

exit $RESULT
