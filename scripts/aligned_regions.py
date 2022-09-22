import sys
import os

status_file = sys.argv[1]
working_dir = sys.argv[2]
output_dir = sys.argv[3]
text = os.path.join(working_dir, 'text_actual')
segments = os.path.join(output_dir, 'segments')
out_text = os.path.join(output_dir, 'text')
spk2utt = os.path.join(output_dir, 'spk2utt')
utt2spk = os.path.join(output_dir, 'utt2spk')

with open(text) as f:
	text = f.readline()
	text = text.split()

with open(status_file) as f:
	status = f.readlines()
	status = [ln.rstrip().split() for ln in status]

aligned_regions = [[st[0], st[1], st[3], st[4]] for st in status if st[2] == 'DONE'] 

with open(segments, 'w') as f:
	for i, reg in enumerate(aligned_regions):
		onset_time, offset_time, _, _ = reg 
		f.write('segment_{} key_1 {} {}\n'.format(i, onset_time, offset_time))

with open(out_text, 'w') as f:
	for i, reg in enumerate(aligned_regions):
		_, _, onset, offset = reg
		print(int(onset), int(offset))
		reg_text = ' '.join(text[int(onset):int(offset)+1]) 
		f.write('segment_{} {}\n'.format(i, reg_text))

with open(spk2utt, 'w') as f:
	for i in range(len(aligned_regions)):
		f.write('key_1 segment_{}\n'.format(i))

with open(utt2spk, 'w') as f:
	for i in range(len(aligned_regions)):
		f.write('segment_{} key_1\n'.format(i))

