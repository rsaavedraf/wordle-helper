#!/bin/bash
# SPDX-License-Identifier: MIT

# wordle-helper.sh
# author: Raul Saavedra F. (raul.saavedra@gmail.com)
# Created : 2022-09-26
# Last version: 2025-09-17 (Modifications to make it match
# the logic and the output of the python script)
#
# This script progressively filters out all words that are
# no longer valid for a Wordle challenge, given your guesses
# and clues so far (green, yellow, or black) that you've
# received for each guess.
#
# This exercises the usage of some grep filtering,
# regular expressions, and bash programming.
#

BAR="================================================"
echo $BAR
echo "|     wordle-helper.sh                         |"
echo "|     By Raul Saavedra F., 2025-Sep-20         |"
echo $BAR
VALIDCLUES="gy-"
SHOWMAXN=100
BINPUTS=""
WLFILE=""
WORDSET=""
NWORDS=0
WLEN=5
ANYTHING="....."
BATCHMODE=false
ABC="abcdefghijklmnopqrstuvwxyz"

function rebuild_anything() {
    ANYTHING=""
    for (( i=0; i<$(( WLEN )); i++ )); do
        ANYTHING="$ANYTHING."
    done
}

# This function completes the ABC adding any additional letters
# (e.g. ñ for Spanish) that might appear in the word list to use
function do_Complete_ABC() {
    for W in $WORDSET; do
        for (( i=0; i<$(( WLEN )); i++ )); do
            LETTER="${W:$i:1}"
            if [[ $ABC == *"$LETTER"* ]]; then
                continue
            fi
            # This letter is not in the ABC, append it
            ABC="$ABC$LETTER"
        done
    done
    ABC=`echo "$ABC" | grep -o . | tr -d '[:space:]'`
}

# This function returns the 1st invalid letter found in a word
# If no invalid letter is found, returns ""
# Parameter $1 is the word to check
# Parameter $2 is the set of valid letters
function get_Invalid() {
    local i
    local W=$1
    for (( i=0; i<$(( WLEN )); i++ )); do
        local LETTER="${W:$i:1}"
        if [[ "$2" != *"$LETTER"* ]]; then
            # Not a valid letter
            echo $LETTER
            exit
        fi
    done
    echo ""
}

function do_filter_down() {
    VMSG=$1
    VMODE=$2
    VPATTERN=$3
    echo -e "$VMSG"
    if [[ "$VMODE" == "MATCH" ]]; then
        WORDSET=`echo -e "$WORDSET" | grep "$VPATTERN"`
    else
        WORDSET=`echo -e "$WORDSET" | grep -v "$VPATTERN"`
    fi
    NWORDS=`echo $WORDSET | wc -w`
    echo -e "\tWords remaining: $NWORDS"
}

# Process parameters/options, if any
for OPTION in "$@"; do
    case $OPTION in
        -h)  cat wordle-helper-help.txt
             exit 0
             ;;
        -s)  echo "Using the default wordlist for SPANISH"
             WLFILE="words_len5_es.txt"
             ;;
        -b*) INFILE="${OPTION:2}"
             if [[ -f $INFILE ]]; then
                 # Get contents of the file removing comments
                 CONTENTS=`cat $INFILE | grep -v "^#.*"`
                 # Create array of words in CONTENTS
                 BINPUTS=( $CONTENTS )
                 echo "Using contents of '$INFILE' as input file in batch mode:"
                 echo $CONTENTS
                 BATCHMODE=true
             else
                 echo "ERROR: File '$INFILE' not found, exiting."
                 exit -1
             fi
             ;;
        -n*) N="${OPTION:2}"
             NUMREGEX="^[0-9]+$"
             if ! [[ $N =~ $NUMREGEX ]]; then
                echo "Invalid max parameter: $N is not >= zero"
             else
                SHOWMAXN=$N
             fi
             echo "Using $SHOWMAXN as maximum number of words to display"
             ;;
        -l*) VWLEN="${OPTION:2}"
             NUMREGEX="^[1-9]+$"
             if ! [[ $VWLEN =~ $NUMREGEX ]]; then
                echo "Invalid parameter for -l: '$VWLEN'"
             else
                WLEN=$VWLEN
                rebuild_anything
             fi
             echo "Using $WLEN as word-length"
             ;;
        -w*) WLF="${OPTION:2}"
             if [[ -f $WLF ]]; then
                 WLFILE=$WLF
                 echo "Using '$WLFILE' as word list"
             else
                 echo "ERROR: Word list file '$WLF' not found, exiting"
                 exit -2
             fi
             ;;
        *)   echo "ERROR: $OPTION is not an option, use -h for usage details"
             exit -3
             ;;
    esac
done

if [[ "$WLFILE" == "" ]]; then
    # Use the default english word list
    WLFILE="words_len5_en.txt"
fi

