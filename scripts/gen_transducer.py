
# Copyright 2017  Speech Lab, EE Dept., IITM (Author: Srinivas Venkattaramanujam)

import sys
import codecs
import math
input_file_path=sys.argv[1]
skip=False
if(len(sys.argv)==3 and sys.argv[2]=='--include-skip'):
	skip=True
with codecs.open(input_file_path,'r','utf-8') as f:
	input_contents=f.readlines()


# print(input_contents[0])
words=input_contents[0].split(' ')
# print(words)
idx=1
for w in words:
	w=w.strip()
	w=w.encode('utf-8')
	if(skip != True):
		print('{} {} {} {} {}'.format(idx-1, idx, w, w, '0'))
	else:
		print('{} {} {} {} {}'.format(idx-1, idx, w, w, math.log(0.9,10)))
		print('{} {} {} {} {}'.format(idx-1, idx, '<eps>', '<eps>', math.log(0.1,10)))
	print('{} {} {} {} {}'.format('0', idx, '<eps>', '<eps>', '0'))
	print(idx)
	idx+=1

