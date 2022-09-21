import sys

status_path = sys.argv[1]

with open(status_path) as f:
	status = f.readlines()
	status = [ln.rstrip().split() for ln in  status]


status_cleaned = []
onset_time_curr = status[0][0]
onset_curr = status[0][3]
offset_time_curr = status[0][1]
offset_curr = status[0][4]
stat_cur = status[0][2]

for i, ln in enumerate(status[:-1]):
	
	onset_time, offset_time, stat, onset, offset = ln
	onset_time_next, offset_time_next, stat_next, onset_next, offset_next = status[i+1]
	if stat_next != stat_cur:
		status_cleaned.append([onset_time_curr, offset_time_curr, stat_cur, onset_curr, offset_curr])

		onset_time_curr = onset_time_next
		onset_curr = onset_next
		offset_time_curr = offset_time_next
		offset_curr = offset_next
		stat_cur = stat_next
 
	
	else:
		offset_time_curr = offset_time_next
		offset_curr = offset_next


for stat in status_cleaned:
	print(' '.join(stat))
	
	
