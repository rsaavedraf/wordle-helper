#!/usr/bin/env python
# SPDX-License-Identifier: MIT

"""
wordle-helper.py
author: Raul Saavedra ( raul.saavedra@gmail.com )
Created    : 2022.10.03
Last update: 2025.09.14 (new simplified logic and filtering)

This script progressively filters out all words that are
no longer valid for a Wordle challenge, given your guesses
and clues so far (green, yellow, or black) that you've
received for each guess.

(This was a just rewrite in python of the original
wordle-helper.sh bash script. After implementing the new logic in
python, now the bash script will need to be checked and updated
to match exactly how this python version runs.)

"""

import sys
import string
import re
from pathlib import Path

BAR             = '='*48
abc_str         = string.ascii_lowercase
abc             = set(abc_str)
valid_clues     = set("gy-")
wordlist_file   = ""
word_set        = set()
show_max_n      = 100
anything        = "."*5
batch_mode      = False
binputs         = []
binput_index    = 0
wc_msg          = "Size of starting word list:"
wlen            = 5
KEEP            = True
DISCARD         = False

def starting_banner():
    print(BAR)
    print('|      wordle-helper.py                        |')
    print('|      By Raul Saavedra F., 2025-Sep-14        |');
    print(BAR)

def process_options(argv):
    global wordlist_file
    global show_max_n
    global batch_mode
    global binputs
    global wlen
    global anything
    for opt in argv:
        if opt == "-h":
            # Display help
            with open('wordle-helper-help-py.txt') as help:
                for line in help:
                    print(line.rstrip())
            sys.exit()
        if opt == "-s":
            # Use Spanish word list
            print("Using the default wordlist for SPANISH")
            wordlist_file="words_len5_es.txt"
            continue
        if opt.startswith("-n"):
            # Set maximum number of words to show
            n=opt[2:]
            if n.isdecimal():
                show_max_n=int(n)
            else:
                print("Invalid max parameter: '{0}'".format(n))
            print("Using {0} as maximum number of words to display".format(show_max_n))
            continue
        if opt.startswith("-b"):
            fname = opt[2:]
            vpath = Path(fname)
            if vpath.is_file():
                print("Using contents of '"+fname+"' as input file in batch mode:")
                with open(fname) as contents:
                    for line in contents:
                        line = line.strip()
                        if len(line) > 0 and not line.startswith("#"):
                            words = line.split()
                            binputs.extend(words)
                print(" ".join(str(x) for x in binputs))
                batch_mode = True
            else:
                print("ERROR: File '"+fname+"' not found, exiting.")
                sys.exit(-1)
            continue
        if opt.startswith("-l"):
            n=opt[2:]
            if n.isdecimal() and int(n) >= 1:
                wlen=int(n)
                anything="."*wlen
            else:
                print("Invalid parameter for -l: '{0}'".format(n))
            print("Using {0} as word-length".format(wlen))
            continue
        if opt.startswith("-w"):
            fname = opt[2:]
            vpath = Path(fname)
            if vpath.is_file():
                wordlist_file = fname
                print("Using '"+wordlist_file+"' as word list")
            else:
                print("ERROR: Word list file '"+fname+"' not found, exiting")
                sys.exit(-2)
            continue
        print("ERROR: {0} is not an option, use -h for usage details".format(opt))
        sys.exit(-3)

def load_wordlist():
    global wordlist_file
    global word_set
    global abc
    global abc_str
    global batch_mode
    global wc_msg
    global wlen
    word_set.clear()
    print("Loading word list...")
    if wordlist_file == "":
        # Use the default english word list
        wordlist_file="words_len5_en.txt"
    """
    Read word list ignoring comments, keeping only wlen letter words,
    and making all words lowercase, creating a set from the result,
    also updating abc if letters other than those in english appear
    """
    with open(wordlist_file) as wordlist_lines:
        for line in wordlist_lines:
            li = line.strip()
            if not li.startswith("#"):
                words = li.split()
                for word in words:
                    if len(word) == wlen:
                        word = word.lower()
                        word_set.add( word )
                        # Make sure abc has all letters
                        for letter in [*word]:
                            if not letter in abc:
                                abc.add(letter)
                                abc_str = abc_str + letter
    nwords = len(word_set)
    print("Size of starting word list: "+str(nwords))
    print("ABC has a total of {0} letters: {1}".format(len(abc), abc_str))

def get_word(msg, valid_letters):
    global batch_mode
    global binputs
    global binput_index
    word = ""
    invalid = True
    while invalid:
        if batch_mode:
            if binput_index >= len(binputs):
                break
            else:
                word = binputs[binput_index]
                binput_index = binput_index + 1
        else:
            print(msg)
            word = input()
        if (word == ""):
            break
        word = word.strip()
        if (len(word) != wlen):
            print("ERROR: Input '"+word+"' is not {0} characters long.".format(wlen))
            if batch_mode:
                sys.exit(-4)
            continue
        word = word.lower()
        letters = [*word]
        invalid = False
        for letter in letters:
            if (letter not in valid_letters):
                print("ERROR: invalid character '"+letter+"' in '"+word+"'")
                if batch_mode:
                    sys.exit(-5)
                invalid = True
                break
    return word

def do_filter_down(matching, pattern, msg):
    global word_set
    global msg_wr
    print(msg)
    if matching:
        word_set = set(w for w in word_set if re.match(pattern, w))
    else:
        word_set = set(w for w in word_set if not re.match(pattern, w))
    nwords = len(word_set)
    print("\tWords remaining: "+str(nwords))