# Read word list ignoring comments, making all words lowercase,
# keeping only words with WLEN letters, and sorting using US locale
# (to match default for python script)
echo "Loading word list..."
WORDSET=`cat $WLFILE | grep -v "#" | tr '[:upper:]' '[:lower:]' | tr ' ' '\n'`
WLMATCH="^$ANYTHING$"
WORDSET=`echo -e "$WORDSET" | grep "$WLMATCH" | env LC_ALL=en_US sort`
# Build ABC from the WORDSET
NWORDS=`echo $WORDSET | wc -w`
echo "Size of starting word list: $NWORDS"
do_Complete_ABC
echo "ABC has a total of ${#ABC} letters: $ABC"

WORD=""
GUESS=""
CLUES=""
BINPUTIDX=0
ATTEMPT=0
GET_GUESS=true
LTRS_GNOREP_ALL="" # Letters in Green from all clues, with no repetitions
LTRS_YNOREP_ALL="" # Letters in Yellow from all clues, with no repetitions

while true; do
    # Get input WORD
    if $BATCHMODE; then
        # get next word from the inputs array
        WORD=${BINPUTS[$BINPUTIDX]}
        BINPUTIDX=$(( BINPUTIDX + 1 ))
    else
        # Ask user for next input
        if $GET_GUESS; then
            echo -e "\n===== Please enter your $WLEN-letter wordle guess, or Enter to leave:"
        else
            # Ask for the corresponding clues
            echo "===== Please enter the resulting clues (e.g. -YG--), or Enter to leave:"
        fi
        read WORD
    fi
    # Trim whitespace from WORD, and make it lowercase
    WORD=`echo "$WORD" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]'`

    # If WORD is empty, exit normally
    if [[ "$WORD" == "" ]]; then
        echo "No more inputs, see you next time."
        exit 0
    fi

    # Validate that word has 5 characters
    if (( "${#WORD}" != "$WLEN" )); then
        echo "ERROR: Input '$WORD' is not $WLEN characters long."
        if $BATCHMODE; then
            exit -4
        fi
        continue
    fi
    if $GET_GUESS; then
        # Validate letters in the guess word
        INVALID=`get_Invalid "$WORD" "$ABC"`
        if [ "$INVALID" != "" ]; then
            echo "ERROR: invalid letter '$INVALID' in '$WORD'."
            if $BATCHMODE; then
                exit -5
            fi
            continue
        fi
        # WORD has the current GUESS, and it's valid
        GUESS=$WORD
        # Ask now for the associated clues
        GET_GUESS=false
        continue;
    fi

    # Validate clues
    INVALID=`get_Invalid "$WORD" "$VALIDCLUES"`
    if [ "$INVALID" != "" ]; then
        echo "ERROR: invalid character '$INVALID' in '$WORD'."
        if $BATCHMODE; then
            exit -6
        fi
        continue
    fi

    # If we are here, WORD has now the CLUES for GUESS,
    # and both Guess and Clues have been validated
    CLUES=$WORD

    # Building filtering patterns given the clues for this guess
    PATTERN_TO_MATCH=$ANYTHING   # Pattern to match (from Green letters)
    PATTERNS_TO_DISCARD=""       # Patterns to discard
    PATTERNS_TO_KEEP=""          # Patterns to keep
    GOODSET=""
    TOOMANY=""
    SPACER=" "
    declare -A LCOUNTERS         # <-- An associative array in bash
    for (( i=0; i<$(( WLEN )); i++)); do
        LCOUNTERS["${GUESS:$i:1}"]=0
    done

    # Pass 1: Process g clues (perfect matches)
    for (( i=0; i<$(( WLEN )); i++)); do
        CLUE="${CLUES:$i:1}"
        if [[ "$CLUE" != "g" ]]; then
            continue
        fi
        LETTER="${GUESS:$i:1}"
        echo "G${LETTER}${i}  :  Keep only words that contain '$LETTER' in slot $i"
        PATTERN_TO_MATCH="${PATTERN_TO_MATCH:0:i}$LETTER${PATTERN_TO_MATCH:i+1}"
        if [[ $GOODSET != *"$LETTER"* ]]; then
            GOODSET="$GOODSET$LETTER"
        fi
        LCOUNTERS["$LETTER"]=$(( LCOUNTERS[$LETTER] + 1 ))
    done

    # Pass 2: Process y clues
    for (( i=0; i<$(( WLEN )); i++)); do
        CLUE="${CLUES:$i:1}"
        if [[ "$CLUE" != "y" ]]; then
            continue
        fi
        LETTER="${GUESS:$i:1}"
        LCOUNTERS[$LETTER]=$(( LCOUNTERS[$LETTER] + 1 ))
        if [[ $GOODSET == *"$LETTER"* ]]; then
            LC=$(( LCOUNTERS[$LETTER] ))
            echo "YR${LETTER}${i}${LC}:  Discard words with '$LETTER' in slot $i, and Keep only words that contain at least ${LC} '$LETTER's (Reps detected from y clue!)"
        else
            LC=1
            GOODSET="$GOODSET$LETTER"
            echo "Y${LETTER}${i}  :  Discard words with '$LETTER' in slot $i, and Keep only words that have '$LETTER' somewhere else."
        fi
        PATTERNS_TO_DISCARD="$PATTERNS_TO_DISCARD$SPACER${ANYTHING:0:i}$LETTER${ANYTHING:i+1}"
        CHUNK=".*$LETTER"
        PATTERN="$CHUNK"
        for (( k=1; k<$(( LC )); k++)); do
            PATTERN="$PATTERN$CHUNK"
        done
        PATTERNS_TO_KEEP="$PATTERNS_TO_KEEP$SPACER$PATTERN.*"
    done

    # Pass 3: Process - clues
    for (( i=0; i<$(( WLEN )); i++)); do
        CLUE="${CLUES:$i:1}"
        if [[ "$CLUE" != "-" ]]; then
            continue
        fi
        LETTER="${GUESS:$i:1}"
        LCOUNTERS[$LETTER]=$(( LCOUNTERS[$LETTER] + 1 ))
        if [[ $GOODSET == *"$LETTER"* ]]; then
            # this letter had a g or y clue somewhere else
            if [[ $TOOMANY != *"$LETTER"* ]]; then
                LC=$(( LCOUNTERS[$LETTER] ))
                # First time we see it with the - clue from this guess
                echo "-R${LETTER}${LC} :  Discard words with '$LETTER' in slot $i, and also excessive Reps of '$LETTER' (${LC}x is one too many)"
                PATTERNS_TO_DISCARD="$PATTERNS_TO_DISCARD$SPACER${ANYTHING:0:i}$LETTER${ANYTHING:i+1}"
                CHUNK=".*$LETTER"
                PATTERN="$CHUNK"
                for (( k=1; k<$(( LC )); k++)); do
                    PATTERN="$PATTERN$CHUNK"
                done
                PATTERNS_TO_DISCARD="$PATTERNS_TO_DISCARD$SPACER$PATTERN.*"
            fi
        else
            # letter is not at all in the solution
            if (( LCOUNTERS[$LETTER] == 1 )); then
                # First time we see this letter in the guess, so do filter it out
                echo "-$LETTER*  :  Discard any words that contain '$LETTER' anywhere."
                PATTERNS_TO_DISCARD="$PATTERNS_TO_DISCARD$SPACER.*$LETTER.*"
            fi
        fi
    done

    # Details of current guess and corresponding clues
    ATTEMPT=$(( ATTEMPT + 1 ))
    echo -e "\n\tAttempt: $ATTEMPT"
    echo -e "\tGuess  : $GUESS"
    echo -e "\tClues  : $CLUES"
    FOUND=`echo -e $WORDSET | grep "$GUESS"`
    if [[ "$FOUND" == "" ]]; then
        echo "Warning: word '$GUESS' was not found among remaining words."
        echo "(It might contain letter/position guesses already discarded.)"
    fi
    NWORDS=`echo $WORDSET | wc -w`
    echo -e "\tWords remaining: $NWORDS"

    # Filter further down list of remaining words given the new guess and clues
    if [[ "$PATTERN_TO_MATCH" != "$ANYTHING" ]]; then
        MSG="\tKeeping only words matching: $PATTERN_TO_MATCH"
        do_filter_down "$MSG" "MATCH" "$PATTERN_TO_MATCH"
    fi
    for PATTERN in $PATTERNS_TO_DISCARD; do
        MSG="\tDiscarding words matching:   '$PATTERN'"
        do_filter_down "$MSG" "EXCL" "$PATTERN"
    done
    for PATTERN in $PATTERNS_TO_KEEP; do
        MSG="\tKeeping words matching:      '$PATTERN'"
        do_filter_down "$MSG" "MATCH" "$PATTERN"
    done

    LEN_YNR=${#LTRS_YNOREP}
    for (( i=0; i<$LEN_YNR; i++)); do
        LETTER="${LTRS_YNOREP:$i:1}"
        if [[ $LTRS_GNOREP_ALL != *"$LETTER"* ]]; then
            MSG="\tKeeping only words with '$LETTER' somewhere"
            do_filter_down "$MSG" "MATCH" "$LETTER"
        fi
    done

    if (( NWORDS <= SHOWMAXN )); then
        # Show the remaining set of possible solutions
        echo -n "Actual words remaining: "
        echo $WORDSET
    fi
    if (( NWORDS == 1 )); then
        echo -e "$BAR\nCongratulations, a single word was reached!!! :)"
        echo -e "See you next time.\n$BAR"
        exit 0
    fi
    if (( NWORDS == 0 )); then
        echo "We ran out of words, no further filtering is possible."
        echo "The starting word list might need additional entries."
        echo "Double-check your provided input just in case of typos."
        echo "Bye for now."
        exit 0
    fi

    GET_GUESS=true # Ask for the next guess

done
