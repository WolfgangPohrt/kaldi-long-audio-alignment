import sys
import os


word_timings = sys.argv[1]


with open(word_timings) as f:
    lines = f.readlines()
    lines = [ln.rstrip().split() for ln in lines]

for i, ln in enumerate(lines[1:]):
    word, onset, offset = ln
    if onset == '-1':
        continue
    elif float(onset) < float(lines[i-1][2]):
        print('Overlap {} {} {}'.format(onset, offset, word))
