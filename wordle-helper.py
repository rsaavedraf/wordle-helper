#!/usr/bin/env python
# SPDX-License-Identifier: MIT

"""
wordle-helper.py
author: Raul Saavedra ( raul.saavedra@gmail.com )
date  : 2022.10.03

This script progressively filters out all words that are
no longer valid for a Wordle challenge, given your guesses
and clues so far (green, yellow, or black) that you've
received for each guess.

(This is a just rewrite in python of the original
wordle-helper.sh bash script.)

"""

import sys
import string
import re
from pathlib import Path

BAR             = '='*48
abc_str         = string.ascii_lowercase
abc             = set(abc_str)
black           = "-"
green           = "g"
yellow          = "y"
valid_clues     = set(black+green+yellow)
wordlist_file   = ""
word_set        = set()
show_max_n      = 100
ltrs_ynorep_all = set() # Letters in Yellow from all clues, with no repetitions
ltrs_gnorep_all = set() # Letters in Green from all clues, with no repetitions
anything        = "."*5
batch_mode      = False
binputs         = []
binput_index    = 0
wc_msg          = "Size of starting word list:"
wlen            = 5

def starting_banner():
    print(BAR)
    print('|      wordle-helper.py                        |')
    print('|      By Raul Saavedra F., 2022-Oct-03        |');
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

def process_attempt(n, word, clues):
    global BAR
    global word_set
    global ltrs_ynorep_all
    global ltrs_gnorep_all
    global show_max_n
    global batch_mode

    # Process Yellows and Greens first
    msg_wr="\tWords remaining"
    ltrs_yellow=""
    ltrs_green=""
    ltrs_ynorep=[]
    patterns_to_discard=[]
    pattern_to_match=anything
    lw = [*word]  # list of letters in word
    lc = [*clues] # list of letters in clues
    for i in range(wlen):
        ltr  = lw[i]
        clue = lc[i]
        if (clue == 'y'):       # Process yellow clue
            ltrs_yellow = ltrs_yellow + ltr
            ltrs_ynorep.append(ltr)
            ltrs_ynorep_all.add(ltr)
            patterns_to_discard.append( anything[0:i] + ltr + anything[i+1:])
        elif (clue == 'g'):     # Process green clue
            ltrs_green = ltrs_green + ltr
            ltrs_gnorep_all.add(ltr)
            pattern_to_match = pattern_to_match[0:i] + ltr + pattern_to_match[i+1:]

    # Details of current guess and corresponding clues
    print("\n\tAttempt: "+str(n))
    print(  "\tGuess  : "+word)
    print(  "\tClues  : "+clues)
    if (word not in word_set):
        print("Warning: word '"+word+"' was not found among remaining words.")
        print("(It might contain letter/position guesses already discarded.)")
    nwords = len(word_set)
    print("\tWords remaining: "+str(nwords))

    # Process Blacks
    str_ltrs_b  = ""
    ltrs_black  = set()
    repeated    = set()
    ltrs_yg_all = list(ltrs_ynorep_all) + list(ltrs_gnorep_all)
    #print("Letters YG_ALL are:", ltrs_yg_all)
    for i in range(wlen):
        ltr  = lw[i]
        clue = lc[i]
        if (clue == "-"):       # Process black clue
            if ltr in ltrs_yg_all:
                # Clue was black, but letter has been seen elsewhere as Y or G.
                # Before we just discarded words that matched this letter in this position, e.g.
                #       patterns_to_discard.append( anything[0:i] + ltr + anything[i+1:])
                # but we can do a bit more: all words with that letter repeated more than
                # the nr. of times this letter has been found to be green or yellow
                # can also be now discarded. Example: guess='litio', clues='---gg'
                # Then any words with two or more i's can and should already be
                # discarded, regardless of the positions of those i's
                patterns_to_discard.append( anything[0:i] + ltr + anything[i+1:])
                if ltr not in repeated:
                    repeated.add (ltr)
                    # rep_pattern will have one too many occurrences of the letter.
                    rep_pattern = ".*" + ltr
                    # Count how many times this letter appears in green or yellow
                    count = 0;
                    for l in ltrs_yg_all:
                        if l == ltr:
                            count = count + 1
                            rep_pattern = rep_pattern + ".*" + ltr
                    rep_pattern = rep_pattern + ".*" # Finish the needed pattern
                    print("\tDetected that letter '"+ltr+"' appears only "+str(count)+" time(s).")
                    do_filter_down(False, rep_pattern, "\tDiscarding words with too many occurrences of '"+ltr+"' (pattern "+rep_pattern+")")
            else:
                # Clue is black and letter has never appeared as yellow or green.
                if ltr not in ltrs_black:
                    # Append to list of letters that for sure are not in the solution
                    str_ltrs_b = str_ltrs_b + ltr
                    ltrs_black.add(ltr)

    # Filter further down list of remaining words given the new guess and clues
    if len(ltrs_black) > 0:
        bltrs= "[" + str_ltrs_b + "]"
        pattern = ".*" + bltrs + ".*"
        do_filter_down(False, pattern, "\tDiscarding words with any of "+bltrs+" in any position")

    if pattern_to_match != anything:
        do_filter_down (True, pattern_to_match, "\tKeeping only words that match the pattern for greens: "+pattern_to_match)

    for pattern in patterns_to_discard:
        do_filter_down(False, pattern, "\tDiscarding pattern '"+pattern+"'")

    for ltr in ltrs_ynorep:
        if ltr not in ltrs_gnorep_all:
            do_filter_down(True, ".*"+ltr+".*", "\tKeeping only words with '"+ltr+"' somewhere")

    # If there is a yellow letter repeated, or a yellow letter which also
    # appears in green, then count how many times this letter appears, in order
    # to keep only words with at least that many occurences of this letter
    ltrs_yg  = ltrs_yellow + ltrs_green
    len_yg   = len(ltrs_yg)
    repeated = set()
    for i in range(len_yg):
        ltr = ltrs_yg[i]
        if ltr not in repeated:
            count = 1
            rep_pattern = ".*" + ltr
            for j in range(i+1, len_yg):
                ltr2 = ltrs_yg[j]
                if ltr == ltr2:
                    count = count + 1
                    rep_pattern = rep_pattern + ".*" + ltr
            if count > 1:
                repeated.add(ltr)                # Track the letter as repeated
                rep_pattern = rep_pattern + ".*" # Finish the needed pattern
                print("\tRepetition detected for '"+ltr+"', appearing "+str(count)+" times.")
                do_filter_down(True, rep_pattern, "\tKeeping only words with that repetition (pattern "+rep_pattern+")")

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
    msg_enter_clues="===== Please enter the resulting clues (e.g. -YG--), or Enter to leave:"
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
