#!/usr/bin/env python
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

BAR='='*48
wordlist_file=""
word_set=set()
abc=set([*string.ascii_lowercase])
show_max_n=100

def starting_banner():
    print(BAR)
    print('|      wordle-helper.py                        |')
    print('|      By Raul Saavedra F., 2022-Oct-03        |');
    print(BAR)

def process_options(argv):
    global wordlist_file
    global show_max_n
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
            print("Using {0} as maximum number of words to display.".format(show_max_n))
            continue
        if opt.startswith("-b"):
            # to do
            print("Processing -b")
            continue
        if opt.startswith("-w"):
            # to do
            print("Processing -w")
            continue
        print("ERROR: {0} is not an option, use -h for usage details".format(opt))
        sys.exit(-3)

def load_wordlist():
    global wordlist_file
    global word_set
    global abc
    word_set.clear()
    print("Loading word list...")
    if wordlist_file == "":
        # Use the default english word list
        wordlist_file="words_len5_en.txt"
    """
    Read word list ignoring comments, keeping only 5 letter words,
    and making all words lowercase, creating a set from the result,
    also updating abc if letters other than those in english appear
    """
    with open(wordlist_file) as wordlist_lines:
        for line in wordlist_lines:
            li = line.strip()
            if not li.startswith("#"):
                if len(li) == 5:
                    word = li.lower()
                    word_set.add( word )
                    # Make sure abc has all letters
                    for letter in [*word]:
                        abc.add(letter)
    print("Size of the word set: {0}".format(len(word_set)))
    print("ABC has a total of {0} letters: {1}".format(len(abc), ''.join(sorted(abc))))

def do_helper_loop():
    print("\nHere comes the helper loop")
    # to do
    sys.exit(0)

def do_wordle_helper(argv):
    starting_banner()
    process_options(argv)
    load_wordlist()
    do_helper_loop()


if __name__ == '__main__':
    do_wordle_helper(sys.argv[1:])
