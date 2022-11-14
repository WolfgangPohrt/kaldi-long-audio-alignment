import sys

word_ali_path = sys.argv[1]
audio_duration = sys.argv[2]

with open(word_ali_path) as f:
    word_ali = f.readlines()
    word_ali = [ln.rstrip().split() for ln in word_ali]



if word_ali[0][1] == '-1':
    stat = 'PENDING'
    onset_time_stat = offset_time_stat = 0
else:
    stat = 'DONE'
    onset_time_stat = offset_time_stat = word_ali[0][1]
onset_stat = 0
ali_stat = []
for i, w_ali, in enumerate(word_ali[1:]):

    _, onset_time, offset_time = w_ali

    
    if onset_time != '-1' and stat == 'PENDING':
        ali_stat.append([onset_time_stat, onset_time, 'PENDING', onset_stat, i])
        onset_stat = i + 1
        stat = 'DONE'
        onset_time_stat = onset_time

    elif onset_time == '-1' and stat == 'DONE':
        ali_stat.append([onset_time_stat, word_ali[i][2], 'DONE', onset_stat, i])
        onset_stat = i + 1
        stat = 'PENDING'
        onset_time_stat = word_ali[i][2]
ali_stat.append([onset_time_stat, audio_duration, stat, onset_stat, i+1])
for stat in ali_stat:
    print('{} {} {} {} {}'.format(*stat))