def process_attempt(n, guess, clues):
    global BAR
    global word_set
    global ltrs_ynorep_all
    global ltrs_gnorep_all
    global show_max_n
    global batch_mode

    msg_wr="\tWords remaining"
    patterns_to_discard = []
    patterns_to_keep = []
    pattern_to_match = anything
    lw = [*guess] # list of letters in guessed word
    lc = [*clues] # list of letters in clues

    goodset = set()     # Set of letters that are in the target word (clues g or y)
    toomany = set()     # Used to identify excessive repetitions of a guessed letter
    # Create dictionary for counters of letters in the guess
    lcounters = dict()  # counters for each letter in the guess
    for ltr in guess:
        lcounters[ltr] = 0

    # New processing/filtering logic as implemented in test_logic.py,
    # with 3 passes:

    # Pass 1: process g clues (perfect matches)
    for i in range(wlen):
        if (lc[i] != 'g'):
            continue
        ltr = lw[i]
        si = str(i)
        print("G" + ltr + si + "  :  Keep only words that contain '" + ltr + "' in slot " + si)
        pattern_to_match = pattern_to_match[0:i] + ltr + pattern_to_match[i+1:]
        goodset.add(ltr)
        lcounters[ltr] += 1

    # Pass 2: Process y clues
    for i in range(wlen):
        if (clues[i] != 'y'):
            continue
        ltr = guess[i]
        si = str(i)
        lcounters[ltr] += 1
        if (ltr in goodset):
            lc = lcounters[ltr]
            slc = str(lc)
            print("YR" + ltr + si + slc + ":  Discard words with '" + ltr + "' in slot " + si + ", and Keep only words that contain at least " + slc + " '" + ltr + "'s (Reps detected from y clue!)")
        else:
            lc = 1
            print("Y" + ltr + si +"  :  Discard words with '"+ltr+"' in slot "+si+", and Keep only words that have '" + ltr + "' somewhere else.")
        patterns_to_discard.append( anything[0:i] + ltr + anything[i+1:] )
        patterns_to_keep.append( ((".*" + ltr)*lc) + ".*" )
        goodset.add(ltr)

    # Pass 3: Process '-' clues
    for i in range(wlen):
        if (clues[i] != "-"):
            continue
        ltr = guess[i]
        lcounters[ltr] += 1
        if (ltr in goodset):
            # this letter had a g or y clue somewhere else
            if ltr not in toomany:
                # First time we see it with the - clue from this guess
                si = str(i)
                lc = lcounters[ltr]
                slc = str(lc)
                print("-R" + ltr + slc + " :  Discard words with '" + ltr +"' in slot " + si +", and also excessive Reps of '" + ltr + "' (" + slc + "x is one too many)")
                patterns_to_discard.append( anything[0:i] + ltr + anything[i+1:] )
                patterns_to_discard.append( ((".*" + ltr)*lc) + ".*" )
                toomany.add(ltr)
        else:
            # ltr is not at all in the solution
            if (lcounters[ltr] == 1):
                # First time we see this letter in the guess, so do filter it out
                print("-" + ltr + "*  :  Discard any words that contain '" + ltr + "' anywhere.")
                patterns_to_discard.append( ".*" + ltr + ".*")

    # Details of current guess and corresponding clues
    print("\n\tAttempt: "+str(n))
    print(  "\tGuess  : "+guess)
    print(  "\tClues  : "+clues)
    if (guess not in word_set):
        print("Warning: word '"+guess+"' was not found among remaining words.")
        print("(It might contain letter/position guesses already discarded.)")
    nwords = len(word_set)
    print("\tWords remaining: "+str(nwords))

    # Filter further down list of remaining words given the new guess and clues
    if pattern_to_match != anything:
        do_filter_down(KEEP, pattern_to_match, "\tKeeping only words matching: "+pattern_to_match)

    for pattern in patterns_to_discard:
        do_filter_down(DISCARD, pattern,       "\tDiscarding words matching:   '"+pattern+"'")

    for pattern in patterns_to_keep:
        do_filter_down(KEEP   , pattern,       "\tKeeping words matching:      '"+pattern+"'")

    nwords = len(word_set)
    if nwords <= show_max_n:
        print("Actual words remaining: "+" ".join(sorted(word_set)))
    if nwords == 1:
        print(BAR+"\nCongratulations, a single word was reached!!! :)")
        print("See you next time.\n"+BAR)
        sys.exit(0)
    if nwords == 0:
        print("We ran out of words, no further filtering is possible.")
        print("The starting word list might need additional entries.")
        print("Double-check your provided input just in case of typos.")
        print("Bye for now.")
        sys.exit(0)


def do_helper_loop():
    global abc
    global valid_clues
    msg_eoi="No more inputs, see you next time."
    msg_enter_guess="\n===== Please enter your {0}-letter wordle guess, or Enter to leave:".format(wlen)
    msg_enter_clues="===== Please enter the resulting clues (e.g. -yg--), or Enter to leave:"
    attempt = 0
    while True:
        word = get_word(msg_enter_guess, abc)
        if (word == ""):
            print(msg_eoi)
            break
        clues = get_word(msg_enter_clues, valid_clues)
        if (clues == ""):
            print(msg_eoi)
            break
        attempt = attempt + 1
        process_attempt(attempt, word, clues)
    sys.exit(0)

def do_wordle_helper(argv):
    starting_banner()
    process_options(argv)
    load_wordlist()
    do_helper_loop()


if __name__ == '__main__':
    do_wordle_helper(sys.argv[1:])
