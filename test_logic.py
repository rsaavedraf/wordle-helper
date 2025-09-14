#!/usr/bin/env python
# SPDX-License-Identifier: MIT

"""
test-logic.py
author: Raul Saavedra ( raul.saavedra@gmail.com )
date  : 2025.09.11

This program tests the clue-based filtering logic used in wordle-helper.

"""


import sys
from pathlib import Path

wlen = 5
batch_mode = False
batch_data = []

def process_options(argv):
    global batch_mode
    global batch_data
    for opt in argv:
        if opt == "-h":
            # Display help
            with open('test_logic_help_py.txt') as help:
                for line in help:
                    print(line.rstrip())
            sys.exit()
        if opt.startswith("-b"):
            # Batch mode
            fname = opt[2:]
            vpath = Path(fname)
            if vpath.is_file():
                print("Using contents of '"+fname+"' as input file in batch mode:")
                with open(fname) as contents:
                    for line in contents:
                        line = line.strip()
                        if len(line) > 0 and not line.startswith("#"):
                            try:
                                idx = line.index("#")
                                if (idx >= 0):
                                    line = line[0:idx].strip()
                            except ValueError:
                                pass
                            words = line.split()
                            batch_data.append(words)
                #print("Batch data to check:")
                #print(batch_data)
                batch_mode = True
            else:
                print("ERROR: File '"+fname+"' not found, exiting.")
                sys.exit(-1)
            continue
        print("ERROR: {0} is not an option, use -h for usage details".format(opt))
        sys.exit(-2)


def test_wordle_logic_batch():
    for data_line in batch_data:
        try:
            # get next word from input file
            guess = data_line[0]
            print(guess, end=" ")
            if len(guess) == 0:
                break

            if len(guess) != wlen:
                # ignore, skip the clues, and continue
                continue
            guess = guess.lower()

            clues = data_line[1]
            while len(clues) != 5:
                # get corresponding clues from the input file
                if len(clues) == 0:
                    exit()
            clues = clues.lower()
            print(clues, end="   ")
            expected = data_line[2:]
            #print("Expected result: ", expected)
        except:
            print("(There was an error processing", data_line, ")")
            continue

        goodset = set()     # Set of letters that are in the target word (clues g or y)
        toomany = set()     # Used to identify excessive repetitions of a guessed letter
        # Create dictionary for counters of letters in the guess
        lcounters = dict()	# counters for each letter in the guess
        for ltr in guess:
            lcounters[ltr] = 0

        j = 0
        ne = len(expected)
        # Pass 1: First process g clues (perfect matches)
        for i in range(wlen):
            if (clues[i] != 'g'):
                continue
            ltr = guess[i]
            si = str(i)
            result = "G" + ltr + si
            print(result, end="   ") # Keep only words that contain ltr in slot si
            if (j >= ne):
                print("\t(Error: More outputs than expected, processing g clues)")
                exit(-1)
            if (result != expected[j].strip()):
                print("\t(Error: Result from g clue differs from expected: "+expected[j]+")")
                exit(-2)
            j += 1
            goodset.add(ltr)
            lcounters[ltr] += 1

        # Pass 2: Process y clues
        for i in range(wlen):
            if (clues[i] != 'y'):
                continue
            # Here we have a y clue
            ltr = guess[i]
            si = str(i)
            lcounters[ltr] += 1
            if (ltr in goodset):
                slc = str(lcounters[ltr])
                result = "YR" + ltr + si + slc
                print(result, end=" ")      # Discard words with ltr in slot si, but Keep only words that contain
                                            # at least snl ltr's (Repetition detected from y clue)
            else:
                result = "Y" + ltr + si
                print(result, end="   ")    # Discard words with ltr in slot si but Keep words that have ltr somewhere else
            if (j >= ne):
                print("\t(Error: More outputs than expected, processing y clues)")
                exit(-3)
            if (result != expected[j].strip()):
                print("\t(Error: Result for y clue differs from expected: "+expected[j]+")")
                exit(-4)
            j += 1
            goodset.add(ltr)

        # Pass 3: Process - clues
        for i in range(wlen):
            if (clues[i] in "gy"):
                continue
            ltr = guess[i]
            result = ""
            lcounters[ltr] += 1
            if (ltr in goodset):
                # ltr is in the solution somewhere else though
                if ltr not in toomany:
                    slc = str(lcounters[ltr])
                    result = "-R" + ltr + slc
                    print(result, end="  ") # Discard excessive reps of ltr (slc is one too many)
                    toomany.add(ltr)
            else:
                # ltr is not at all in the solution
                if (lcounters[ltr] == 1):
                    result = "-" + ltr + "*"
                    print(result, end="   ") # Discard any words that contain ltr anywhere

            if (result != ""):
                if (j >= ne):
                    print("\tError: More outputs than expected, processing - clues")
                    exit(-5)
                if (result != expected[j].strip()):
                    print("\tError: Result for - clue differs from expected: "+expected[j])
                    exit(-6)
                j += 1

        if (j < ne):
            print("\tError: more outputs were expected:", expected)
            exit(-7)

        print("\t(Result == Expected)")
    print("\tAll tests passed!")

