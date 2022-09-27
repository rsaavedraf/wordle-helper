#!/bin/bash
# wordle_helper.sh
# By Raul Saavedra F., Bonn-Germany, 2022-09-23
#
# This program progressively filters out all words
# that are no longer valid for a Wordle challenge,
# given your guesses so far, and the clues (green,
# yellow, or black) for each letter you've received
# in each guess.
#
# This script is not really intended to be optimal,
# just exercises the usage of some grep filtering,
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
SHOWMAXN=100
INPUTS=""
WLFILE=""
WORDSET=""
BATCHMODE=false
ABC="abcdefghijklmnñopqrstuvwxyz"

# Process parameters/options, if any
for OPTION in "$@"; do
    case $OPTION in
        -h)  cat wordle-helper-help.txt
             exit 0
             ;;
        -s)  echo "Using the default wordlist for SPANISH."
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
                echo "Invalid max parameter: $N is not >= zero."
             else
                SHOWMAXN=$N
             fi
             echo "Using $SHOWMAXN as maximum number of words to display."
             ;;
        -w*) WLF="${OPTION:2}"
             # Todo: verify that file exists
             if [[ -f $WLF ]]; then
                 WLFILE=$WLF
                 echo "Using '$WLFILE' as word list."
             else
                 echo "ERROR: Word list file '$WLF' not found, exiting."
                 exit -2
             fi
             ;;
        *)   echo "ERROR: $OPTION is not an option, use -h for usage details."
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
WORDSET=`cat $WLFILE | grep -v "#" | grep "^.....$" | tr '[:upper:]' '[:lower:]'`

