#!/bin/bash
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
ANYTHING="....."
BLACK="-"
GREEN="g"
YELLOW="y"
VALIDCLUES="$BLACK$GREEN$YELLOW"
SHOWMAXN=100
INPUTS=""
WLFILE=""
WORDSET=""
NWORDS=0
BATCHMODE=false
ABC="abcdefghijklmnopqrstuvwxyz"

function do_Word_Count () {
    NWORDS=`echo $WORDSET | wc -w`
    if [[ "$1" == "" ]]; then
        echo -e "\tWords remaining: $NWORDS"
    else
        echo "Size of starting word list: $NWORDS"
    fi
}

# This function completes the ABC adding any additional letters
# (e.g. ñ for Spanish) that might appear in the word list to use
function do_Complete_ABC() {
    for W in $WORDSET; do
        for (( i=0; i<5; i++ )); do
            LETTER="${W:$i:1}"
            if [[ $ABC == *"$LETTER"* ]]; then
                continue
            fi
            # This letter is not in the ABC, append it
            ABC="$ABC$LETTER"
        done
    done
    # sort letters in ABC
    ABC=`echo "$ABC" | grep -o . | sort | tr -d '[:space:]'`
}

# This function returns the 1st invalid letter found in a word
# If no invalid letter is found, returns ""
# Parameter $1 is the word to check
# Parameter $2 is the set of valid letters
function get_Invalid() {
    local i
    local W=$1
    for (( i=0; i<5; i++ )); do
        local LETTER="${W:$i:1}"
        if [[ "$2" != *"$LETTER"* ]]; then
            # Not a valid letter
            echo $LETTER
            exit
        fi
    done
    echo ""
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
                 INPUTS=( $CONTENTS )
                 echo "Using contents of '$INFILE' as input file in batch mode:"
                 echo $CONTENTS
                 BATCHMODE=true
             else
                 echo "ERROR: File '$INFILE' not found, exiting."
                 exit -1
                 BATCHMODE=false
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
        -w*) WLF="${OPTION:2}"
             if [[ -f $WLF ]]; then
                 WLFILE=$WLF
                 echo "Using '$WLFILE' as word list."
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

# Read word list ignoring comments, keeping only 5 letter words,
# and making all words lowercase
echo "Loading word list..."
WORDSET=`cat $WLFILE | grep -v "#" | grep "^.....$" | tr '[:upper:]' '[:lower:]'`
# Build ABC from the WORDSET
do_Word_Count "start"
do_Complete_ABC
echo "ABC has a total of ${#ABC} letters: $ABC"

WORD=""
GUESS=""
CLUES=""
LOOP=0
ATTEMPT=0
GET_GUESS=true
LTRS_GNOREP_ALL="" # Letters in Green from all clues, with no repetitions
LTRS_YNOREP_ALL="" # Letters in Yellow from all clues, with no repetitions

while true; do
    # Get input WORD
    if $BATCHMODE; then
        # get next word from the inputs array
        WORD=${INPUTS[$LOOP]}
        LOOP=$(( LOOP + 1 ))
    else
        # Ask user for next input
        if $GET_GUESS; then
            echo -e "\n===== Please enter your 5-letter wordle guess, or Enter to leave:"
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
    if (( ${#WORD} != 5 )); then
        echo "ERROR: Input '$WORD' is not five characters long."
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
    LTRS_YNOREP=""
    LTRS_GREEN=""  # Collect here letters in Green
    PATTERN_TO_MATCH=$ANYTHING     # Pattern to match (from Green letters)
    PATTERNS_TO_DISCARD=""         # Patterns to discard (from Yellow letters)
    SPACER=""
    # Process Yellows and Greens first
    for (( i=0; i<5; i++)); do
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

    # Process blacks
    LTRS_BLACK=""  # Collect here Letters in Black
    LTRS_YG_ALL="$LTRS_YNOREP_ALL$LTRS_GNOREP_ALL"
    for (( i=0; i<5; i++)); do
        LETTER="${GUESS:$i:1}"
        CLUE="${CLUES:$i:1}"
        if [[ "$CLUE" == "$BLACK" ]]; then
            if [[ $LTRS_YG_ALL != *"$LETTER"* ]]; then
                # Clue is black and letter has never appeared as yellow or green
                # Append to list of letters that for sure are not in the solution,
                # if not there already
                if [[ $LTRS_BLACK != *"$LETTER"* ]]; then
                    LTRS_BLACK="$LTRS_BLACK$LETTER"
                fi
            else
                # Clue was black, but letter has been seen elsewhere as Y or G,
                # So remove words that match this letter in this position
                PATTERNS_TO_DISCARD="$PATTERNS_TO_DISCARD$SPACER${ANYTHING:0:i}$LETTER${ANYTHING:i+1}"
                SPACER=" "
            fi
        fi
    done

    # Proceed filtering down the list of words
    ATTEMPT=$(( ATTEMPT + 1 ))
    echo -e "\n\tAttempt: $ATTEMPT"
    echo -e "\tGuess  : $GUESS"
    echo -e "\tClues  : $CLUES"
    FOUND=`echo -e $WORDSET | grep "$GUESS"`
    if [[ "$FOUND" == "" ]]; then
        echo "Warning: word '$GUESS' was not found among remaining words."
        echo "(It might contain letter/position guesses already discarded.)"
    fi
    # Details about current guess and clues
    #echo -e "\tLetters in BLACK : $LTRS_BLACK"
    #echo -e "\tTo Match (GREEN) : $PATTERN_TO_MATCH"
    #echo -e "\tTo Discard       : $PATTERNS_TO_DISCARD"
    do_Word_Count
    # Filter the remaining set of words given the new guess+clues
    if [[ "$LTRS_BLACK" != "" ]]; then
        echo -e "\tDiscarding words with any of '$LTRS_BLACK' in any position."
        WORDSET=`echo -e "$WORDSET" | grep -v "[$LTRS_BLACK]"`
        do_Word_Count
    fi
    if [[ "$PATTERN_TO_MATCH" != "$ANYTHING" ]]; then
        echo -e "\tKeeping only words that match the pattern for greens: $PATTERN_TO_MATCH"
        WORDSET=`echo -e "$WORDSET" | grep "$PATTERN_TO_MATCH"`
        do_Word_Count
    fi
    if [[ "$PATTERNS_TO_DISCARD" != "" ]]; then
        #echo -e "\tDiscarding words matching these pattern(s): $PATTERNS_TO_DISCARD"
        for PATTERN in $PATTERNS_TO_DISCARD; do
            echo -e "\tDiscarding pattern '$PATTERN'"
            WORDSET=`echo -e "$WORDSET" | grep -v "$PATTERN"`
            do_Word_Count
        done
    fi
    LEN_YNR=${#LTRS_YNOREP}
    for (( i=0; i<$LEN_YNR; i++)); do
        LETTER="${LTRS_YNOREP:$i:1}"
        if [[ $LTRS_GNOREP_ALL != *"$LETTER"* ]]; then
            echo -e "\tKeeping only words with '$LETTER' somewhere"
            WORDSET=`echo -e "$WORDSET" | grep "$LETTER"`
            do_Word_Count
        fi
    done
    # If there are yellow letters repeated, or yellow letters which also
    # appear in green, then count how many times this letter appears, in order
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
                echo -e "\tRepetition detected for $LETTER, appearing $COUNT times."
                echo -e "\tKeeping only words with that repetition (PATTERN $REP_PATTERN)"
                WORDSET=`echo -e "$WORDSET" | grep "$REP_PATTERN"`
                do_Word_Count
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