def test_wordle_logic_interactive():
    while (True):
        guess = input("Please enter your guess (or just Enter to exit):\n")
        if len(guess) == 0:
            break

        if len(guess) != wlen:
            print("Make sure it has "+str(wlen)+" letters, try again.")
            continue

        guess = guess.lower()
        clues = ""
        while len(clues) != 5:
            clues = input("Please enter the 5 clues (ie. -yg--) for that guess (or just Enter to exit):\n")
            if len(clues) == 0:
                exit()
        clues = clues.lower()

        goodset = set()	# Set of letters that are in the target word (clues g or y)
        toomany = set()     # Used to identify excessive repetitions of a guessed letter
        # Create dictionary for counters of letters in the guess
        lcounters = dict()	# counters for each letter in the guess
        for ltr in guess:
            lcounters[ltr] = 0

        # Pass 1: process g clues (perfect matches)
        for i in range(wlen):
            if (clues[i] != 'g'):
                continue
            ltr = guess[i]
            si = str(i)
            print("G" + ltr + si + "  :  Keep only words that contain '" + ltr + "' in slot " + si)
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
                snl = str(lcounters[ltr])
                print("YR" + ltr + si + snl + ":  Discard words with '" + ltr + "' in slot " + si + ", but Keep only words that contain at least " + snl + " '" + ltr + "'s (Reps detected from y clue!)")
            else:
                print("Y" + ltr + si +"  :  Discard words with '"+ltr+"' in slot "+si+", but Keep words that have '" + ltr + "' somewhere else.")
            goodset.add(ltr)

        # Pass 3: Process '-' clues (anything not g or y is assumed to mean -)
        for i in range(wlen):
            if clues[i] in "gy":
                continue
            ltr = guess[i]
            lcounters[ltr] += 1
            if (ltr in goodset):
                # this letter had a g or y clue somewhere else
                if ltr not in toomany:
                    # First time we see it with the - clue from this guess
                    slc = str(lcounters[ltr])
                    print("-R" + ltr + slc + " :  Discard excessive Reps of '" + ltr + "' (" + slc + "x is one too many)")
                    toomany.add(ltr)
            else:
                # ltr is not at all in the solution
                if (lcounters[ltr] == 1):
                    # First time we see this letter in the guess, so do filter it out
                    print("-" + ltr + "*  :  Discard any words that contain '" + ltr + "' anywhere")

        if (clues == "ggggg"):
            print("That's a match!")

if __name__ == '__main__':
    process_options(sys.argv[1:])
    if (batch_mode):
        test_wordle_logic_batch()
    else:
        test_wordle_logic_interactive()