# Main loop to iteratively get the guess and clues,
# then filter the remaining valid words accordingly
WORD=""
GUESS=""
CLUES=""
LOOP=0
ATTEMPT=0
GET_GUESS=1
while true; do

    # Get input WORD
    if $BATCHMODE; then
        # get next word from the inputs array
        WORD=${INPUTS[$LOOP]}
        LOOP=$(( LOOP + 1 ))
    else
        # Ask user for next input
        if ((GET_GUESS)); then
            echo -e "\n===== Please enter your 5-letter wordle guess, or Enter to leave:"
        else
            # Ask for the corresponding clues
            echo "===== Please enter the resulting clues (e.g. -YG--), or Enter to leave:"
        fi
        read WORD
    fi
    # Trim whitespace from WORD, and make it lowercase
    WORD=`echo "$WORD" | xargs | tr '[:upper:]' '[:lower:]'`

    # If WORD is empty, exit normally
    if [[ "$WORD" == "" ]]; then
        echo "No more inputs, see you next time."
        exit 0
    fi

    # Validate that the word has 5 characters
    if (( ${#WORD} != 5 )); then
        echo "ERROR: Input '$WORD' is not five characters long."
        if $BATCHMODE; then
            exit -4
        fi
        continue
    fi
    INVALID=false
    if ((GET_GUESS)); then
        # Validate letters in guess word
        for (( i=0; i<5; i++ )); do
            LETTER="${WORD:$i:1}"
            if [[ $ABC != *"$LETTER"* ]]; then
                # Not a valid letter
                INVALID=true
                break
            fi
        done
        if $INVALID; then
            echo "ERROR: invalid letter '$LETTER' in '$WORD'."
            if $BATCHMODE; then
                exit -5
            fi
            continue
        fi
        # WORD has the current GUESS, and it's valid
        GUESS=$WORD
        # Ask for the associated clues before continuing further down
        GET_GUESS=0
        continue;
    fi

    # If we are here, WORD has the CLUES for the last GUESS
    CLUES=$WORD

    # Validate the CLUES, while building associated filtering patterns
    LTRS_BLACK=""  # Letters in Black i.e. not in the Wordle solution
    LTRS_GREEN=""  # Collect here letters in Green
    LTRS_YELLOW="" # Collect here letters in Yellow
    LTRS_YNOREP="" # Letters in Yellow, but with no repetitions
    PATTERN_TO_MATCH=$ANYTHING     # Pattern to match (from Green letters)
    PATTERNS_TO_DISCARD=""         # Patterns to discard (from Yellow letters)
    SPACER=""
    for (( i=0; i<5; i++)); do
        LETTER="${GUESS:$i:1}"
        CLUE="${CLUES:$i:1}"
        if [[ "$CLUE" == "$GREEN" ]]; then
            # Add this letter in this position to the pattern to match
            PATTERN_TO_MATCH="${PATTERN_TO_MATCH:0:i}$LETTER${PATTERN_TO_MATCH:i+1}"
            # Update our set of green letters
            LTRS_GREEN="$LTRS_GREEN$LETTER"
        elif [[ "$CLUE" == "$YELLOW" ]]; then
            # Add this letter in this position to the patterns to discard using yellows
            PATTERNS_TO_DISCARD="$PATTERNS_TO_DISCARD$SPACER${ANYTHING:0:i}$LETTER${ANYTHING:i+1}"
            SPACER=" "
            # Update our set of yellow letters allowing repetitions
            LTRS_YELLOW="$LTRS_YELLOW$LETTER"
            # Update our set of yellow letters with no repetitions
            if [[ $LTRS_YNOREP != *"$LETTER"* ]]; then
                LTRS_YNOREP="$LTRS_YNOREP$LETTER"
            fi
        elif [[ "$CLUE" == "$BLACK" ]]; then
            # Update our set of black letters with no repetitions
            if [[ $LTRS_BLACK != *"$LETTER"* ]]; then
                LTRS_BLACK="$LTRS_BLACK$LETTER"
            fi
        else
            # Invalid character in clues
            echo "ERROR: character '$CLUE' is an invalid clue."
            INVALID=true
            break
        fi
    done
    if $INVALID; then
        if $BATCHMODE; then
            exit -6
        fi
        continue
    fi

    # At this point the Guess and Clues are finally valid
    # Proceed with filtering down the list of words
    ATTEMPT=$(( ATTEMPT + 1 ))
    echo -e "\n\tAttempt: $ATTEMPT"
    FOUND=`echo -e $WORDSET | grep "$GUESS"`
    if [[ "$FOUND" == "" ]]; then
        echo "Warning: word '$GUESS' was not found among remaining words."
        echo "(It might contain letter/position guesses already discarded.)"
    fi
    # Remove from LTRS_BLACK any letter that appears also in yellow or green
    NEWLTRS_BLACK=""
    LTRS_YG="$LTRS_YELLOW$LTRS_GREEN"
    LEN_B=${#LTRS_BLACK}
    for (( i=0; i<$LEN_B; i++)); do
        LETTER="${LTRS_BLACK:$i:1}"
        if [[ $LTRS_YG != *"$LETTER"* ]]; then
            # Not in yellows or greens, so keep as black
            NEWLTRS_BLACK="$NEWLTRS_BLACK$LETTER"
        fi
    done
    LTRS_BLACK=$NEWLTRS_BLACK
    # Details about current guess and clues
    echo -e "\tLetters in BLACK   : $LTRS_BLACK"
    echo -e "\tTo Match (GREEN)   : $PATTERN_TO_MATCH"
    echo -e "\tTo Discard (YELLOW): $PATTERNS_TO_DISCARD"
    NWORDS=`echo $WORDSET | wc -w`
    echo -e "\tWords remaining: $NWORDS"
    # Filter the remaining set of words given the new guess+clues
    if [[ "$LTRS_BLACK" != "" ]]; then
        echo -e "\tDiscarding words with any of '$LTRS_BLACK' in any position."
        WORDSET=`echo -e "$WORDSET" | grep -v "[$LTRS_BLACK]"`
        NWORDS=`echo $WORDSET | wc -w`
        echo -e "\tWords remaining: $NWORDS"
    fi
    if [[ "$PATTERN_TO_MATCH" != "$ANYTHING" ]]; then
        echo -e "\tKeeping only words that match the pattern for greens: $PATTERN_TO_MATCH"
        WORDSET=`echo -e "$WORDSET" | grep "$PATTERN_TO_MATCH"`
        NWORDS=`echo $WORDSET | wc -w`
        echo -e "\tWords remaining: $NWORDS"
    fi
    if [[ "$PATTERNS_TO_DISCARD" != "" ]]; then
        echo -e "\tDiscarding words matching the pattern(s) for yellows: $PATTERNS_TO_DISCARD"
        for PATTERN in $PATTERNS_TO_DISCARD; do
            echo -e "\tDiscarding pattern '$PATTERN'"
            WORDSET=`echo -e "$WORDSET" | grep -v "$PATTERN"`
            NWORDS=`echo $WORDSET | wc -w`
            echo -e "\tWords remaining: $NWORDS"
        done
    fi
    LEN_YNR=${#LTRS_YNOREP}
    for (( i=0; i<$LEN_YNR; i++)); do
        LETTER="${LTRS_YNOREP:$i:1}"
        echo -e "\tKeeping only words with '$LETTER' somewhere"
        WORDSET=`echo -e "$WORDSET" | grep "$LETTER"`
        NWORDS=`echo $WORDSET | wc -w`
        echo -e "\tWords remaining: $NWORDS"
    done
    # If there are yellow letters repeated, or yellow letters which also
    # appear in green, then count how many times this letter appears, in order
    # to keep only words with at least that many occurences of this letter
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
                NWORDS=`echo $WORDSET | wc -w`
                echo -e "\tWords remaining: $NWORDS"
            fi
        fi
    done
    if (( NWORDS <= SHOWMAXN )); then
        # Show the remaining set of possible solutions
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
    GET_GUESS=1 # Repeat asking about the next guess
done
