#!/bin/bash
# SPDX-License-Identifier: MIT

# wordle-helper.sh
# author: Raul Saavedra F. (raul.saavedra@gmail.com)
# date  : 2022-09-26
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
echo "|     By Raul Saavedra F., 2022-Sep-26         |"
echo $BAR
BLACK="-"
GREEN="g"
YELLOW="y"
VALIDCLUES="$BLACK$GREEN$YELLOW"
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
    LTRS_YELLOW="" # Collect here letters in Yellow
    LTRS_YNOREP="" # Same, but with no repetitions
    LTRS_GREEN=""  # Collect here letters in Green
    PATTERN_TO_MATCH=$ANYTHING     # Pattern to match (from Green letters)
    PATTERNS_TO_DISCARD=""         # Patterns to discard (from Yellow or Black letters)
    SPACER=""
    # Process Yellows and Greens first
    for (( i=0; i<$(( WLEN )); i++)); do
        LETTER="${GUESS:$i:1}"
        CLUE="${CLUES:$i:1}"
        if [[ "$CLUE" == "$YELLOW" ]]; then
            # Add this letter in this position to the patterns to discard
            PATTERNS_TO_DISCARD="$PATTERNS_TO_DISCARD$SPACER${ANYTHING:0:i}$LETTER${ANYTHING:i+1}"
            SPACER=" "
            # Update our set of yellow letters from these clues
            LTRS_YELLOW="$LTRS_YELLOW$LETTER"
            # Update our set of yellow letters with no repetitions
            if [[ $LTRS_YNOREP != *"$LETTER"* ]]; then
                # For this attempt only
                LTRS_YNOREP="$LTRS_YNOREP$LETTER"
            fi
            if [[ $LTRS_YNOREP_ALL != *"$LETTER"* ]]; then
                # For all attempts
                LTRS_YNOREP_ALL="$LTRS_YNOREP_ALL$LETTER"
            fi
        elif [[ "$CLUE" == "$GREEN" ]]; then
            # Add this letter in this position to the pattern to match
            PATTERN_TO_MATCH="${PATTERN_TO_MATCH:0:i}$LETTER${PATTERN_TO_MATCH:i+1}"
            # Update our set of green letters from these clues
            LTRS_GREEN="$LTRS_GREEN$LETTER"
            # Update our set of green letters from all clues, with no repetitions
            if [[ $LTRS_GNOREP_ALL != *"$LETTER"* ]]; then
                LTRS_GNOREP_ALL="$LTRS_GNOREP_ALL$LETTER"
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

    # Process blacks
    LTRS_BLACK=""  # Collect here Letters in Black
    LTRS_YG_ALL="$LTRS_YNOREP_ALL$LTRS_GNOREP_ALL"
    #echo "Letters YG_ALL are: $LTRS_YG_ALL"
    REPEATED=""
    for (( i=0; i<$(( WLEN )); i++)); do
        LETTER="${GUESS:$i:1}"
        CLUE="${CLUES:$i:1}"
        if [[ "$CLUE" == "$BLACK" ]]; then
            if [[ $LTRS_YG_ALL == *"$LETTER"* ]]; then
                # Clue was black, but letter has been seen elsewhere as Y or G.
                # Before we just discarded words that matched this letter in this position, e.g.
                #   PATTERNS_TO_DISCARD="$PATTERNS_TO_DISCARD$SPACER${ANYTHING:0:i}$LETTER${ANYTHING:i+1}"
                #   SPACER=" "
                # but we can do a bit more: all words with that letter repeated more than
                # the nr. of times this letter has been found to be green or yellow
                # can also be now discarded. Example: guess='litio', clues='---gg'
                # Then any words with two or more i's can and should already be
                # discarded, regardless of the positions of those i's
                PATTERNS_TO_DISCARD="$PATTERNS_TO_DISCARD$SPACER${ANYTHING:0:i}$LETTER${ANYTHING:i+1}"
                if [[ $REPEATED != *"$LETTER"* ]]; then
                    REPEATED="$REPEATED$LETTER"
                    COUNT=0
                    LEN_YG_ALL=${#LTRS_YG_ALL}
                    REP_PATTERN=".*$LETTER"
                    for (( j=0; j<$LEN_YG_ALL; j++ )); do
                        LETTER2="${LTRS_YG_ALL:$j:1}"
                        if [[ "$LETTER2" == "$LETTER" ]]; then
                            COUNT=$((COUNT + 1))
                            REP_PATTERN="$REP_PATTERN.*$LETTER"
                        fi
                    done
                    REP_PATTERN="$REP_PATTERN.*" # Finish the needed pattern
                    echo -e "\tDetected that letter '$LETTER' appears only $COUNT time(s)."
                    MSG="\tDiscarding words with too many occurrences of '$LETTER' (pattern $REP_PATTERN)"
                    do_filter_down "$MSG" "EXCL" "$REP_PATTERN"
                fi
            else
                # Clue is black and letter has never appeared as yellow or green
                # Append to list of letters that for sure are not in the solution,
                # if not there already
                if [[ $LTRS_BLACK != *"$LETTER"* ]]; then
                    LTRS_BLACK="$LTRS_BLACK$LETTER"
                fi
            fi
        fi
    done

    # Proceed to filter down list of remaining words given the new guess+clues
    if [[ "$LTRS_BLACK" != "" ]]; then
        MSG="\tDiscarding words with any of [$LTRS_BLACK] in any position"
        do_filter_down "$MSG" "EXCL" "[$LTRS_BLACK]"
    fi
    if [[ "$PATTERN_TO_MATCH" != "$ANYTHING" ]]; then
        MSG="\tKeeping only words that match the pattern for greens: $PATTERN_TO_MATCH"
        do_filter_down "$MSG" "MATCH" "$PATTERN_TO_MATCH"
    fi
    for PATTERN in $PATTERNS_TO_DISCARD; do
        MSG="\tDiscarding pattern '$PATTERN'"
        do_filter_down "$MSG" "EXCL" "$PATTERN"
    done
    LEN_YNR=${#LTRS_YNOREP}
    for (( i=0; i<$LEN_YNR; i++)); do
        LETTER="${LTRS_YNOREP:$i:1}"
        if [[ $LTRS_GNOREP_ALL != *"$LETTER"* ]]; then
            MSG="\tKeeping only words with '$LETTER' somewhere"
            do_filter_down "$MSG" "MATCH" "$LETTER"
        fi
    done

    # If there is a yellow letter repeated, or a yellow letters which also
    # appears in green, then count how many times this letter appears, in order
    # to keep only words with at least that many occurences of this letter
    LTRS_YG="$LTRS_YELLOW$LTRS_GREEN"
    LEN_YG=${#LTRS_YG}
    REPEATED="" # Collect here letters that we find repeated in LTRS_YG
    for (( i=0; i<$LEN_YG; i++)); do
        LETTER="${LTRS_YG:$i:1}"
        if [[ $REPEATED != *"$LETTER"* ]]; then
            # Not marked as repeated yet, so check if it is repeated
            COUNT=1
            REP_PATTERN=".*$LETTER"
            for (( ((j=i+1)); j<$LEN_YG; j++ )); do
                LETTER2="${LTRS_YG:$j:1}"
                if [[ "$LETTER2" == "$LETTER" ]]; then
                    # It is repeated, count the repetitions
                    COUNT=$((COUNT + 1))
                    # Update the needed pattern
                    REP_PATTERN="$REP_PATTERN.*$LETTER"
                fi
            done
            if (( COUNT > 1 )); then
                REPEATED="$REPEATED$LETTER"  # Track the letter as repeated
                REP_PATTERN="$REP_PATTERN.*" # Finish the needed pattern
                echo -e "\tRepetition detected for '$LETTER', appearing $COUNT times."
                MSG="\tKeeping only words with that repetition (pattern $REP_PATTERN)"
                do_filter_down "$MSG" "MATCH" "$REP_PATTERN"
            fi
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
